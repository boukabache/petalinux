#include <configs/platform-auto.h>

/* sdio - ps7_sd_1 */
#define CONFIG_ZYNQ_SDHCI1 0xE0101000

#define CONFIG_ZYNQ_HISPD_BROKEN

#define CONFIG_SYS_BOOTM_LEN 0xF000000

#define DFU_ALT_INFO_RAM \
        "dfu_ram_info=" \
        "setenv dfu_alt_info " \
        "image.ub ram $netstart 0x1e00000\0" \
        "dfu_ram=run dfu_ram_info && dfu 0 ram 0\0" \
        "thor_ram=run dfu_ram_info && thordown 0 ram 0\0"

#define DFU_ALT_INFO_MMC \
        "dfu_mmc_info=" \
        "set dfu_alt_info " \
        "${kernel_image} fat 0 1\\\\;" \
        "dfu_mmc=run dfu_mmc_info && dfu 0 mmc 0\0" \
        "thor_mmc=run dfu_mmc_info && thordown 0 mmc 0\0"


/*Required for uartless designs */
#ifndef CONFIG_BAUDRATE
#define CONFIG_BAUDRATE 115200
#ifdef CONFIG_DEBUG_UART
#undef CONFIG_DEBUG_UART
#endif
#endif

/*Define CONFIG_ZYNQ_EEPROM here and its necessaries in u-boot menuconfig if you had EEPROM memory. */
#ifdef CONFIG_ZYNQ_EEPROM
#define CONFIG_SYS_I2C_EEPROM_ADDR_LEN         1
#define CONFIG_SYS_I2C_EEPROM_ADDR             0x54
#define CONFIG_SYS_EEPROM_PAGE_WRITE_BITS      4
#define CONFIG_SYS_EEPROM_PAGE_WRITE_DELAY_MS  5
#define CONFIG_SYS_EEPROM_SIZE                 1024 /* Bytes */
#define CONFIG_SYS_I2C_MUX_ADDR                0x74
#define CONFIG_SYS_I2C_MUX_EEPROM_SEL          0x4
#endif

/* Extra U-Boot Env settings */
#define CONFIG_EXTRA_ENV_SETTINGS \
   SERIAL_MULTI \ 
   CONSOLE_ARG \ 
   PSSERIAL0 \ 
    "progemmc=" \
        "if fatload mmc 0:1 0x20000000 image.ub; then " \
            "echo Copying Linux image.ub to eMMC ...; " \
            "echo Loading image.ub from SD card into memory ...; " \
            "fatload mmc 0:1 0x20000000 image.ub; " \
            "echo Copying image.ub from memory to eMMC partition ...; " \
            "fatwrite mmc 1:1 0x20000000 image.ub $filesize; " \
            "echo Copying Linux image.ub to eMMC Complete ...;" \
        "fi\0" \
   "nc=setenv stdout nc;setenv stdin nc;\0" \ 
   "ethaddr=00:0a:35:00:1e:53\0" \
   "importbootenv=echo \"Importing environment from SD ...\"; " \ 
      "env import -t ${loadbootenv_addr} $filesize\0" \ 
   "loadbootenv=load mmc $sdbootdev:$partid ${loadbootenv_addr} ${bootenv}\0" \ 
   "sd_uEnvtxt_existence_test=test -e mmc $sdbootdev:$partid /uEnv.txt\0" \ 
   "uenvboot=" \ 
        "if run sd_uEnvtxt_existence_test; then " \ 
            "run loadbootenv; " \  
            "echo Loaded environment from ${bootenv}; " \ 
            "run importbootenv; " \
        "fi\0" \
   "sdboot=echo boot Petalinux; run uenvboot ; mmcinfo && fatload mmc 0 ${netstart} ${kernel_img} && bootm \0" \ 
   "autoload=no\0" \ 
   "clobstart=0x10000000\0" \ 
   "netstart=0x10000000\0" \ 
   "dtbnetstart=0x11800000\0" \ 
   "loadaddr=0x10000000\0" \ 
   "bootsize=0x640000\0" \
   "bootstart=0x0\0" \
   "boot_img=BOOT.BIN\0" \ 
   "load_boot=tftpboot ${clobstart} ${boot_img}\0" \ 
   "update_boot=setenv img boot; setenv psize ${bootsize}; setenv installcmd \"install_boot\"; run load_boot test_img; setenv img; setenv psize; setenv installcmd\0" \
   "sd_update_boot=echo Updating boot from SD; mmcinfo && fatload mmc 0:1 ${clobstart} ${boot_img} && run install_boot\0" \
   "install_boot=sf probe 0 && sf erase ${bootstart} ${bootsize} && " \
      "sf write ${clobstart} ${bootstart} ${filesize}\0" \
   "bootenvsize=0x20000\0" \ 
   "bootenvstart=0x640000\0" \ 
   "eraseenv=sf probe 0 && sf erase ${bootenvstart} ${bootenvsize}\0" \ 
   "jffs2_img=rootfs.jffs2\0" \ 
   "load_jffs2=tftpboot ${clobstart} ${jffs2_img}\0" \ 
   "update_jffs2=setenv img jffs2; setenv psize ${jffs2size}; setenv installcmd \"install_jffs2\"; run load_jffs2 test_img; setenv img; setenv psize; setenv installcmd\0" \ 
   "sd_update_jffs2=echo Updating jffs2 from SD; mmcinfo && fatload mmc 0:1 ${clobstart} ${jffs2_img} && run install_jffs2\0" \ 
   "install_jffs2=sf probe 0 && sf erase ${jffs2start} ${jffs2size} && " \ 
      "sf write ${clobstart} ${jffs2start} ${filesize}\0" \ 
   "kernel_img=image.ub\0" \ 
   "load_kernel=tftpboot ${clobstart} ${kernel_img}\0" \ 
   "update_kernel=setenv img kernel; setenv psize ${kernelsize}; setenv installcmd \"install_kernel\"; run load_kernel ${installcmd}; setenv img; setenv psize; setenv installcmd\0" \ 
   "install_kernel=mmcinfo && fatwrite mmc 0 ${clobstart} ${kernel_img} ${filesize}\0" \ 
   "cp_kernel2ram=mmc dev 1 && fatload mmc 1 ${netstart} ${kernel_img}\0" \
   "dtb_img=system.dtb\0" \ 
   "load_dtb=tftpboot ${clobstart} ${dtb_img}\0" \ 
   "update_dtb=setenv img dtb; setenv psize ${dtbsize}; setenv installcmd \"install_dtb\"; run load_dtb test_img; setenv img; setenv psize; setenv installcmd\0" \ 
   "sd_update_dtb=echo Updating dtb from SD; mmcinfo && fatload mmc 0:1 ${clobstart} ${dtb_img} && run install_dtb\0" \ 
   "fault=echo ${img} image size is greater than allocated place - partition ${img} is NOT UPDATED\0" \ 
   "test_crc=if imi ${clobstart}; then run test_img; else echo ${img} Bad CRC - ${img} is NOT UPDATED; fi\0" \ 
   "test_img=setenv var \"if test ${filesize} -gt ${psize}\\; then run fault\\; else run ${installcmd}\\; fi\"; run var; setenv var\0" \ 
   "netboot=tftpboot ${netstart} ${kernel_img} && bootm\0" \ 
   "default_bootcmd=run progemmc; run uenvboot; run cp_kernel2ram && bootm ${netstart}\0" \ 
""
