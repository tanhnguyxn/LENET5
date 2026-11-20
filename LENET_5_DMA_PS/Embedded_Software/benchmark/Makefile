obj-m := lenet_zdma.o
KDIR ?= /lib/modules/$(shell uname -r)/build
.PHONY: module
module:
	$(MAKE) -C $(KDIR) M=$(CURDIR) modules
