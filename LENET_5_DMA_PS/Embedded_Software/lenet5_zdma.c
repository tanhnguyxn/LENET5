#define _POSIX_C_SOURCE 200809L
#define _FILE_OFFSET_BITS 64

#include <ctype.h>
#include <fcntl.h>
#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/mman.h>
#include <time.h>
#include <unistd.h>

typedef uint16_t U16;
typedef uint32_t U32;
typedef uint64_t U64;

/* ================================================================
 * LeNet5 on KR260
 *
 * Control and results : PIO through /dev/mem
 * Weights, bias, image: PS ZDMA, from DDR to the LeNet5 AXI slave
 * Data format         : signed Q8.8, stored as 16-bit words
 *
 * All IP offsets in this file are BYTE offsets.
 * ================================================================ */


/* ================================================================
 * 1. Physical address map
 * ================================================================ */

/* PS general-purpose DMA, channel 0. */
#define ZDMA_BASE             UINT64_C(0xFD500000)
#define ZDMA_MAP_SIZE         0x1000u

/* LeNet5 AXI slave in the PL. */
#define LENET_BASE            UINT64_C(0xA0000000)
#define LENET_MAP_SIZE        0x80000u       /* 512 KiB */

/* Reserved DDR staging buffer from the lab template. */
#define DDR_INPUT_PHYS        UINT64_C(0x800010000)
#define DDR_MAP_SIZE          0x10000u       /* 64 KiB */

/* Run ./main from Embedded_Software. */
#define HEX_DIR               "../train_model/outputs_q88"

#define TIMEOUT_SECONDS       2.0


/* ================================================================
 * 2. LeNet5 register and memory offsets
 * ================================================================ */

/* PIO registers: START is written; STATUS is read at the same offset. */
#define REG_W_START           0x00000u
#define REG_R_STATUS          0x00000u
#define REG_R_PREDICTION      0x00010u
#define REG_R_CYCLES          0x00020u
#define REG_R_VERSION         0x00030u
#define REG_R_LOGITS          0x00100u

#define STATUS_BUSY           0x01u
#define STATUS_DONE           0x02u
#define EXPECTED_VERSION      0x4C4E1281u

/* DMA write destinations inside LeNet5. */
#define MEM_IMAGE             0x10000u

#define MEM_CONV1_WEIGHT      0x20000u
#define MEM_CONV2_WEIGHT      0x30000u
#define MEM_FC1_WEIGHT        0x40000u
#define MEM_FC2_WEIGHT        0x50000u
#define MEM_FC3_WEIGHT        0x60000u

#define MEM_CONV1_BIAS        0x70000u
#define MEM_CONV2_BIAS        0x71000u
#define MEM_FC1_BIAS          0x72000u
#define MEM_FC2_BIAS          0x73000u
#define MEM_FC3_BIAS          0x74000u


/* ================================================================
 * 3. ZDMA register offsets
 * ================================================================ */

#define ZDMA_CH_ISR           0x100u
#define ZDMA_CH_IDS           0x10Cu
#define ZDMA_CH_CTRL0         0x110u
#define ZDMA_CH_CTRL1         0x114u
#define ZDMA_CH_FCI           0x118u
#define ZDMA_CH_STATUS        0x11Cu
#define ZDMA_CH_DATA_ATTR     0x120u
#define ZDMA_CH_DSCR_ATTR     0x124u

#define ZDMA_SRC_LSB          0x128u
#define ZDMA_SRC_MSB          0x12Cu
#define ZDMA_SRC_LENGTH       0x130u

#define ZDMA_DST_LSB          0x138u
#define ZDMA_DST_MSB          0x13Cu
#define ZDMA_DST_LENGTH       0x140u

#define ZDMA_CH_CTRL2         0x200u

#define ZDMA_ALL_FLAGS        0xFFFu
#define ZDMA_DONE_FLAG        0x400u
#define ZDMA_ERROR_FLAGS      0xBF9u


/* ================================================================
 * 4. Hardware context and prediction result
 * ================================================================ */

struct hw_context {
    volatile U32 *dma;       /* ZDMA control registers */
    volatile U32 *pio;       /* LeNet5 control/result registers */
    volatile U16 *ddr;       /* CPU view of the DDR staging buffer */
};

struct lenet_result {
    U16 logits[10];
    U16 score;
    U32 digit;
    U32 cycles;
};


/* ================================================================
 * 5. Common helpers
 * ================================================================ */

static void fail(const char *message)
{
    fprintf(stderr, "[ERROR] %s\n", message);
    exit(EXIT_FAILURE);
}

static double time_seconds(void)
{
    struct timespec ts;

    if (clock_gettime(CLOCK_MONOTONIC, &ts) != 0) {
        perror("clock_gettime");
        exit(EXIT_FAILURE);
    }

    return (double)ts.tv_sec + (double)ts.tv_nsec * 1.0e-9;
}

static int q88_signed(U16 value)
{
    return (value < 0x8000u) ? (int)value : (int)value - 65536;
}

static void barrier(void)
{
    __sync_synchronize();
}


/* ================================================================
 * 6. Open and close hardware
 * ================================================================ */

static void *map_region(int fd, U64 phys_addr, size_t size)
{
    void *ptr = mmap(NULL, size,
                     PROT_READ | PROT_WRITE,
                     MAP_SHARED, fd, (off_t)phys_addr);

    if (ptr == MAP_FAILED) {
        fprintf(stderr, "Cannot map 0x%" PRIx64 ": ", phys_addr);
        perror("mmap");
        exit(EXIT_FAILURE);
    }

    return ptr;
}

static void hw_open(struct hw_context *hw)
{
    int fd = open("/dev/mem", O_RDWR | O_SYNC);

    if (fd < 0) {
        perror("open /dev/mem");
        exit(EXIT_FAILURE);
    }

    hw->dma = map_region(fd, ZDMA_BASE,      ZDMA_MAP_SIZE);
    hw->pio = map_region(fd, LENET_BASE,     LENET_MAP_SIZE);
    hw->ddr = map_region(fd, DDR_INPUT_PHYS, DDR_MAP_SIZE);

    /* The mappings remain valid after closing the file descriptor. */
    close(fd);
}

static void hw_close(struct hw_context *hw)
{
    munmap((void *)hw->ddr, DDR_MAP_SIZE);
    munmap((void *)hw->pio, LENET_MAP_SIZE);
    munmap((void *)hw->dma, ZDMA_MAP_SIZE);
}


/* ================================================================
 * 7. Register access and LeNet5 PIO
 * ================================================================ */

/*
 * base points to 32-bit registers.
 * Divide the byte offset by 4 to obtain the C array index.
 */
static void reg_write32(volatile U32 *base, U32 byte_offset, U32 value)
{
    barrier();
    base[byte_offset / 4u] = value;
    barrier();
}

static U32 reg_read32(volatile U32 *base, U32 byte_offset)
{
    U32 value = base[byte_offset / 4u];
    barrier();
    return value;
}

/* Use these two functions for LeNet5, not for the ZDMA registers. */
static void pio_write(struct hw_context *hw, U32 byte_offset, U32 value)
{
    reg_write32(hw->pio, byte_offset, value);
}

static U32 pio_read(struct hw_context *hw, U32 byte_offset)
{
    return reg_read32(hw->pio, byte_offset);
}


/* ================================================================
 * 8. Read a Q8.8 HEX file
 *
 * One token = one 16-bit word.
 * Example: 001D FFFF 0100
 * ================================================================ */

static void read_hex_file(const char *name, U16 *out, unsigned count)
{
    char path[4096];
    char token[64];

    int n = snprintf(path, sizeof path, "%s/%s.hex", HEX_DIR, name);
    if (n < 0 || (size_t)n >= sizeof path)
        fail("HEX file path is too long");

    FILE *fp = fopen(path, "r");
    if (fp == NULL) {
        perror(path);
        exit(EXIT_FAILURE);
    }

    for (unsigned i = 0; i < count; ++i) {
        if (fscanf(fp, "%63s", token) != 1) {
            fprintf(stderr, "[ERROR] %s: missing element %u\n", path, i);
            exit(EXIT_FAILURE);
        }

        unsigned value = 0;

        for (unsigned j = 0; token[j] != '\0'; ++j) {
            unsigned char c = (unsigned char)token[j];

            if (j >= 4 || !isxdigit(c)) {
                fprintf(stderr, "[ERROR] %s: invalid HEX word '%s'\n",
                        path, token);
                exit(EXIT_FAILURE);
            }

            unsigned digit = isdigit(c)
                           ? (unsigned)(c - '0')
                           : (unsigned)(tolower(c) - 'a' + 10);

            value = (value << 4) | digit;
        }

        out[i] = (U16)value;
    }

    if (fscanf(fp, "%63s", token) != EOF || ferror(fp)) {
        fprintf(stderr, "[ERROR] %s: extra data or read error\n", path);
        exit(EXIT_FAILURE);
    }

    fclose(fp);
}


/* ================================================================
 * 9. Initialize ZDMA for polling
 * ================================================================ */

static void dma_init(volatile U32 *dma)
{
    U32 status = reg_read32(dma, ZDMA_CH_STATUS);

    if ((status & 0x3u) != 0u)
        fail("GDMA channel 0 is not idle");

    /* Disable interrupts and clear old status flags. */
    reg_write32(dma, ZDMA_CH_IDS, ZDMA_ALL_FLAGS);
    reg_write32(dma, ZDMA_CH_ISR, ZDMA_ALL_FLAGS);

    /* Register-mode settings from the Median Filter lab template. */
    reg_write32(dma, ZDMA_CH_CTRL0,     0x00000080u);
    reg_write32(dma, ZDMA_CH_CTRL1,     0x000003FFu);
    reg_write32(dma, ZDMA_CH_FCI,       0x00000000u);
    reg_write32(dma, ZDMA_CH_DATA_ATTR, 0x04C3D30Fu);
    reg_write32(dma, ZDMA_CH_DSCR_ATTR, 0x00000000u);
}


/* ================================================================
 * 10. Wait for ZDMA completion
 *
 * DMA DONE means the data transfer has finished.
 * It does not mean that LeNet5 has finished inference.
 * ================================================================ */

static int dma_wait_done(volatile U32 *dma)
{
    double deadline = time_seconds() + TIMEOUT_SECONDS;

    for (;;) {
        U32 isr    = reg_read32(dma, ZDMA_CH_ISR);
        U32 status = reg_read32(dma, ZDMA_CH_STATUS);

        if (isr & ZDMA_ERROR_FLAGS) {
            fprintf(stderr,
                    "[DMA ERROR] ISR=0x%08x STATUS=0x%08x\n",
                    isr, status);
            return -1;
        }

        if ((isr & ZDMA_DONE_FLAG) && ((status & 0x3u) == 0u))
            return 0;

        if (time_seconds() >= deadline) {
            fprintf(stderr,
                    "[DMA TIMEOUT] ISR=0x%08x STATUS=0x%08x\n",
                    isr, status);
            return -1;
        }
    }
}


/* ================================================================
 * 11. Transfer one block: source -> destination
 *
 * Sequence from the lab:
 *   1. Set source address and length.
 *   2. Set destination address and length.
 *   3. Start ZDMA.
 *   4. Wait for DMA DONE.
 * ================================================================ */

static int dma_transfer(volatile U32 *dma,
                        U64 src_phys,
                        U64 dst_phys,
                        U32 length_bytes)
{
    /* Clear flags left by the previous transfer. */
    reg_write32(dma, ZDMA_CH_ISR, ZDMA_ALL_FLAGS);

    /* Source: reserved DDR buffer. */
    reg_write32(dma, ZDMA_SRC_LSB,    (U32)src_phys);
    reg_write32(dma, ZDMA_SRC_MSB,    (U32)(src_phys >> 32));
    reg_write32(dma, ZDMA_SRC_LENGTH, length_bytes);

    /* Destination: memory inside LeNet5. */
    reg_write32(dma, ZDMA_DST_LSB,    (U32)dst_phys);
    reg_write32(dma, ZDMA_DST_MSB,    (U32)(dst_phys >> 32));
    reg_write32(dma, ZDMA_DST_LENGTH, length_bytes);

    /* Start the physical DMA channel in the PS. */
    reg_write32(dma, ZDMA_CH_CTRL2, 1u);

    return dma_wait_done(dma);
}


/* ================================================================
 * 12. Load one HEX file: file -> DDR -> LeNet5 memory
 * ================================================================ */

static void dma_load_file(struct hw_context *hw,
                          const char *file_name,
                          U32 ip_byte_offset,
                          unsigned element_count)
{
    static U16 host_data[DDR_MAP_SIZE / sizeof(U16)];

    if (element_count == 0u ||
        element_count > sizeof host_data / sizeof host_data[0])
        fail("Invalid block size for the DDR buffer");

    U32 length_bytes = (U32)element_count * 2u;
    U64 dst_phys     = LENET_BASE + ip_byte_offset;

    /* CPU reads the text file and produces binary Q8.8 words. */
    read_hex_file(file_name, host_data, element_count);

    /* CPU writes the binary words into DDR, not into LeNet5. */
    for (unsigned i = 0; i < element_count; ++i)
        hw->ddr[i] = host_data[i];

    /* Ordering only; this is not a cache flush. */
    barrier();

    printf("[DMA] %-13s  DDR 0x%" PRIx64
           " -> IP 0x%" PRIx64 "  (%u bytes)\n",
           file_name, DDR_INPUT_PHYS, dst_phys, length_bytes);
    fflush(stdout);

    /* ZDMA now moves the whole block from DDR to the IP. */
    if (dma_transfer(hw->dma, DDR_INPUT_PHYS, dst_phys, length_bytes) != 0) {
        fprintf(stderr, "[ERROR] Failed to load %s\n", file_name);
        exit(EXIT_FAILURE);
    }

    /* DDR can now be reused for the next file. */
}


/* ================================================================
 * 13. Load weights, biases and image
 *
 * The last argument is the number of Q8.8 elements, not bytes.
 * ================================================================ */

static void load_weights(struct hw_context *hw)
{
    dma_load_file(hw, "conv1_weight", MEM_CONV1_WEIGHT,   150u);
    dma_load_file(hw, "conv2_weight", MEM_CONV2_WEIGHT,  2400u);
    dma_load_file(hw, "fc1_weight",   MEM_FC1_WEIGHT,   30720u);
    dma_load_file(hw, "fc2_weight",   MEM_FC2_WEIGHT,   10080u);
    dma_load_file(hw, "fc3_weight",   MEM_FC3_WEIGHT,     840u);
}

static void load_biases(struct hw_context *hw)
{
    dma_load_file(hw, "conv1_bias", MEM_CONV1_BIAS,   6u);
    dma_load_file(hw, "conv2_bias", MEM_CONV2_BIAS,  16u);
    dma_load_file(hw, "fc1_bias",   MEM_FC1_BIAS,   120u);
    dma_load_file(hw, "fc2_bias",   MEM_FC2_BIAS,    84u);
    dma_load_file(hw, "fc3_bias",   MEM_FC3_BIAS,    10u);
}

static void load_image(struct hw_context *hw)
{
    dma_load_file(hw, "sample_input", MEM_IMAGE, 28u * 28u);
}


/* ================================================================
 * 14. Wait for LeNet5 inference
 *
 * Here we read the STATUS register of LeNet5, not the ZDMA ISR.
 * ================================================================ */

static int wait_lenet_done(struct hw_context *hw)
{
    double deadline = time_seconds() + TIMEOUT_SECONDS;

    for (;;) {
        U32 status = pio_read(hw, REG_R_STATUS);

        if ((status & (STATUS_BUSY | STATUS_DONE)) == STATUS_DONE)
            return 0;

        if (time_seconds() >= deadline) {
            fprintf(stderr, "[LENET TIMEOUT] STATUS=0x%08x\n", status);
            return -1;
        }
    }
}


/* ================================================================
 * 15. Read the prediction and logits using PIO
 * ================================================================ */

static void read_result(struct hw_context *hw, struct lenet_result *result)
{
    U32 prediction = pio_read(hw, REG_R_PREDICTION);

    /* Prediction register: [19:16] class, [15:0] signed Q8.8 score. */
    result->digit  = (prediction >> 16) & 0xFu;
    result->score  = (U16)prediction;
    result->cycles = pio_read(hw, REG_R_CYCLES);

    /*
     * One 32-bit PIO read returns two 16-bit logits.
     * 0x100: logits 0,1     0x104: logits 2,3
     * 0x108: logits 4,5     0x10C: logits 6,7
     * 0x110: logits 8,9
     */
    for (unsigned pair = 0; pair < 5u; ++pair) {
        U32 word = pio_read(hw, REG_R_LOGITS + pair * 4u);

        result->logits[2u * pair]      = (U16)word;
        result->logits[2u * pair + 1u] = (U16)(word >> 16);
    }
}


/* ================================================================
 * 16. Compare hardware outputs with the golden file
 * ================================================================ */

static int compare_with_golden(const struct lenet_result *result,
                               const U16 golden[10])
{
    unsigned best = 0;
    int pass = 1;

    puts("\nDigit   RTL    Golden");

    for (unsigned i = 0; i < 10u; ++i) {
        printf("%5u   %04X   %04X%s\n",
               i,
               (unsigned)result->logits[i],
               (unsigned)golden[i],
               result->logits[i] == golden[i] ? "" : "  <-- mismatch");

        if (result->logits[i] != golden[i])
            pass = 0;

        if (q88_signed(golden[i]) > q88_signed(golden[best]))
            best = i;
    }

    if (result->digit != best || result->score != golden[best])
        pass = 0;

    printf("\nPredicted digit : %u\n", result->digit);
    printf("Expected digit  : %u\n", best);
    printf("Predicted score : %.6f\n", q88_signed(result->score) / 256.0);
    printf("Core cycles     : %u\n", result->cycles);
    puts(pass ? "PASS" : "FAIL");

    return pass;
}


/* ================================================================
 * 17. Main program
 * ================================================================ */

int main(void)
{
    struct hw_context hw;
    struct lenet_result result;
    U16 golden[10];
    int pass;

    /* Golden outputs stay on the CPU. They are not loaded into LeNet5. */
    read_hex_file("sample_logits", golden, 10u);

    /* 1. Open the board hardware and check the loaded IP. */
    hw_open(&hw);

    U32 version = pio_read(&hw, REG_R_VERSION);
    if (version != EXPECTED_VERSION) {
        fprintf(stderr,
                "[ERROR] LeNet version: read 0x%08x, expected 0x%08x\n",
                version, EXPECTED_VERSION);
        hw_close(&hw);
        return EXIT_FAILURE;
    }

    if (pio_read(&hw, REG_R_STATUS) & STATUS_BUSY) {
        fprintf(stderr, "[ERROR] LeNet is busy before loading\n");
        hw_close(&hw);
        return EXIT_FAILURE;
    }

    /* 2. Initialize the PS DMA channel. */
    dma_init(hw.dma);

    /* 3. Load weights, biases and the input image through ZDMA. */
    load_weights(&hw);
    load_biases(&hw);
    load_image(&hw);

    /* 4. Start the CNN through PIO. */
    puts("[PIO] Start LeNet5");
    pio_write(&hw, REG_W_START, 1u);

    /* 5. Wait for CNN completion. */
    if (wait_lenet_done(&hw) != 0) {
        hw_close(&hw);
        return EXIT_FAILURE;
    }

    /* 6. Read results through PIO and compare with the golden outputs. */
    read_result(&hw, &result);
    pass = compare_with_golden(&result, golden);

    hw_close(&hw);
    return pass ? EXIT_SUCCESS : EXIT_FAILURE;
}