export LINUX_DIR			:= linux
# export LINUX_DIR			:= kernel
export KBUILD_DIR			:= linux-build
export KERNEL_MODULES		:= linux-modules
export KERNEL_DTBS			:= linux-dtbs

export NPROCS:=8

export OS:=$(shell uname -s)
# ifeq($(OS),Linux)
#   NPROCS:=$(shell grep -c ^processor /proc/cpuinfo)
# endif
# ifeq($(OS),Darwin) # Assume Mac OS X
#   NPROCS:=$(shell system_profiler SPHardwareDataType | awk '/Total Number of Cores/{print $5}{next;}')
# endif

export CORES				:= -j$(NPROCS)
export ARCH					:= arm
export CROSS_COMPILE		:= arm-linux-gnueabihf-

.PHONY: config 				configpatch			\
		menuconfig								\
		kernel				kernel_dtb			\
		kernel_bootimg					 		\
		copy_lib						 		\
		clean_kernel 		reset_kernel		\

config:
	mkdir -p $(KBUILD_DIR)
# ./kernel-armv7 bash -c 'make -C $(LINUX_DIR) O=../$(KBUILD_DIR) $(CORES) tegra_defconfig'
	make -C $(LINUX_DIR) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) O=../$(KBUILD_DIR) $(CORES) tegra_defconfig



config_patch:
	mkdir -p $(KBUILD_DIR)
	# if ! patch -R -p0 -s -f --dry-run patch $(KBUILD_DIR)/.config kernel-patch/defconfig.patch; then \
	# 	patch $(KBUILD_DIR)/.config kernel-patch/defconfig.patch; \
	# fi


menuconfig:
	mkdir -p $(KBUILD_DIR)
# ./kernel-armv7 bash -c 'make -C $(LINUX_DIR) O=../$(KBUILD_DIR) $(CORES) menuconfig'
	make -C $(LINUX_DIR) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) O=../$(KBUILD_DIR) $(CORES) menuconfig



kernel:
	mkdir -p $(KERNEL_MODULES)
	mkdir -p $(KERNEL_DTBS)
# ./kernel-armv7 bash -c 'make -C $(LINUX_DIR) O=../$(KBUILD_DIR) $(CORES) zImage modules dtbs'
# ./kernel-armv7 bash -c 'make -C $(LINUX_DIR) O=../$(KBUILD_DIR) $(CORES) modules_install dtbs_install INSTALL_MOD_PATH=../$(KERNEL_MODULES) INSTALL_DTBS_PATH=../$(KERNEL_DTBS)'
	make -C $(LINUX_DIR) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) O=../$(KBUILD_DIR) $(CORES) zImage modules dtbs
	make -C $(LINUX_DIR) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) O=../$(KBUILD_DIR) $(CORES) modules_install dtbs_install INSTALL_MOD_PATH=../$(KERNEL_MODULES) INSTALL_DTBS_PATH=../$(KERNEL_DTBS)


kernel_dtb:
	cp $(KBUILD_DIR)/arch/arm/boot/zImage .
	cat $(KERNEL_DTBS)/tegra30-ouya.dtb >> ./zImage


kernel_bootimg:
	./mkbootimg/mkbootimg --kernel zImage --ramdisk /dev/null --output zImage-616


copy_lib:
	sudo mkdir -p /Volumes/ouyahdd
	sudo fuse-ext2 /dev/disk4s1 /Volumes/ouyahdd/ -o rw+
	sudo cp -RP ./linux-modules/lib /Volumes/ouyahdd/
	sudo umount /Volumes/ouyahdd/


clean_kernel:
	rm -rf $(KBUILD_DIR)
	rm -rf $(KERNEL_MODULES)
	rm -rf $(KERNEL_DTBS)


reset_kernel:
	cd $(LINUX_DIR); git reset --hard; git clean -fxd :/;
