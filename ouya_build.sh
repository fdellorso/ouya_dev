make -C linux O=../linux-build -j4 tegra_defconfig
make -C linux O=../linux-build -j4 menuconfig

CONFIG_ATAGS is not set
CONFIG_ARM_APPENDED_DTB=y
CONFIG_CMDLINE="android.kerneltype=normal androidboot.serialno=015d4906e123f807 video=tegrafb fbcon=map:0 gpt gpt_sector=15073279 console=tty1 console=ttyS0,115200n8 no_console_suspend=1 root=/dev/sda1 rootfstype=ext4 rw rootwait fsck.repair=yes"
AUTOFS4

make -C linux O=../linux-build -j4 zImage modules dtbs
make -C linux O=../linux-build -j4 INSTALL_MOD_PATH=../linux-modules modules_install

cp linux-build/arch/arm/boot/zImage .
cat linux-build/arch/arm/boot/dts/tegra30-ouya.dtb >>./zImage

mkbootimg —-kernel zImage —-ramdisk /dev/null —-output zImage-515

sudo fuse-ext2 /dev/disk4s1 /Volumes/ouyahdd/ -o rw+
sudo cp -r ./linux-modules/lib /Volumes/ouyahdd/
sudo umount /Volumes/ouyahdd/
