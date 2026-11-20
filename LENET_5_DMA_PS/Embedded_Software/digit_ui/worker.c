// Reuse the AXI map and inference routine from the working board program.
#define main sample_program_main
#include "../lenet5_kr260.c"
#undef main

int main(void) {
    if (!LENET5_BASE) fail("Set LENET5_BASE in ../lenet5_kr260.c");
    int fd = open("/dev/mem", O_RDWR | O_SYNC);
    if (fd < 0) { perror("/dev/mem"); return 1; }
    void *map = mmap(NULL, MAP_BYTES, PROT_READ | PROT_WRITE, MAP_SHARED, fd, LENET5_BASE);
    close(fd);
    if (map == MAP_FAILED) { perror("mmap"); return 1; }
    volatile uint64_t *regs = map;
    if (regs[0] & 1) fail("Core busy");
    static uint16_t buffer[30720];
    for (unsigned b = 0; b < sizeof params / sizeof params[0]; ++b) {
        load_hex(HEX_DIR, params[b].name, params[b].count, buffer);
        for (unsigned i = 0; i < params[b].count; ++i)
            regs[params[b].address+i] = buffer[i];
    }
    puts("READY");
    fflush(stdout);
    uint8_t gray[784];
    uint16_t image[784], logits[10], score;
    while (fread(gray, 1, sizeof gray, stdin) == sizeof gray) {
        for (unsigned i = 0; i < 784; ++i)
            image[i] = (gray[i] * 256u + 127u) / 255u;
        if (regs[0] & 1) fail("Core busy");
        double begin = seconds();
        for (unsigned i = 0; i < 784; ++i) regs[0x10000+i] = image[i];
        __sync_synchronize();
        double loaded = seconds();
        regs[0] = 1;
        __sync_synchronize();
        while ((regs[0] & 3) != 2)
            if (seconds() - loaded > 2.0) fail("Timeout waiting for DONE");
        double done = seconds();
        for (unsigned i = 0; i < 10; ++i) logits[i] = (uint16_t)regs[0x90000+i];
        uint64_t result = regs[0x80000];
        __sync_synchronize();
        double end = seconds();
        score = (uint16_t)result;
        unsigned digit = (unsigned)((result >> 16) & 15);
        if (digit > 9 || score != logits[digit]) fail("Invalid FPGA prediction");
        printf("%u", digit);
        for (unsigned i = 0; i < 10; ++i) printf(" %d", signed16(logits[i]));
        printf(" %.3f %.3f %.3f %.3f\n", (loaded-begin)*1e6,
               (done-loaded)*1e6, (end-done)*1e6, (end-begin)*1e6);
        fflush(stdout);
    }
    munmap(map, MAP_BYTES);
    return ferror(stdin) != 0;
}
