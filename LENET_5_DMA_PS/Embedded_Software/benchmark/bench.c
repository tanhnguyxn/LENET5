// Build for little-endian KR260 Linux.
#define _POSIX_C_SOURCE 200809L
#define _FILE_OFFSET_BITS 64
#include <errno.h>
#include <sys/ioctl.h>
#include "zdma_api.h"
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
    {"fc2 bias",0x76000,84}, {"fc3 bias",0x78000,10}
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
static volatile uint64_t *ip;
static volatile uint32_t *dma;
static uint64_t *buf;
static uint32_t src,base;
static uint16_t weights[44426],sample[2][784],gold[2][10];
struct row {double upload,wait,read,total; unsigned digit;};

static unsigned long parse(const char *s, unsigned long max) {
    char *end;
    errno=0;
    unsigned long v=strtoul(s,&end,0);
    if(errno || end==s || *end || !v || v>max) die("Invalid address or count");
    return v;
}
static void exact(FILE *f,void *data,size_t bytes) {
    if(fread(data,1,bytes,f)!=bytes) die("Incomplete dataset");
}
static FILE *dataset(const char *name,const char *magic) {
    FILE *f=fopen(name,"rb");
    char tag[4];
    if(!f) os_error(name);
    exact(f,tag,4);
    if(memcmp(tag,magic,4)) die("Wrong dataset type");
    return f;
}
static void eof(FILE *f) {
    if(fgetc(f)!=EOF || ferror(f)) die("Dataset length mismatch");
    fclose(f);
}
static int zdma_fd = -1;

static void upload(uint32_t word,const uint16_t *v,unsigned count) {
    if(zdma_fd>=0) {
        for(unsigned i=0;i<count;) {
            unsigned n=count-i;
            if(n>CHUNK) n=CHUNK;
            struct lenet_write w={.word=word+i,.count=n,.values=(uintptr_t)(v+i)};
            if(ioctl(zdma_fd,LENET_WRITE,&w)<0) os_error("PS ZDMA upload");
            i+=n;
        }
    } else if(!dma) {
        for(unsigned i=0;i<count;i++) ip[word+i]=v[i];
    } else {
        for(unsigned i=0;i<count;) {
            unsigned n=count-i;
            if(n>CHUNK) n=CHUNK;
            attr(BUF_SYS "sync_for_cpu","1");
            for(unsigned j=0;j<n;j++) buf[j]=v[i+j];
            __sync_synchronize();
            attr(BUF_SYS "sync_for_device","1");
            cdma_transfer(dma,src,base+8u*(word+i),8*n);
            i+=n;
        }
    }
    __sync_synchronize();
}
static struct row infer(const uint16_t *x,const uint16_t *expected) {
    if(ip[0]&1) die("Core already busy");
    double t0=seconds();
    upload(0x10000,x,784);
    double t1=seconds();
    ip[0]=1;
    __sync_synchronize();
    while((ip[0]&3)!=2)
        if(seconds()-t1>2) die("Timeout waiting for DONE");
    double t2=seconds();
    uint16_t logits[10];
    for(unsigned j=0;j<10;j++) logits[j]=(uint16_t)ip[0x90000+j];
    uint64_t res=ip[0x80000];
    __sync_synchronize();
    double t3=seconds();
    unsigned digit=(res>>16)&15;
    if(digit>=10 || logits[digit]!=(uint16_t)res) die("Invalid result register");
    for(unsigned j=0;j<10;j++) {
        if(expected && logits[j]!=expected[j]) {
            fprintf(stderr,"logit[%u] actual=%04x expected=%04x\n",j,(unsigned)logits[j],(unsigned)expected[j]);
            exit(1);
        }
        if((int16_t)logits[j]>(int16_t)logits[digit]) die("Invalid argmax");
    }
    return (struct row){(t1-t0)*1e6,(t2-t1)*1e6,(t3-t2)*1e6,(t3-t0)*1e6,digit};
}
int main(int argc,char **argv) {
    if(argc!=7 || (strcmp(argv[1],"pio") && strcmp(argv[1],"cdma") && strcmp(argv[1],"zdma"))) {
        fprintf(stderr,"Usage: %s pio|zdma|cdma IP_BASE -|CDMA_BASE prep.bin N|mnist.bin NEW.csv\n",argv[0]);
        return 2;
    }
    base=parse(argv[2],UINT32_MAX-LENET_SIZE+1u);
    int use_dma=!strcmp(argv[1],"cdma");
    if(!use_dma && strcmp(argv[3],"-")) die("Use - for PIO or PS ZDMA");
    uint32_t db=use_dma?parse(argv[3],UINT32_MAX-4095u):0;
    if(base%4096 || db%4096 || (use_dma && ((uint64_t)db+4096>base && (uint64_t)base+LENET_SIZE>db)))
        die("Unaligned or overlapping addresses");
    FILE *f=dataset(argv[4],"L5P1");
    exact(f,weights,sizeof weights);
    for(int i=0;i<2;i++) {exact(f,sample[i],sizeof sample[i]); exact(f,gold[i],sizeof gold[i]);}
    eof(f);
    unsigned char *data=NULL;
    unsigned n;
    if(strspn(argv[5],"0123456789")==strlen(argv[5])) n=parse(argv[5],1000000);
    else {
        n=10000;
        data=malloc(n*1569u);
        if(!data) die("Out of memory");
        f=dataset(argv[5],"L5M1"); exact(f,data,n*1569u); eof(f);
    }
    struct row *rows=calloc(n,sizeof *rows);
    if(!rows) die("Out of memory");
    if(!strcmp(argv[1],"zdma")) {
        __u64 configured=0;
        zdma_fd=open("/dev/lenet_zdma",O_RDWR);
        if(zdma_fd<0) os_error("/dev/lenet_zdma");
        if(ioctl(zdma_fd,LENET_BASE_GET,&configured)<0) os_error("ZDMA base");
        if(configured!=base) die("IP base differs from module ip_base");
    }
    int mem=open("/dev/mem",O_RDWR|O_SYNC);
    if(mem<0) os_error("/dev/mem");
    ip=map_fd(mem,LENET_SIZE,base);
    if(ip[0]&1) die("Core already busy");
    if(use_dma) {
        int fd=open(BUF_DEV,O_RDWR|O_SYNC);
        if(fd<0 || flock(fd,LOCK_EX|LOCK_NB)) os_error(BUF_DEV);
        uint64_t addr=number(BUF_SYS "phys_addr");
        if(addr>UINT32_MAX-4095 || addr%8 || number(BUF_SYS "size")<4096) die("Invalid DMA buffer");
        src=(uint32_t)addr;
        buf=map_fd(fd,4096,0);
        dma=map_fd(mem,4096,db);
        if(!(dma[SR/4]&IDLE)) die("CDMA not idle");
        cdma_reset(dma);
        attr(BUF_SYS "sync_offset","0"); attr(BUF_SYS "sync_size","4096"); attr(BUF_SYS "sync_direction","1");
    }
    size_t offset=0;
    double t=seconds();
    for(unsigned b=0;b<sizeof blocks/sizeof blocks[0];b++) {
        upload(blocks[b].word,weights+offset,blocks[b].count);
        offset+=blocks[b].count;
    }
    double param_ms=(seconds()-t)*1000;
    for(unsigned k=0;k<3;k++) infer(sample[k%2],gold[k%2]);
    puts("PASS A-B-A: 10/10 logits each");
    unsigned correct=0;
    uint16_t img[784];
    t=seconds();
    for(unsigned i=0;i<n;i++) {
        const uint16_t *x=sample[i%2];
        if(data) {memcpy(img,data+i*1569u+1,sizeof img); x=img;}
        rows[i]=infer(x,data?NULL:gold[i%2]);
        if(data && rows[i].digit==data[i*1569u]) correct++;
    }
    double batch=seconds()-t;
    FILE *out=fopen(argv[6],"wx");
    if(!out) os_error(argv[6]);
    fprintf(out,"mode,index,label,pred,upload_us,start_done_us,read_us,total_us\n");
    double total=0;
    for(unsigned i=0;i<n;i++) {
        struct row r=rows[i]; total+=r.total;
        fprintf(out,"%s,%u,%d,%u,%.3f,%.3f,%.3f,%.3f\n",argv[1],i,data?(int)data[i*1569u]:-1,r.digit,r.upload,r.wait,r.read,r.total);
    }
    if(fclose(out)) os_error("CSV");
    printf("params_ms=%.3f batch_s=%.6f images=%u fps=%.2f mean_total_us=%.3f\n",param_ms,batch,n,n/batch,total/n);
    if(data) printf("MNIST accuracy=%u/%u (%.2f%%)\n",correct,n,100.*correct/n);
    return 0;
}
