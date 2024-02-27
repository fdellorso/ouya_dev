# TODO
# extract version from Makefile and use to name zImage and copy right LIB folder
# create FULL IPTABLE fragment
# test 6.6.0 kver
# learn to use dockcross

export LINUX_DIR			:= linux
# export LINUX_DIR			:= kernel
export KBUILD_DIR			:= linux-build
export KERNEL_MODULES		:= linux-modules
export KERNEL_DTBS			:= linux-dtbs
export OUYA_HDD_MOUNT		:= /mnt/linux
export OUYA_HDD_ID			:= 


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


export RULES_DIR      ?= ./rules
export PATCHES_DIR    ?= ./patches
export KERNEL_DIR     ?= $(LINUX_DIR)
export CONFIG_TARGET  ?= menuconfig
export ALL_TARGET     ?= tegra_defconfig


export MERGE_KCONFIG  := $(KERNEL_DIR)/scripts/kconfig/merge_config.sh
export DIFF_KCONFIG   := $(KERNEL_DIR)/scripts/diffconfig
export RULES          := $(wildcard $(RULES_DIR)/*)
export PATCHES        := $(wildcard $(PATCHES_DIR)/*)
export CONFIG         := $(KBUILD_DIR)/.config
export PATCHED_CONFIG := $(KBUILD_DIR)/.patched_config
export NEW_CONFIG     := $(KBUILD_DIR)/.new_config


export VERSION := $(shell cat $(LINUX_DIR)/Makefile | grep -m 1 "VERSION = " | cut -f 3 -d " ")
export PATCHLEVEL := $(shell cat $(LINUX_DIR)/Makefile | grep -m 1 "PATCHLEVEL = " | cut -f 3 -d " ")
export SUBLEVEL := $(shell cat $(LINUX_DIR)/Makefile | grep -m 1 "SUBLEVEL = " | cut -f 3 -d " ")


.PHONY: config 				config_patch		\
		new_config			diff_config			\
		menuconfig								\
		prepare				modules_prepare		\
		clean									\
		kernel				kernel_dtb			\
		kernel_bootimg					 		\
		copy_kernel			copy_lib			\
		clean_kernel 		reset_kernel		\


# ZFS
# linux -> make prepare
# sh ./autogen.sh
# export LINUX_DIR=/home/fdellorso/Develop/ouya_dev/linux
# export LINUX_DIR_OBJ=/home/fdellorso/Develop/ouya_dev/linux-build
# ./configure --enable-linux-builtin --with-linux=$LINUX_DIR --with-linux-obj=$LINUX_DIR_OBJ
# ./copy-builtin $LINUX_DIR_OBJ


config:
	mkdir -p $(KBUILD_DIR)
	./dockcross/kernel-armv7 bash -c 'make -C $(LINUX_DIR) O=../$(KBUILD_DIR) $(CORES) tegra_defconfig'
# make -C $(LINUX_DIR) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) O=../$(KBUILD_DIR) $(CORES) tegra_defconfig


config_patch:
# mkdir -p $(KBUILD_DIR)
# if ! patch -R -p0 -s -f --dry-run patch $(KBUILD_DIR)/.config linux-config/config.patch; then \
# 	patch $(KBUILD_DIR)/.config linux-config/config.patch; \
# fi
	KCONFIG_CONFIG=$(CONFIG) $(MERGE_KCONFIG) -m -r $(CONFIG) linux-config/fragment/docker.fragment
	KCONFIG_CONFIG=$(CONFIG) $(MERGE_KCONFIG) -m -r $(CONFIG) linux-config/fragment/iptables_qos.fragment
	KCONFIG_CONFIG=$(CONFIG) $(MERGE_KCONFIG) -m -r $(CONFIG) linux-config/fragment/notuner.fragment
	KCONFIG_CONFIG=$(CONFIG) $(MERGE_KCONFIG) -m -r $(CONFIG) linux-config/fragment/ouya.fragment
	KCONFIG_CONFIG=$(CONFIG) $(MERGE_KCONFIG) -m -r $(CONFIG) linux-config/fragment/usbserial.fragment


menuconfig:
	mkdir -p $(KBUILD_DIR)
	./dockcross/kernel-armv7 bash -c 'make -C $(LINUX_DIR) O=../$(KBUILD_DIR) $(CORES) menuconfig'
# make -C $(LINUX_DIR) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) O=../$(KBUILD_DIR) $(CORES) menuconfig


# https://github.com/miyuchina/kernel-config
diff_config:
	@[ -f "$(NEW_CONFIG)" ] && \
	    $(DIFF_KCONFIG) -m $(CONFIG) $(NEW_CONFIG)


new_config: $(CONFIG)
	[ -f "$(NEW_CONFIG)" ] || cp $(CONFIG) $(NEW_CONFIG)
	$(MAKE) -C $(KERNEL_DIR) \
	    KCONFIG_CONFIG=$(notdir $(NEW_CONFIG)) \
	    $(CONFIG_TARGET)


# $(CONFIG): $(PATCHED_CONFIG) $(RULES)
# 	KCONFIG_CONFIG=$@ $(MERGE_KCONFIG) -m -r $^
# 	$(MAKE) -C $(KERNEL_DIR) \
# 	    KCONFIG_CONFIG=$(notdir $@) \
# 	    KCONFIG_ALLCONFIG=$(notdir $@) \
# 	    $(ALL_TARGET)


# $(PATCHED_CONFIG): $(PATCHES)
# 	[ -z "$(PATCHES)" ] || \
# 	    git -C $(KERNEL_DIR) apply --verbose $(addprefix ../,$^)
# 	$(MAKE) -C $(KERNEL_DIR) KCONFIG_CONFIG=$(notdir $@) defconfig


prepare:
	mkdir -p $(KBUILD_DIR)
	./dockcross/kernel-armv7 bash -c 'make -C $(LINUX_DIR) O=../$(KBUILD_DIR) $(CORES) prepare'
# make -C $(LINUX_DIR) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) O=../$(KBUILD_DIR) $(CORES) prepare


modules_prepare:
	mkdir -p $(KBUILD_DIR)
	./dockcross/kernel-armv7 bash -c 'make -C $(LINUX_DIR) O=../$(KBUILD_DIR) $(CORES) modules_prepare'
# make -C $(LINUX_DIR) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) O=../$(KBUILD_DIR) $(CORES) modules_prepare


clean:
	mkdir -p $(KBUILD_DIR)
	./dockcross/kernel-armv7 bash -c 'make -C $(LINUX_DIR) O=../$(KBUILD_DIR) $(CORES) clean'
# make -C $(LINUX_DIR) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) O=../$(KBUILD_DIR) $(CORES) clean


kernel:
	mkdir -p $(KERNEL_MODULES)
	mkdir -p $(KERNEL_DTBS)
	./dockcross/kernel-armv7 bash -c 'make -C $(LINUX_DIR) O=../$(KBUILD_DIR) $(CORES) zImage modules dtbs'
	./dockcross/kernel-armv7 bash -c 'make -C $(LINUX_DIR) O=../$(KBUILD_DIR) $(CORES) modules_install dtbs_install INSTALL_MOD_PATH=../$(KERNEL_MODULES) INSTALL_DTBS_PATH=../$(KERNEL_DTBS)'
# make -C $(LINUX_DIR) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) O=../$(KBUILD_DIR) $(CORES) zImage modules dtbs
# make -C $(LINUX_DIR) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) O=../$(KBUILD_DIR) $(CORES) modules_install dtbs_install INSTALL_MOD_PATH=../$(KERNEL_MODULES) INSTALL_DTBS_PATH=../$(KERNEL_DTBS)


kernel_dtb:
	cp $(KBUILD_DIR)/arch/arm/boot/zImage ./zImage-$(VERSION)$(PATCHLEVEL)$(SUBLEVEL)
	cat $(KERNEL_DTBS)/tegra30-ouya.dtb >> ./zImage-$(VERSION)$(PATCHLEVEL)$(SUBLEVEL)


kernel_bootimg:
	./mkbootimg/mkbootimg --kernel zImage-$(VERSION)$(PATCHLEVEL)$(SUBLEVEL) --ramdisk /dev/null --output zImage


copy_kernel:
	rsync -ac zImage francescodellorso@macmini:/Volumes/Develop/ouya_dev


copy_lib:
# MACOS
# sudo mkdir -p /Volumes/ouyahdd
# sudo fuse-ext2 /dev/disk4s1 /Volumes/ouyahdd/ -o rw+
# sudo cp -RP ./linux-modules/lib /Volumes/ouyahdd/
# sudo umount /Volumes/ouyahdd/

# LINUX
# sudo mkdir -p $(OUYA_HDD_MOUNT)
# sudo mount /dev/disk/by-uuid/a5af45bc-bed3-4c69-8313-d407d75bc101 $(OUYA_HDD_MOUNT)
# sudo cp -RP $(KERNEL_MODULES)/lib/modules/* $(OUYA_HDD_MOUNT)/lib/modules/
# sudo umount $(OUYA_HDD_MOUNT)
	rsync -ac $(KERNEL_MODULES)/lib/modules/* root@alarm.local:/lib/modules


clean_kernel:
	rm -rf $(KBUILD_DIR)
	rm -rf $(KERNEL_MODULES)
	rm -rf $(KERNEL_DTBS)
	rm -rf ./zImage*


reset_kernel:
	cd $(LINUX_DIR); git reset --hard; git clean -fxd :/;
