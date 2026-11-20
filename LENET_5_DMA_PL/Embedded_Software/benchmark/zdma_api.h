#ifndef LENET5_ZDMA_API_H
#define LENET5_ZDMA_API_H
#include <linux/types.h>
#include <linux/ioctl.h>

/* User pointer to 16-bit values. The driver expands each to one 64-bit AXI word. */
struct lenet_write {
    __u64 values;
    __u32 word;
    __u32 count;
};
#define LENET_WRITE _IOW('L', 1, struct lenet_write)
#define LENET_BASE_GET _IOR('L', 2, __u64)
#endif
