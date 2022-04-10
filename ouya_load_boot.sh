adb kill-server

sleep 3

if adb devices | grep -w device; then
  adb -s 015d4906e123f807 reboot bootloader
else
  echo ouya not found
  fastboot reboot
  exit 1
fi

sleep 3

if fastboot devices | grep -w fastboot; then
  fastboot boot zImage-518
  # fastboot boot zImage-511 --cmdline 'tegraid=30.1.3.0.0 mem=1022M@2048M commchip_id=0 androidboot.serialno=015d4906e123f807 androidboot.commchip_id=0 video=tegrafb no_console_suspend=1 console=ttyS0,115200n8 console=tty2 debug_uartport=lsport,3 usbcore.old_scheme_first=1 lp0_vec=8192@0xbddf9000 tegra_fbmem=8302080@0xacc23000 core_edp_mv=1300 audio_codec=wm8903 board_info=c5b:b01:4:43:3 tegraboot=sdmmc gpt gpt_sector=15073279 android.kerneltype=normal root=/dev/sda4 root rw rootwait fbcon=map:1'
else
  echo ouya not found
  exit 1
fi

exit 0
