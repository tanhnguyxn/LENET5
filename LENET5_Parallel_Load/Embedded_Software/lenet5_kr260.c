#define _FILE_OFFSET_BITS 64
#define _POSIX_C_SOURCE 200809L
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <errno.h>
#include <ctype.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <time.h>
#include <unistd.h>

#define MAP_BYTES 0x480050u
struct block { const char *name; unsigned address, count; };
static const struct block params[] = {
    {"conv1_weight",0x20000,150}, {"conv2_weight",0x30000,2400},
    {"fc1_weight",0x40000,30720}, {"fc2_weight",0x50000,10080},
    {"fc3_weight",0x60000,840}, {"conv1_bias",0x70000,6},
    {"conv2_bias",0x72000,16}, {"fc1_bias",0x74000,120},
    {"fc2_bias",0x76000,84}, {"fc3_bias",0x78000,10}
};

static void fail(const char *msg) { fprintf(stderr,"%s\n",msg); exit(1); }

static void load_hex(const char *dir, const char *name, unsigned n, uint16_t *out) {
    char path[4096], token[64];
    int len = snprintf(path,sizeof path,"%s/%s.hex",dir,name);
    if (len < 0 || (size_t)len >= sizeof path) fail("Path too long");
    FILE *f = fopen(path,"r");
    if (!f) { perror(path); exit(1); }
    for (unsigned i=0; i<n; ++i) {
        if (fscanf(f,"%63s",token)!=1) fail(path);
        unsigned v=0, j=0;
        for (; token[j]; ++j) {
            unsigned char c=(unsigned char)token[j];
            if (!isxdigit(c) || j>=4) fail(path);
            v=v*16+(isdigit(c)?c-'0':tolower(c)-'a'+10);
        }
        out[i]=(uint16_t)v;
    }
    if (fscanf(f,"%63s",token)!=EOF || ferror(f)) fail(path);
    fclose(f);
}

static double seconds(void) {
    struct timespec t;
    if (clock_gettime(CLOCK_MONOTONIC,&t)) fail("Clock error");
    return t.tv_sec+t.tv_nsec*1e-9;
}

static int signed16(uint16_t v) { return v<0x8000 ? v : (int)v-65536; }

// Each array index is one 64-bit AXI word, i.e. eight bytes.
static unsigned predict(volatile uint64_t *regs, const uint16_t image[784],
                        uint16_t logits[10], uint16_t *score) {
    if (regs[0]&1) fail("Core busy before image load");
    for (unsigned i=0;i<784;++i) regs[0x10000+i]=image[i];
    __sync_synchronize();
    regs[0]=1;
    __sync_synchronize();
    double deadline=seconds()+2.0;
    while ((regs[0]&3)!=2)
        if (seconds()>deadline) fail("Timeout waiting for DONE");
    for (unsigned i=0;i<10;++i) logits[i]=(uint16_t)regs[0x90000+i];
    uint64_t result=regs[0x80000];
    *score=(uint16_t)result;
    return (unsigned)((result>>16)&15);
}

// Set this once to the IP base address in Vivado Address Editor.
#define LENET5_BASE 0x0ULL
#define HEX_DIR "../train_model/outputs_q88"

int main(void) {
    if (LENET5_BASE == 0) fail("Set LENET5_BASE in the C file before running");
    const unsigned long long base = LENET5_BASE;
    static uint16_t weights[44426], image[784], golden[10], logits[10];
    unsigned pos=0;
    for (unsigned b=0;b<sizeof params/sizeof params[0];++b) {
        load_hex(HEX_DIR,params[b].name,params[b].count,weights+pos);
        pos+=params[b].count;
    }
    load_hex(HEX_DIR,"sample_input",784,image);
    load_hex(HEX_DIR,"sample_logits",10,golden);
    int fd=open("/dev/mem",O_RDWR|O_SYNC);
    if (fd<0) { perror("/dev/mem"); return 1; }
    void *map=mmap(NULL,MAP_BYTES,PROT_READ|PROT_WRITE,MAP_SHARED,fd,(off_t)base);
    close(fd);
    if (map==MAP_FAILED) { perror("mmap"); return 1; }
    volatile uint64_t *regs=map;
    if (regs[0]&1) fail("Core busy before parameter load");
    pos=0;
    for (unsigned b=0;b<sizeof params/sizeof params[0];++b)
        for (unsigned i=0;i<params[b].count;++i)
            regs[params[b].address+i]=weights[pos++];
    uint16_t score;
    unsigned digit=predict(regs,image,logits,&score), best=0;
    int ok=1;
    puts("Digit  RTL   Golden");
    for (unsigned i=0;i<10;++i) {
        printf("%5u  %04X  %04X\n",i,(unsigned)logits[i],(unsigned)golden[i]);
        if (logits[i]!=golden[i]) ok=0;
        if (signed16(golden[i])>signed16(golden[best])) best=i;
    }
    ok=ok && digit==best && score==golden[best];
    printf("Predicted digit: %u   Score: %.6f\n%s\n",digit,signed16(score)/256.0,ok?"PASS":"FAIL");
    munmap(map,MAP_BYTES);
    return !ok;
}
