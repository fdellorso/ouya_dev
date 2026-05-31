make -C linux O=../linux-build -j4 tegra_defconfig
make -C linux O=../linux-build -j4 menuconfig

CONFIG_ATAGS is not set
CONFIG_ARM_APPENDED_DTB=y
CONFIG_CMDLINE="android.kerneltype=normal androidboot.serialno=015d4906e123f807 video=tegrafb fbcon=map:0 gpt gpt_sector=15073279 console=tty1 console=ttyS0,115200n8 no_console_suspend=1 root=/dev/sda1 rootfstype=ext4 rw rootwait fsck.repair=yes"
AUTOFS4
IPTABLES
GPIO & PWM FAN

make -C linux O=../linux-build -j4 zImage modules dtbs
make -C linux O=../linux-build -j4 INSTALL_MOD_PATH=../linux-modules modules_install

cp linux-build/arch/arm/boot/zImage .
cat linux-build/arch/arm/boot/dts/tegra30-ouya.dtb >>./zImage

mkbootimg —-kernel zImage —-ramdisk /dev/null —-output zImage-515

sudo fuse-ext2 /dev/disk4s1 /Volumes/ouyahdd/ -o rw+
sudo cp -r ./linux-modules/lib /Volumes/ouyahdd/
sudo umount /Volumes/ouyahdd/

# tegraid=30.1.3.0.0 mem=1022M@2048M commchip_id=0 androidboot.serialno=015d4906e123f807 androidboot.commchip_id=0 video=tegrafb no_console_suspend=1 console=ttyS0,115200n8 console=tty2 debug_uartport=lsport,3 usbcore.old_scheme_first=1 lp0_vec=8192@0xbddf9000 tegra_fbmem=8302080@0xacc23000 core_edp_mv=1300 audio_codec=wm8903 board_info=c5b:b01:4:43:3 tegraboot=sdmmc gpt gpt_sector=15073279 android.kerneltype=normal root=/dev/sda1 root rw rootwait fbcon=map:1

# root tegraid=30.1.3.0.0 commchip_id=0 debug_uartport=lsport,3 lp0_vec=8192@0xbddf9000 tegra_fbmem=8302080@0xacc23000 core_edp_mv=1300 audio_codec=wm8903 board_info=c5b:b01:4:43:3 tegraboot=sdmmc
