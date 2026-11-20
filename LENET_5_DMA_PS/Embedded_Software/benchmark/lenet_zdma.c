// SPDX-License-Identifier: GPL-2.0
/* PS FPD ZDMA client for Linux on KR260. One reserved channel per loaded module. */
#include <linux/module.h>
#include <linux/dmaengine.h>
#include <linux/dma-mapping.h>
#include <linux/platform_device.h>
#include <linux/of.h>
#include <linux/miscdevice.h>
#include <linux/fs.h>
#include <linux/uaccess.h>
#include <linux/completion.h>
#include <linux/mutex.h>
#include <linux/slab.h>
#include "zdma_api.h"

#define WORDS 512
#define WINDOW 0x400000 /* Includes every upload block, excludes output registers. */
static unsigned long long ip_base;
module_param(ip_base, ullong, 0444);
MODULE_PARM_DESC(ip_base,"Physical base of the LeNet PL IP from the implemented address map");
static struct dma_chan *channel;
static struct device *master;
static u64 *stage;
static dma_addr_t source, dest;
static DEFINE_MUTEX(lock);
static atomic_t opened = ATOMIC_INIT(0);
static DECLARE_COMPLETION(finished);
static u16 input[WORDS];

static bool gdma_filter(struct dma_chan *c, void *unused)
{
    struct device *dev = c->device->dev;
    struct resource *r;

    if (dev->bus != &platform_bus_type ||
        !of_device_is_compatible(dev->of_node,"xlnx,zynqmp-dma-1.0"))
        return false;
    r = platform_get_resource(to_platform_device(dev), IORESOURCE_MEM, 0);
    return r && r->start >= 0xfd4f0000 && r->start <= 0xfd560000 &&
           !(r->start & 0xffff);
}

static bool valid_range(u32 word, u32 count)
{
    static const struct { u32 addr, size; } ranges[] = {
        {0x10000,784},{0x20000,150},{0x30000,2400},{0x40000,30720},
        {0x50000,10080},{0x60000,840},{0x70000,6},{0x72000,16},
        {0x74000,120},{0x76000,84},{0x78000,10}
    };
    size_t i;

    if (!count || count > WORDS)
        return false;
    for (i = 0; i < ARRAY_SIZE(ranges); i++)
        if (word >= ranges[i].addr && count <= ranges[i].size &&
            word - ranges[i].addr <= ranges[i].size - count)
            return true;
    return false;
}

static void done(void *data)
{
    complete(data);
}

static int transfer(const struct lenet_write *w)
{
    u32 i;
    size_t bytes = w->count * sizeof(*stage);
    dma_addr_t target = dest + (u64)w->word * 8;
    struct dma_async_tx_descriptor *tx;
    dma_cookie_t cookie;

    if (!is_dma_copy_aligned(channel->device,source,target,bytes))
        return -EINVAL;
    if (copy_from_user(input,u64_to_user_ptr(w->values),w->count*sizeof(*input)))
        return -EFAULT;
    for (i = 0; i < w->count; i++)
        stage[i] = input[i];
    dma_wmb();
    reinit_completion(&finished);
    tx = dmaengine_prep_dma_memcpy(channel,target,source,bytes,
                                   DMA_PREP_INTERRUPT | DMA_CTRL_ACK);
    if (!tx)
        return -EIO;
    tx->callback = done;
    tx->callback_param = &finished;
    cookie = dmaengine_submit(tx);
    if (dma_submit_error(cookie))
        return cookie;
    dma_async_issue_pending(channel);
    if (!wait_for_completion_timeout(&finished,msecs_to_jiffies(2000))) {
        dmaengine_terminate_sync(channel);
        return -ETIMEDOUT;
    }
    if (dma_async_is_tx_complete(channel,cookie,NULL,NULL) != DMA_COMPLETE)
        return -EIO;
    return 0;
}

static long control(struct file *f, unsigned int cmd, unsigned long arg)
{
    struct lenet_write w;
    int ret;

    if (cmd == LENET_BASE_GET)
        return copy_to_user((void __user *)arg,&ip_base,sizeof(ip_base)) ? -EFAULT : 0;
    if (cmd != LENET_WRITE)
        return -ENOTTY;
    if (copy_from_user(&w,(void __user *)arg,sizeof(w)))
        return -EFAULT;
    if (!valid_range(w.word,w.count))
        return -EINVAL;
    mutex_lock(&lock);
    ret = transfer(&w);
    mutex_unlock(&lock);
    return ret;
}
static int claim(struct inode *ino, struct file *f)
{
    return atomic_cmpxchg(&opened,0,1) ? -EBUSY : 0;
}
static int release_file(struct inode *ino, struct file *f)
{
    atomic_set(&opened,0);
    return 0;
}
static const struct file_operations ops = {
    .owner=THIS_MODULE, .open=claim, .release=release_file, .unlocked_ioctl=control
};
static struct miscdevice node = {
    .minor=MISC_DYNAMIC_MINOR, .name="lenet_zdma", .fops=&ops, .mode=0600
};

static int __init setup(void)
{
    dma_cap_mask_t mask;
    int ret;

    if (!ip_base || (ip_base & 4095) || ip_base > U32_MAX - WINDOW)
        return -EINVAL;
    dma_cap_zero(mask);
    dma_cap_set(DMA_MEMCPY,mask);
    channel = dma_request_channel(mask,gdma_filter,NULL);
    if (!channel) {
        pr_err("lenet_zdma: no free ZynqMP FPD GDMA channel; check live DT and zynqmp_dma driver\n");
        return -ENODEV;
    }
    master = dmaengine_get_dma_device(channel);
    stage = dma_alloc_coherent(master,WORDS*sizeof(*stage),&source,GFP_KERNEL);
    if (!stage) {
        ret = -ENOMEM;
        goto free_channel;
    }
    dest = dma_map_resource(master,ip_base,WINDOW,DMA_FROM_DEVICE,0);
    if (dma_mapping_error(master,dest)) {
        ret = -EIO;
        goto free_stage;
    }
    ret = misc_register(&node);
    if (!ret) {
        pr_info("lenet_zdma: %s on %s, IP %llx\n",dma_chan_name(channel),
                dev_name(channel->device->dev),ip_base);
        return 0;
    }
    dma_unmap_resource(master,dest,WINDOW,DMA_FROM_DEVICE,0);
free_stage:
    dma_free_coherent(master,WORDS*sizeof(*stage),stage,source);
free_channel:
    dma_release_channel(channel);
    return ret;
}
static void __exit teardown(void)
{
    misc_deregister(&node);
    dmaengine_terminate_sync(channel);
    dma_unmap_resource(master,dest,WINDOW,DMA_FROM_DEVICE,0);
    dma_free_coherent(master,WORDS*sizeof(*stage),stage,source);
    dma_release_channel(channel);
}
module_init(setup);
module_exit(teardown);
MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("LeNet-5 upload benchmark via ZynqMP PS GDMA");
