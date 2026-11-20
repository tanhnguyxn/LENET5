// Classic LeNet5: run in the directory containing the exported Q8.8 hex files.
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

static int image[784], w1[150], w2[2400], w3[30720], w4[10080], w5[840];
static int b1[6], b2[16], b3[120], b4[84], b5[10];
static int c1[6*24*24], p1[6*12*12], c2[16*8*8], p2[256], f1[120], f2[84], out[10];

static void die(const char *s) { perror(s); exit(1); }

// Emit one stimulus line per RAM row: byte offset, byte enables, packed data.
static void load(FILE *stim,const char *name,int *a,unsigned n,unsigned base) {
    FILE *f=fopen(name,"r");
    if (!f) die(name);
    char token[32];
    for(unsigned i=0;i<n;i++) {
        if(fscanf(f,"%31s",token)!=1 || strlen(token)>4 ||
           strspn(token,"0123456789abcdefABCDEF")!=strlen(token)) {
            fprintf(stderr,"Invalid or missing word %u in %s\n",i,name); exit(1);
        }
        int v=(int)strtol(token,NULL,16);
        a[i]=v>=32768?v-65536:v;
    }
    if(fscanf(f,"%31s",token)==1 || ferror(f)) {fprintf(stderr,"Invalid length/read: %s\n",name);exit(1);}
    fclose(f);
    for(unsigned i=0;i<n;i+=8) {
        unsigned lanes=n-i<8?n-i:8;
        fprintf(stim,"%06X %04X ",base+2*i,(1u<<(2*lanes))-1);
        for(int k=7;k>=0;k--)
            fprintf(stim,"%04X",(unsigned)k<lanes?(unsigned)(uint16_t)a[i+k]:0u);
        fputc('\n',stim);
    }
}

// Match signed arithmetic shift on each product, including negative fractions.
static int mul_q88(int a,int b) {
    int64_t p=(int64_t)a*b;
    return (int)(p>=0?p/256:-((-p+255)/256));
}
static int post(int64_t s,int relu) {
    if(relu && s<0) return 0;
    return s>32767?32767:s< -32768?-32768:(int)s;
}
static void conv(const int *x,int side,int ci,const int *w,const int *b,int co,int *y) {
    int os=side-4;
    for(int o=0;o<co;o++) for(int r=0;r<os;r++) for(int c=0;c<os;c++) {
        int64_t s=b[o];
        for(int i=0;i<ci;i++) for(int ky=0;ky<5;ky++) for(int kx=0;kx<5;kx++)
            s+=mul_q88(x[(i*side+r+ky)*side+c+kx],w[((o*ci+i)*5+ky)*5+kx]);
        y[(o*os+r)*os+c]=post(s,1);
    }
}
static void pool(const int *x,int side,int channels,int *y) {
    int os=side/2;
    for(int ch=0;ch<channels;ch++) for(int r=0;r<os;r++) for(int c=0;c<os;c++) {
        int pos=(ch*side+2*r)*side+2*c, m=x[pos];
        for(int dy=0;dy<2;dy++) for(int dx=0;dx<2;dx++)
            if(x[pos+dy*side+dx]>m) m=x[pos+dy*side+dx];
        y[(ch*os+r)*os+c]=m;
    }
}
static void fc(const int *x,int ni,const int *w,const int *b,int no,int relu,int *y) {
    for(int o=0;o<no;o++) {
        int64_t s=b[o];
        for(int i=0;i<ni;i++) s+=mul_q88(x[i],w[o*ni+i]);
        y[o]=post(s,relu);
    }
}
int main(void) {
    FILE *stim=fopen("core_writes.txt","w");
    if(!stim) die("core_writes.txt");
#define LOAD(name,a,base) load(stim,name ".hex",a,sizeof(a)/sizeof(a[0]),base)
    LOAD("conv1_weight",w1,0x20000); LOAD("conv2_weight",w2,0x30000);
    LOAD("fc1_weight",w3,0x40000); LOAD("fc2_weight",w4,0x50000);
    LOAD("fc3_weight",w5,0x60000);
    LOAD("conv1_bias",b1,0x70000); LOAD("conv2_bias",b2,0x71000);
    LOAD("fc1_bias",b3,0x72000); LOAD("fc2_bias",b4,0x73000);
    LOAD("fc3_bias",b5,0x74000); LOAD("sample_input",image,0x10000);
    if(fclose(stim)) die("core_writes.txt");
    conv(image,28,1,w1,b1,6,c1); pool(c1,24,6,p1);
    conv(p1,12,6,w2,b2,16,c2); pool(c2,8,16,p2);
    fc(p2,256,w3,b3,120,1,f1); fc(f1,120,w4,b4,84,1,f2);
    fc(f2,84,w5,b5,10,0,out);
    FILE *g=fopen("golden_logits.hex","w");
    if(!g) die("golden_logits.hex");
    for(int i=0;i<10;i++) fprintf(g,"%04X\n",(unsigned)(uint16_t)out[i]);
    if(fclose(g)) die("golden_logits.hex");
    return 0;
}
