export LINUX_DIR			:= $(PWD)/linux
export KBUILD_DIR			:= $(PWD)/linux-build
export KERNEL_MODULES		:= $(PWD)/linux-modules
export KERNEL_DTBS			:= $(PWD)/linux-dtbs

export NPROCS:=1

export OS:=$(shell uname -s)
ifeq($(OS),Linux)
  NPROCS:=$(shell grep -c ^processor /proc/cpuinfo)
endif
ifeq($(OS),Darwin) # Assume Mac OS X
  NPROCS:=$(shell system_profiler SPHardwareDataType | awk '/Total Number of Cores/{print $5}{next;}')
endif

export CORES				:= -j$(NPROCS)


.PHONY: config 				configpatch			\
		menuconfig								\
		kernel				kernel_dtb			\
		kernel_bootimg					 		\
		clean_kernel 		reset_kernel		\

config:
	mkdir -p $(KBUILD_DIR)
	kernel-armv7 bash -c 'make -C $(LINUX_DIR) O=$(KBUILD_DIR) $(CORES) tegra_defconfig'


config_patch:
	# if ! patch -R -p0 -s -f --dry-run patch $(KBUILD_DIR)/.config kernel-patch/defconfig.patch; then \
	# 	patch $(KBUILD_DIR)/.config kernel-patch/defconfig.patch; \
	# fi


menuconfig:
	kernel-armv7 bash -c 'make -C $(LINUX_DIR) O=$(KBUILD_DIR) $(CORES) menuconfig'


kernel:
	mkdir -p $(KERNEL_MODULES)
	mkdir -p $(KERNEL_DTBS)
	kernel-armv7 bash -c 'make -C $(LINUX_DIR) O=$(KBUILD_DIR) $(CORES) zImage modules dtbs'
	kernel-armv7 bash -c 'make -C $(LINUX_DIR) O=$(KBUILD_DIR) $(CORES) modules_install dtbs_install INSTALL_MOD_PATH=$(KERNEL_MODULES) INSTALL_DTBS_PATH=$(KERNEL_DTBS)'


kernel_dtb:
	cp $(KBUILD_DIR)/arch/arm/boot/zImage .
	cat $(KERNEL_DTBS)/tegra30-ouya.dtb >>./zImage


kernel_bootimg:
	mkbootimg —-kernel zImage —-ramdisk /dev/null —-output zImage


clean_kernel:
	rm -rf $(KBUILD_DIR)
	rm -rf $(KERNEL_MODULES)
	rm -rf $(KERNEL_DTBS)


reset_kernel:
	cd $(LINUX_DIR); git reset --hard; git clean -fxd :/;
