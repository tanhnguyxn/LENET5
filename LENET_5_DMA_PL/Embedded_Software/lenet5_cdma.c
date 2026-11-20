// KR260 Linux, full AXI CDMA simple mode, 32-bit addresses, 64-bit data.
// Input: one whitespace-separated hex file in the block order below.
// Each token is one 16-bit Q8.8 bit pattern, optionally prefixed with 0x.
#define _POSIX_C_SOURCE 200809L
#define _FILE_OFFSET_BITS 64
#include <errno.h>
#include <fcntl.h>
#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/file.h>
#include <sys/mman.h>
#include <time.h>
#include <unistd.h>

#define LENET_BASE UINT32_C(0xA0000000)
#define CDMA_BASE  UINT32_C(0xA0800000)
#define LENET_SIZE 0x800000
#define BUF_SYS "/sys/class/u-dma-buf/udmabuf0/"
#define BUF_DEV "/dev/udmabuf0"
#define CHUNK 512u  // 4096 bytes per transfer

enum { CR=0x00, SR=0x04, SA=0x18, DA=0x20, BTT=0x28 };
enum { RESET=4, IDLE=2, DMA_ERRORS=0x770, IRQ_FLAGS=0x7000 };
struct block { const char *name; uint32_t word, count; };
static const struct block blocks[] = {
    {"conv1 weight",0x20000,150}, {"conv2 weight",0x30000,2400},
    {"fc1 weight",0x40000,30720}, {"fc2 weight",0x50000,10080},
    {"fc3 weight",0x60000,840}, {"conv1 bias",0x70000,6},
    {"conv2 bias",0x72000,16}, {"fc1 bias",0x74000,120},
    {"fc2 bias",0x76000,84}, {"fc3 bias",0x78000,10},
    {"image",0x10000,784}
};
static void die(const char *msg) { fprintf(stderr,"%s\n",msg); exit(1); }
static void os_error(const char *msg) { perror(msg); exit(1); }

static double seconds(void) {
    struct timespec t;
    if (clock_gettime(CLOCK_MONOTONIC,&t)) os_error("clock_gettime");
    return t.tv_sec + t.tv_nsec * 1e-9;
}
static uint64_t number(const char *path) {
    FILE *f=fopen(path,"r");
    char s[64], *end;
    if (!f) os_error(path);
    if (fscanf(f,"%63s",s)!=1) die(path);
    fclose(f);
    errno=0;
    unsigned long long n=strtoull(s,&end,0);
    if (errno || *end || s[0]=='-') die(path);
    return n;
}
static void attr(const char *path, const char *value) {
    int fd=open(path,O_WRONLY);
    if (fd<0) os_error(path);
    if (write(fd,value,strlen(value))!=(ssize_t)strlen(value)) os_error(path);
    close(fd);
}
static void *map_fd(int fd, size_t bytes, off_t addr) {
    void *p=mmap(NULL,bytes,PROT_READ|PROT_WRITE,MAP_SHARED,fd,addr);
    if (p==MAP_FAILED) os_error("mmap");
    return p;
}
static uint16_t read_hex(FILE *f) {
    char token[32], *end;
    if (fscanf(f,"%31s",token)!=1) die("Missing hex value");
    errno=0;
    unsigned long v=strtoul(token,&end,16);
    if (errno || *end || token[0]=='-' || strlen(token)>6 || v>0xffff)
        die("Expected a 16-bit hex value");
    return (uint16_t)v;
}
static void end_file(FILE *f) {
    char extra;
    if (fscanf(f," %c",&extra)!=EOF || ferror(f)) die("Extra data or file read error");
    fclose(f);
}
static void cdma_reset(volatile uint32_t *reg) {
    reg[CR/4]=RESET;
    __sync_synchronize();
    double deadline=seconds()+1;
    while (reg[CR/4]&RESET)
        if (seconds()>deadline) die("CDMA reset timed out; reset PL before retry");
}
// Caller owns the controller and has handed the source buffer to the device.
static void cdma_transfer(volatile uint32_t *reg, uint32_t src,
                          uint32_t dst, uint32_t bytes) {
    if (!(reg[SR/4]&IDLE)) die("CDMA busy before submission");
    reg[SR/4]=IRQ_FLAGS;
    reg[SA/4]=src;
    reg[DA/4]=dst;
    __sync_synchronize();
    reg[BTT/4]=bytes;  // Writing BTT starts the transfer.
    __sync_synchronize();
    double deadline=seconds()+2;
    for (;;) {
        uint32_t status=reg[SR/4];
        if (status&DMA_ERRORS || seconds()>deadline) {
            fprintf(stderr,"CDMA failed: SR=%08" PRIx32 " SRC=%08" PRIx32
                    " DST=%08" PRIx32 " bytes=%u\n",status,src,dst,bytes);
            cdma_reset(reg);
            die("Transfer aborted; reload the complete input before inference");
        }
        if (status&IDLE) return;
    }
}
int main(int argc,char **argv) {
    if (argc!=2 && argc!=3) {
        fprintf(stderr,"Usage: %s inputs.hex [golden_logits.hex]\n",argv[0]);
        return 2;
    }
    FILE *input=fopen(argv[1],"r");
    if (!input) os_error(argv[1]);
    uint16_t values[45210], golden[10];
    for (size_t i=0;i<45210;i++) values[i]=read_hex(input);
    end_file(input);
    if (argc==3) {
        FILE *f=fopen(argv[2],"r");
        if (!f) os_error(argv[2]);
        for (int i=0;i<10;i++) golden[i]=read_hex(f);
        end_file(f);
    }

    int buf_fd=open(BUF_DEV,O_RDWR|O_SYNC);
    if (buf_fd<0) os_error(BUF_DEV);
    if (flock(buf_fd,LOCK_EX|LOCK_NB)) os_error("exclusive DMA buffer lock");
    uint64_t src=number(BUF_SYS "phys_addr");
    size_t capacity=CHUNK*sizeof(uint64_t);
    if (number(BUF_SYS "size")<capacity || src>UINT32_MAX-(capacity-1) || src%8)
        die("Need an aligned 4 KiB buffer in CDMA-addressable low DDR");
    uint64_t *buf=map_fd(buf_fd,capacity,0);
    int mem=open("/dev/mem",O_RDWR|O_SYNC);
    if (mem<0) os_error("/dev/mem");
    volatile uint32_t *dma=map_fd(mem,4096,CDMA_BASE);
    volatile uint64_t *ip=map_fd(mem,LENET_SIZE,LENET_BASE);
    if (ip[0]&1) die("LeNet busy");
    if (!(dma[SR/4]&IDLE)) die("CDMA not idle; check owner, clocks and reset");
    cdma_reset(dma);
    attr(BUF_SYS "sync_offset","0");
    attr(BUF_SYS "sync_size","4096");
    attr(BUF_SYS "sync_direction","1"); // DMA_TO_DEVICE
    size_t index=0;
    for (size_t b=0;b<sizeof blocks/sizeof blocks[0];b++) {
        const struct block *p=&blocks[b];
        for (uint32_t i=0;i<p->count;) {
            uint32_t n=p->count-i;
            if (n>CHUNK) n=CHUNK;
            attr(BUF_SYS "sync_for_cpu","1");
            for (uint32_t j=0;j<n;j++) buf[j]=values[index++];
            __sync_synchronize();
            attr(BUF_SYS "sync_for_device","1");
            cdma_transfer(dma,(uint32_t)src,LENET_BASE+8u*(p->word+i),8u*n);
            i+=n;
        }
        printf("Loaded %s (%u words)\n",p->name,p->count);
    }
    attr(BUF_SYS "sync_for_cpu","1");
    ip[0]=1;
    __sync_synchronize();
    double deadline=seconds()+2;
    while ((ip[0]&3)!=2)
        if (seconds()>deadline) die("Timeout waiting for LeNet DONE");
    int mismatch=0;
    uint16_t logits[10];
    for (int i=0;i<10;i++) {
        logits[i]=(uint16_t)ip[0x90000+i];
        printf("logit[%d] = %04x",i,(unsigned)logits[i]);
        if (argc==3) {
            printf(" expected %04x",(unsigned)golden[i]);
            mismatch+=logits[i]!=golden[i];
        }
        putchar('\n');
    }
    uint64_t result=ip[0x80000];
    unsigned digit=(result>>16)&15;
    if (digit>=10 || logits[digit]!=(uint16_t)result) die("Invalid result word");
    printf("Predicted digit = %u\n",digit);
    if (argc==3) puts(mismatch?"FAIL":"PASS: 10/10 logits");
    munmap((void *)ip,LENET_SIZE);
    munmap((void *)dma,4096);
    munmap(buf,capacity);
    close(mem);
    close(buf_fd);
    return mismatch!=0;
}
