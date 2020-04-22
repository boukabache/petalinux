# ----------------------------------------------------------------------------
#
#        ** **        **          **  ****      **  **********  ********** ®
#       **   **        **        **   ** **     **  **              **
#      **     **        **      **    **  **    **  **              **
#     **       **        **    **     **   **   **  *********       **
#    **         **        **  **      **    **  **  **              **
#   **           **        ****       **     ** **  **              **
#  **  .........  **        **        **      ****  **********      **
#     ...........
#                                     Reach Further™-
#
# ----------------------------------------------------------------------------
# 
#  This design is the property of Avnet.  Publication of this
#  design is not authorized without written consent from Avnet.
# 
#  Please direct any questions to the UltraZed community support forum:
#     http://www.ultrazed.org/forum
# 
#  Product information is available at:
#     http://www.ultrazed.org/product/ultrazed-EG
# 
#  Disclaimer:
#     Avnet, Inc. makes no warranty for the use of this code or design.
#     This code is provided  "As Is". Avnet, Inc assumes no responsibility for
#     any errors, which may appear in this code, nor does it make a commitment
#     to update the information contained herein. Avnet, Inc specifically
#     disclaims any implied warranties of fitness for a particular purpose.
#                      Copyright(c) 2017 Avnet, Inc.
#                              All rights reserved.
# 
# ----------------------------------------------------------------------------
# 
#  Create Date:         Aug 25, 2017
#  Design Name:         Avnet UltraZed SOM PetaLinux BSP Generator
#  Module Name:         make_uz_petalinux_bsp.tcl
#  Project Name:        Avnet UltraZed SOM  PetaLinux BSP Generator
#  Target Devices:      Xilinx Zynq Ultrascale MPSoC
#  Hardware Boards:     UltraZed-EV + EV Carrier
#                       UltraZed-EG + I/O Carrier
#                       UltraZed-EG + PCIe Carrier
# 
#  Tool versions:       Xilinx Vivado 2017.2
# 
#  Description:         Build Script for UZ PetaLinux BSP HW Platform
# 
#  Dependencies:        None
#
#  Revision:            Aug 25, 2017: 1.00 Initial version
#                       Jan 30, 2018: 1.01 Added build for UltraZed-EV
#                       Mar 22, 2018: 1.02 Updated for PetaLinux 2017.4
#                       Aug 11, 2018: 1.03 Updated for PetaLinux 2018.2
#                       Oct 31, 2019: 1.04 Updated for PetaLinux 2019.1
#                       Feb 17, 2020: 1.05 Updated for PetaLinux 2019.2
# 
# ----------------------------------------------------------------------------

#!/bin/bash

# Set global variables here.
# Specify images to create
# Light Green (Avnet color)
LGRN='\033[1;32m'
# Red 
LRED='\033[1;31m'
# BLUE
LBLU='\033[1;34m'
# Yellow
LYEL='\033[1;33m'
# No Color
NC='\033[0m' 

BUILD_UZ3EG_IOCC=no
BUILD_UZ3EG_PCIEC=no
BUILD_UZ7EV_EVCC=no

  if [ "$1" == "UZ3EG_IOCC" ]
    then
      BUILD_UZ3EG_IOCC=yes
  elif [ "$1" == "UZ3EG_PCIEC" ]
    then
      BUILD_UZ3EG_PCIEC=yes
  elif [ "$1" == "UZ7EV_EVCC" ]
    then
      BUILD_UZ7EV_EVCC=yes
  elif [ "$1" == "" ]
	then
      echo ""
      echo ""
      echo -e ${LGRN}"+*******************************************************************+"
      echo -e ${LGRN}"*${LRED} This make script defaults to building NO project, use arguments:  ${LGRN}*"
      echo -e ${LGRN}"* UZ3EG_IOCC  ${LBLU}- builds UltraZed-EG with IO Carrier Card             ${LGRN}*"
      echo -e ${LGRN}"* UZ3EG_PCIEC ${LBLU}- builds UltraZed-EG with PCIe Carrier Card           ${LGRN}*"
      echo -e ${LGRN}"* UZ7EV_EVCC  ${LBLU}- builds UltraZed-EV with Carrier Card                ${LGRN}*"
      echo -e        "*${NC} Example: ${LYEL}./make_uz_petalinux_bsp.sh UZ7EV_EVCC                    ${LGRN}*"
      echo -e ${LGRN}"*${NC}     will produce the UltraZed-EV with Original Carrier Card       ${LGRN}*"
      echo -e ${LGRN}"+*******************************************************************+${NC}"
      echo ""
      echo ""
      exit 1
  fi

APP_PETALINUX_INSTALL_PATH=/tools/petalinux-v2019.2-final
APP_VIVADO_INSTALL_PATH=/tools/Xilinx/Vivado/2019.2
PLNX_VER=2019_2
BUILD_BOOT_QSPI_OPTION=no
BUILD_BOOT_EMMC_OPTION=no
BUILD_BOOT_EMMC_NO_BIT_OPTION=no
BUILD_BOOT_SD_OPTION=yes
BUILD_BOOT_SD_OOB_OPTION=no
BUILD_BOOT_SD_NO_BIT_OPTION=no

FSBL_PROJECT_NAME=zynqmp_fsbl
HDL_HARDWARE_NAME=uz_petalinux_hw
HDL_PROJECT_NAME=uz_petalinux
HDL_PROJECTS_FOLDER=../../hdl/Projects
HDL_SCRIPTS_FOLDER=../../hdl/Scripts
PETALINUX_APPS_FOLDER=../../petalinux/apps
PETALINUX_CONFIGS_FOLDER=../../petalinux/configs
PETALINUX_PROJECTS_FOLDER=../../petalinux/projects
PETALINUX_SCRIPTS_FOLDER=../../petalinux/scripts
START_FOLDER=`pwd`
TFTP_HOST_FOLDER=/tftpboot

DEBUG=no

QSPI_KERNEL_START=0x13A0000

PLNX_BUILD_SUCCESS=-1

source_tools_settings ()
{
  # Source the tools settings scripts so that both Vivado and PetaLinux can 
  # be used throughout this build script.
  source ${APP_VIVADO_INSTALL_PATH}/settings64.sh
  source ${APP_PETALINUX_INSTALL_PATH}/settings.sh
}

# This function checks to see if any board specific device-tree is available 
# and, if so, installs it into the meta-user BSP recipes folder.
petalinux_project_configure_devicetree ()
{
  # Check to see if a device (usually related to the SOM) specific system-user
  # devicetree source file is available.  According to PetaLinux methodology,
  # the system-user.dtsi file is where all of the non-autogenerated devicetree
  # information is supposed to be included.  The benefit of using this 
  # approach over modifying system-conf.dtsi is that the petalinux-config tool
  # is designed to leave system-user.dtsi untouched in case you need to go 
  # back and configure your PetaLinux project further after this bulid 
  # automation has been applied.
  #
  # If available, overwrite the board specific top level devicetree source 
  # with the revision controlled source files.
  if [ -f ${START_FOLDER}/${PETALINUX_CONFIGS_FOLDER}/device-tree/system-user.dtsi.${HDL_BOARD_NAME} ]
    then
    echo " "
    echo "Overwriting system-user level devicetree source include file..."
    echo " "
    cp -rf ${START_FOLDER}/${PETALINUX_CONFIGS_FOLDER}/device-tree/system-user.dtsi.${HDL_BOARD_NAME} \
    ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/project-spec/meta-user/recipes-bsp/device-tree/files/system-user.dtsi
  else
    echo " "
    echo "WARNING: No board specific devicetree file found, "
    echo "PetaLinux devicetree config is not touched for this build ..."
    echo " "
  fi
}

# This function checks to see if any user configuration is available for the
# kernel and, if so, sets up the meta-user kernel recipes folder and installs
# the user kernel configuration into that folder.
petalinux_project_configure_kernel ()
{
  # Check to see if a device (usually related to the SOM or reference design) 
  # specific kernel user configuration file is available.  
  #
  # If available, copy the kernel user configuration file to the meta-user
  # kernel recipes folder.
  if [ -f ${START_FOLDER}/${PETALINUX_CONFIGS_FOLDER}/kernel/user.cfg.${HDL_BOARD_NAME} ]
    then

    # Create the meta-user kernel recipes folder structure if it does not 
    # already exist (for a new PetaLinux project, it usually doesn't).
    if [ ! -d ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/project-spec/meta-user/recipes-kernel ]
      then
      mkdir ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/project-spec/meta-user/recipes-kernel
    fi
    if [ ! -d ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/project-spec/meta-user/recipes-kernel/linux ]
      then
      mkdir ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/project-spec/meta-user/recipes-kernel/linux
    fi
    if [ ! -d ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/project-spec/meta-user/recipes-kernel/linux/linux-xlnx ]
      then
      mkdir ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/project-spec/meta-user/recipes-kernel/linux/linux-xlnx
    fi

    # Copy the kernel user config over to the meta-user kernel recipe folder.
    echo " "
    echo "Overwriting kernel user configuration file..."
    echo " "
    cp -rf ${START_FOLDER}/${PETALINUX_CONFIGS_FOLDER}/kernel/user.cfg.${HDL_BOARD_NAME} \
    ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/project-spec/meta-user/recipes-kernel/linux/linux-xlnx/user_${HDL_BOARD_NAME}.cfg
    
    # Create the kernel user config .bbappend file if it does not already exist.
    if [ ! -f ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/project-spec/meta-user/recipes-kernel/linux/linux-xlnx_%.bbappend ]
      then
      echo "SRC_URI += \"file://user_${HDL_BOARD_NAME}.cfg\"" > ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/project-spec/meta-user/recipes-kernel/linux/linux-xlnx_%.bbappend
      echo "" >> ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/project-spec/meta-user/recipes-kernel/linux/linux-xlnx_%.bbappend
      echo "FILESEXTRAPATHS_prepend := \"\${THISDIR}/\${PN}:\"" >> ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/project-spec/meta-user/recipes-kernel/linux/linux-xlnx_%.bbappend
    fi 
  else
    echo " "
    echo "WARNING: No board specific kernel user configuration files found, "
    echo "PetaLinux kernel user config recipe is not touched for this build ..."
    echo " "
  fi
}

# This function checks to see if any board specific configuration is available
# for the rootfs and, if so, installs the rootfs configuration into the 
# PetaLinux project configs folder.
petalinux_project_configure_rootfs ()
{
  # Check to see if a device (usually related to the SOM or reference design) 
  # specific rootfs configuration file is available.  
  #
  # If available, overwrite the board specific rootfs configuration file with
  # the revision controlled config file.
  if [ -f ${START_FOLDER}/${PETALINUX_CONFIGS_FOLDER}/rootfs/config.${PETALINUX_ROOTFS_NAME} ]
    then
    echo " "
    echo "Overwriting rootfs configuration file..."
    echo " "
    cp -rf ${START_FOLDER}/${PETALINUX_CONFIGS_FOLDER}/rootfs/config.${PETALINUX_ROOTFS_NAME} \
    ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/project-spec/configs/rootfs_config
  else
    echo " "
    echo "WARNING: No board specific rootfs configuration files found, "
    echo "PetaLinux rootfs config is not touched for this build ..."
    echo " "
  fi

  if [ -d ${START_FOLDER}/${PETALINUX_CONFIGS_FOLDER}/meta-user/${PETALINUX_ROOTFS_NAME} ]
    then
    # Copy the meta-user rootfs folder to the PetaLinux project.
    echo " "
    echo "Adding custom rootfs ..."
    echo " "
    cp -rf ${START_FOLDER}/${PETALINUX_CONFIGS_FOLDER}/meta-user/${PETALINUX_ROOTFS_NAME}/* \
    ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/project-spec/meta-user/.
    # If the meta-user folder does not exist, then look for a bbappend file
    # Not every PetaLinux scripted build will have a custom rootfs with user applications, etc. and will instead 
    # use a bbappend file to specify PetaLinux-supplied applications
  elif [ -f ${START_FOLDER}/${PETALINUX_CONFIGS_FOLDER}/rootfs/bbappend.${PETALINUX_ROOTFS_NAME} ]
    then
    echo " "
    echo "Overwriting rootfs bbappend file..."
    echo " "
    cp -rf ${START_FOLDER}/${PETALINUX_CONFIGS_FOLDER}/rootfs/user-rootfsconfig.${PETALINUX_ROOTFS_NAME} \
    ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/project-spec/meta-user/conf/user-rootfsconfig
  else
    echo " "
    echo "WARNING: No custom rootfs found and no user-rootfsconfig file found, "
    echo "PetaLinux rootfs is not touched for this build ..."
    echo " "
  fi
}

petalinux_project_set_sstate_paths ()
{
  # Add the following paths to the end of ${CONF_FILE}
  # If the sstate cache has been downloaded and extracted into the PetaLinux
  # install folder this will significantly accelerate the build time
  # For more information see Xilinx AR #71240
  # https://www.xilinx.com/support/answers/71240.html
  
  PRJ_CFG_FILE=./project-spec/configs/config
  CONF_FILE=./project-spec/meta-user/conf/petalinuxbsp.conf
  
  CACHE_DOWNLOADS=downloads_${PETALINUX_VER}/downloads
  CACHE_AARCH64=sstate_aarch64_${PETALINUX_VER}/aarch64

  if [ -d ${PETALINUX}/${CACHE_DOWNLOADS} ]
  then
    echo " "
    echo "Appending sstate cache paths to ${CONF_FILE}..."
    echo " "

    echo "PREMIRRORS_prepend = \" git://.*/.* file://${PETALINUX}/${CACHE_DOWNLOADS} \\n \\" >> ${CONF_FILE}
    echo "ftp://.*/.* file://${PETALINUX}/${CACHE_DOWNLOADS} \\n \\" >> ${CONF_FILE}
    echo "http://.*/.* file://${PETALINUX}/${CACHE_DOWNLOADS} \\n \\" >> ${CONF_FILE}
    echo "https://.*/.* file://${PETALINUX}/${CACHE_DOWNLOADS} \\n\"" >> ${CONF_FILE}
  else
    echo " "
    echo "NOTE: sstate cache files not installed in ${PETALINUX} "
    echo "Not appending ${CONF_FILE} with sstate cache paths..."
    echo " "
  fi

  if [ -d ${PETALINUX}/${CACHE_AARCH64} ]
  then
    echo " "
    echo "Setting local sstate cache paths in project config file..."
    echo " "

    sed -i 's,http://petalinux.xilinx.com/sswreleases/rel-v${PETALINUX_VER%%.*}/downloads,file://'"${PETALINUX}"'/'"${CACHE_DOWNLOADS}"',g' ${PRJ_CFG_FILE}
    sed -i 's!CONFIG_YOCTO_LOCAL_SSTATE_FEEDS_URL=""!CONFIG_YOCTO_LOCAL_SSTATE_FEEDS_URL="'"${PETALINUX}"'/'"${CACHE_AARCH64}"'"!g' ${PRJ_CFG_FILE}
  else
    echo " "
    echo "NOTE: sstate cache files not installed in ${PETALINUX} "
    echo "Not setting local sstate cache paths in project config file..."
    echo " "
  fi

  # DEBUG
  if [ "$DEBUG" == "yes" ];
  then
    echo "Verify sstate cache paths have been added to ${CONF_FILE} and ${PRJ_CFG_FILE}"
    #read -p "Press ENTER to continue" 
    read -t 10 -p "Pause here for 10 seconds"
    echo " "
  fi
}

petalinux_project_restore_boot_config ()
{
  # Restore original PetaLinux project config. Don't forget that the
  # petalinux_project_save_boot_config () should have been called at some
  # point before this function gets called, otherwise there probably is
  # nothing there to restore.
  echo " "
  echo "Restoring original PetaLinux project config ..."
  echo " "
  cd ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/project-spec/configs/
  cp config.orig config
  cd ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}

  # Restore original U-Boot top level configuration.
  echo " "
  echo "Restoring original U-Boot top level configuration..."
  echo " "
  cd ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/project-spec/meta-user/recipes-bsp/u-boot/files/
  cp platform-top.h.orig platform-top.h
  cd ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}
}

petalinux_project_save_boot_config ()
{
  # Save original PetaLinux project config.
  echo " "
  echo "Saving original PetaLinux project config ..."
  echo " "
  cd ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/project-spec/configs/
  cp config config.orig
  cd ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}

  # Save original U-Boot top level configuration.
  echo " "
  echo "Saving original U-Boot top level configuration..."
  echo " "
  cd ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/project-spec/meta-user/recipes-bsp/u-boot/files/
  cp platform-top.h platform-top.h.orig
  cd ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}
}

petalinux_project_set_boot_config_qspi ()
{ 
  # Change PetaLinux project config to boot from QSPI.
  echo " "
  echo "Patching project config for QSPI boot support..."
  echo " "
  cd ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/project-spec/configs
  patch < ${START_FOLDER}/${PETALINUX_CONFIGS_FOLDER}/project/config.qspi_boot.patch
  cd ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}
  
  # Apply the meta-user level BSP platform-top.h file to establish a baseline
  # override for anything that was directly generated by petalinux-config by
  # overwriting the file found in the following folder with the board specific
  # revision controlled version:
  #  
  # project-spec/meta-user/recipes-bsp/u-boot/files/platform-top.h
  echo " "
  echo "Overriding meta-user BSP platform-top.h to add QSPI boot support in U-Boot ..."
  echo " "
  cd ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/project-spec/meta-user/recipes-bsp/u-boot/files/
  cp -rf ${START_FOLDER}/${PETALINUX_CONFIGS_FOLDER}/u-boot/platform-top.h.uz_qspi_boot ./platform-top.h
  cd ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}
}

petalinux_project_set_boot_config_emmc ()
{ 
  # Change PetaLinux project config to boot from eMMC either indirectly (via FSBL and u-boot in QSPI) or directly
  echo " "
  echo "Patching project config for eMMC boot support..."
  echo " "
  cd ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/project-spec/configs
  patch < ${START_FOLDER}/${PETALINUX_CONFIGS_FOLDER}/project/config.uz_emmc_boot.patch
  cd ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}

  # Add support for QSPI + eMMC boot to U-Boot environment configuration.
  echo " "
  echo "Applying patch to add eMMC indirect (QSPI + eMMC) boot support in U-Boot ..."
  echo " "
  cd ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/project-spec/meta-user/recipes-bsp/u-boot/files/
  cp -rf ${START_FOLDER}/${PETALINUX_CONFIGS_FOLDER}/u-boot/platform-top.h.uz_emmc_boot ./platform-top.h
  cd ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}
}

petalinux_project_set_boot_config_emmc_no_bit ()
{ 
  # Change PetaLinux project config to boot from eMMC (via QSPI).
  echo " "
  echo "Patching project config for eMMC boot support..."
  echo " "
  cd ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/project-spec/configs
  patch < ${START_FOLDER}/${PETALINUX_CONFIGS_FOLDER}/project/config.uz_emmc_boot.patch
  cd ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}

  # Add support for eMMC commands to U-Boot top level configuration which
  # allows for bistream to be loaded from eMMC instead of BOOT.BIN in QSPI
  # flash.
  echo " "
  echo "Applying patch to add eMMC bitstream load support in U-Boot ..."
  echo " "
  cd ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/project-spec/meta-user/recipes-bsp/u-boot/files/
  cp -rf ${START_FOLDER}/${PETALINUX_CONFIGS_FOLDER}/u-boot/platform-top.h.uz_emmc_boot_no_bit ./platform-top.h
  cd ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}
}

petalinux_project_set_boot_config_sd_no_bit ()
{ 
  # Add support for SD commands to U-Boot top level configuration which
  # allows for bistream to be loaded from SD file instead of the BOOT.BIN 
  # container file.
  echo " "
  echo "Applying patch to add SD bitstream load support in U-Boot ..."
  echo " "
  cd ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/project-spec/meta-user/recipes-bsp/u-boot/files/
  cp -rf ${START_FOLDER}/${PETALINUX_CONFIGS_FOLDER}/u-boot/platform-top.h.uz_sd_boot_no_bit ./platform-top.h
  cd ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}
}

# This function must add any patches or files that are needed to support 
# booting from SD card.  This usually invovles manipulation of U-Boot 
# commands within environment variables in order to force the Linux Kernel,
# devicetree, and RAMdisk rootfs (image.ub) to be loaded from the SD card 
# FAT32 filesystem.
petalinux_project_set_boot_config_sd ()
{ 
  # Apply the meta-user level BSP platform-top.h file to establish a baseline
  # override for anything that was directly generated by petalinux-config by
  # overwitting the file found in the following folder with the board specific
  # revision controlled version:
  #  
  # project-spec/meta-user/recipes-bsp/u-boot/files/platform-top.h
  echo " "
  echo "Overriding meta-user BSP platform-top.h to add SD boot support in U-Boot ..."
  echo " "
  cd ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/project-spec/meta-user/recipes-bsp/u-boot/files/
  cp -rf ${START_FOLDER}/${PETALINUX_CONFIGS_FOLDER}/u-boot/platform-top.h.uz_sd_boot ./platform-top.h
  cd ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}

  # Add the bsp.cfg file to the bbappend file for the u-boot build recipe
  echo "SRC_URI += \"file://bsp.cfg\"" >> ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/project-spec/meta-user/recipes-bsp/u-boot/u-boot-xlnx_%.bbappend

  cd ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}
}

create_petalinux_bsp ()
{ 
  # This function is responsible for creating a PetaLinux BSP around the
  # hardware platform specificed in HDL_PROJECT_NAME variable and build
  # the PetaLinux project within the folder specified by the 
  # PETALINUX_PROJECT_NAME variable.
  #
  # When complete, the BSP should boot from SD card by default.

  # Check to see if the PetaLinux projects folder even exists because when
  # you clone the source tree from Avnet Github, the projects folder is not
  # part of that tree.
  if [ ! -d ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER} ]; then
    # Create the PetaLinux projects folder.
    mkdir ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}
  fi

  # Change to PetaLinux projects folder.
  cd ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}

  # Create the PetaLinux project.
  petalinux-create --type project --template zynqMP --name ${PETALINUX_PROJECT_NAME} --force

  # Create the hardware definition folder.
  mkdir -p ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/hw_platform

  # Import the hardware definition files and hardware platform bitstream from
  # implemented system products folder.
  cd ${START_FOLDER}/${HDL_PROJECTS_FOLDER}

  echo " "
  echo "Importing hardware definition ${HDL_BOARD_NAME}.xsa from HDL project folder ..."
  echo " "

#TC  cp -f ${HDL_PROJECT_NAME}/${HDL_BOARD_NAME}_${PLNX_VER}/${HDL_PROJECT_NAME}.runs/impl_1/${HDL_PROJECT_NAME}_wrapper.sysdef \
#TC  ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/hw_platform/${HDL_HARDWARE_NAME}.hdf

  cp -f ${HDL_PROJECT_NAME}/${HDL_BOARD_NAME}_${PLNX_VER}/${HDL_BOARD_NAME}.xsa \
  ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/hw_platform/.

  echo " "
  echo "Importing hardware bitstream ${HDL_BOARD_NAME}_wrapper.bit from impl_1 folder ..."
  echo " "

#TC  cp -f ${HDL_PROJECT_NAME}/${HDL_BOARD_NAME}_${PLNX_VER}/${HDL_PROJECT_NAME}.runs/impl_1/${HDL_PROJECT_NAME}_wrapper.bit \
#TC  ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/hw_platform/system_wrapper.bit

  cp -f ${HDL_PROJECT_NAME}/${HDL_BOARD_NAME}_${PLNX_VER}/${HDL_BOARD_NAME}.runs/impl_1/${HDL_BOARD_NAME}_wrapper.bit \
  ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/hw_platform/system_wrapper.bit

  # Change directories to the hardware definition folder for the PetaLinux
  # project, at this point the .hdf file must be located in this folder 
  # for the petalinux-config step to be successful.
  cd ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}

  # Import the hardware description into the PetaLinux project.
  petalinux-config --silentconfig --get-hw-description=./hw_platform/ -p ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}
 
  # DEBUG
  if [ "$DEBUG" == "yes" ];
  then
    echo "Pause here to check for any messages about importing the hardware platform."
    #read -p "Press ENTER to continue" 
    read -t 10 -p "Pause here for 10 seconds"
    echo " "
  fi

  # Overwrite the PetaLinux project config with some sort of revision 
  # controlled source file.
  # 
  # If a patch is available, then the patch is preferred to be used since you
  # won't unintentionally affect as many pieces of the project configuration.
  #
  # If a patch is not available, but an entire board specific configuration is 
  # available, then that has second preference but you can wipe out some
  # project configuration attributes this way.
  #
  # If neither of those are present, use the generic one by default.
  if [ -f ${START_FOLDER}/${PETALINUX_CONFIGS_FOLDER}/project/config.${HDL_BOARD_NAME}.patch ] 
    then
    echo " "
    echo "Patching PetaLinux project config ..."
    echo " "
    cd ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/project-spec/configs/
    patch < ${START_FOLDER}/${PETALINUX_CONFIGS_FOLDER}/project/config.${HDL_BOARD_NAME}.patch
    cd ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}
  # DEBUG
  if [ "$DEBUG" == "yes" ];
  then
    echo "Pause here to check for any messages about importing the hardware platform."
    #read -p "Press ENTER to continue" 
    read -t 10 -p "Pause here for 10 seconds"
    echo " "
  fi

  elif [ -f ${START_FOLDER}/${PETALINUX_CONFIGS_FOLDER}/project/config.${HDL_BOARD_NAME} ] 
    then
    echo " "
    echo "Overwriting PetaLinux project config ..."
    echo " "
    cp -rf ${START_FOLDER}/${PETALINUX_CONFIGS_FOLDER}/project/config.${HDL_BOARD_NAME} \
    ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/project-spec/configs/config
  elif [ -f ${START_FOLDER}/${PETALINUX_CONFIGS_FOLDER}/project/config.generic ]
    then
    echo " "
    echo "WARNING: Using generic PetaLinux project config ..."
    echo " "
    cp -rf ${START_FOLDER}/${PETALINUX_CONFIGS_FOLDER}/project/config.generic \
    ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/project-spec/configs/config    
  else
    echo " "
    echo "WARNING: No board specific PetaLinux project configuration files found, "
    echo "PetaLinux project config is not touched for this build ..."
    echo " "
  fi

  # DEBUG
  if [ "$DEBUG" == "yes" ];
  then
    echo "Compare project-spec/configs/config file to ${PETALINUX_CONFIGS_FOLDER}/project/config.${PETALINUX_ROOTFS_NAME}.patch file"
    #read -p "Press ENTER to continue" 
    read -t 10 -p "Pause here for 10 seconds"
    echo " "
  fi  

  # Configure the device-tree.
  petalinux_project_configure_devicetree

  # Configure the root file system.
  petalinux_project_configure_rootfs

  # Configure the kernel.
  petalinux_project_configure_kernel

  # Add sstate cache paths to the project config and petalinuxbsp.conf files.
  petalinux_project_set_sstate_paths

  # Prepare to modify project configurations.
  petalinux_project_save_boot_config

  # Do an initial project clean
  petalinux-build -x mrproper

  # DEBUG
  if [ "$DEBUG" == "yes" ];
  then
    echo "Pause here to check for any messages about importing the hardware platform."
    #read -p "Press ENTER to continue" 
    read -t 10 -p "Pause here for 10 seconds"
    echo " "
  fi

  # If the QSPI boot option is set, then perform the steps needed to build 
  # BOOT.BIN for booting from QSPI.
  if [ "$BUILD_BOOT_QSPI_OPTION" == "yes" ]
  then
    # Restore project configurations and wipe out any changes made for special boot options.
    petalinux_project_restore_boot_config

    # Modify the project configuration for QSPI boot.
    petalinux_project_set_boot_config_qspi

    # DEBUG
    if [ "$DEBUG" == "yes" ];
    then
      echo "Stop here and go check the platform-top.h file and make sure it is set for QSPI boot"
      #read -p "Press ENTER to continue."
      read -t 10 -p "Pause here for 10 seconds"
      echo " "
    fi

    PLNX_BUILD_SUCCESS=-1

    echo "Entering PetaLinux build loop.  Stay here until Linux image is built successfully"
    while [ $PLNX_BUILD_SUCCESS -ne 0 ];
    do
      # Make sure that intermediary files get cleaned up.  This will also force
      # the rootfs to get rebuilt and generate a new image.ub file.
      petalinux-build -x distclean

      # Build PetaLinux project.
      petalinux-build 
      
      PLNX_BUILD_SUCCESS=$?
    done

    # Create QSPI boot image.  The kernel "--offset" must match the "kernelstart="  defined in the u-boot platform-top.h source file.
    petalinux-package --boot --fsbl images/linux/${FSBL_PROJECT_NAME}.elf --fpga ./images/linux/system.bit --uboot --kernel --offset ${QSPI_KERNEL_START} --force

    # Copy the boot.bin file and name the new file BOOT_QSPI.bin
    cp ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/images/linux/BOOT.BIN \
    ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/BOOT_QSPI.bin

    # Copy the u-boot.elf file and name the new file u-boot_QSPI.elf
    cp ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/images/linux/u-boot.elf \
    ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/u-boot_QSPI.elf

    # Create script to program the QSPI Flash
    echo "#!/bin/sh" > program_boot_qspi.sh
    echo "program_flash -f ./BOOT_QSPI.bin -offset 0 -flash_type qspi_dual_parallel -fsbl ./images/linux/${FSBL_PROJECT_NAME}.elf"  >> program_boot_qspi.sh
    echo "program_flash -f ./images/linux/image.ub -offset ${QSPI_KERNEL_START} -flash_type qspi_dual_parallel -fsbl ./images/linux/${FSBL_PROJECT_NAME}.elf"   >> program_boot_qspi.sh
    chmod 777 ./program_boot_qspi.sh
  fi

  # If the EMMC boot option is set, then perform the steps needed to build 
  # BOOT.BIN for booting from QSPI + eMMC.
  if [ "$BUILD_BOOT_EMMC_OPTION" == "yes" ]
  then
    # Restore project configurations and wipe out any changes made for special boot options.
    petalinux_project_restore_boot_config

    # Modify the project configuration for EMMC boot.
    petalinux_project_set_boot_config_emmc

    # DEBUG
    if [ "$DEBUG" == "yes" ];
    then
      echo "Stop here and go check the platform-top.h file and make sure it is set for eMMC boot"
      #read -p "Press ENTER to continue."
      read -t 10 -p "Pause here for 10 seconds"
      echo " "
    fi

    PLNX_BUILD_SUCCESS=-1

    echo "Entering PetaLinux build loop.  Stay here until Linux image is built successfully"
    while [ $PLNX_BUILD_SUCCESS -ne 0 ];
    do
      # Make sure that intermediary files get cleaned up.  This will also force
      # the rootfs to get rebuilt and generate a new image.ub file.
      petalinux-build -x distclean

      # Build PetaLinux project.
      petalinux-build 
      
      PLNX_BUILD_SUCCESS=$?
    done

    # Create boot image.
    petalinux-package --boot --fsbl images/linux/${FSBL_PROJECT_NAME}.elf --fpga ./images/linux/system.bit --uboot --force

    # Copy the boot.bin file and name the new file BOOT_EMMC.bin
    cp ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/images/linux/BOOT.BIN \
    ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/BOOT_EMMC.bin

    # Copy the u-boot.elf file and name the new file u-boot_EMMC.elf
    cp ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/images/linux/u-boot.elf \
    ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/u-boot_EMMC.elf
    
    # Create script to program the QSPI Flash
    echo "#!/bin/sh" > program_boot_emmc_indirect.sh
    echo "program_flash -f ./BOOT_EMMC.bin  -offset 0 -flash_type qspi_dual_parallel -fsbl ./images/linux/${FSBL_PROJECT_NAME}.elf"  >> program_boot_emmc_indirect.sh
    echo "program_flash -f ./images/linux/image.ub -flash_type emmc -emmc_partition_size large -fsbl ./images/linux/${FSBL_PROJECT_NAME}.elf"  >> program_boot_emmc_indirect.sh
    chmod 777 ./program_boot_emmc_indirect.sh
       
    # Create script to program the eMMC device
    echo "#!/bin/sh" > program_boot_emmc_direct.sh
    echo "cp BOOT_EMMC.bin boot.bin" >> program_boot_emmc_direct.sh
    echo "program_flash -f ./boot.bin -flash_type emmc -emmc_partition_size large -fsbl ./images/linux/${FSBL_PROJECT_NAME}.elf"  >> program_boot_emmc_direct.sh
    echo "program_flash -f ./images/linux/image.ub -flash_type emmc -emmc_partition_size large -no_erase -fsbl ./images/linux/${FSBL_PROJECT_NAME}.elf"  >> program_boot_emmc_direct.sh
    chmod 777 ./program_boot_emmc_direct.sh
  fi
  
  # If the EMMC boot no bit option is set, then perform the steps needed to build 
  # BOOT.BIN for booting from QSPI + eMMC with the bistream loaded from eMMC
  # instead of from BOOT.BIN image in QSPI.
  if [ "$BUILD_BOOT_EMMC_NO_BIT_OPTION" == "yes" ]
  then
    # Restore project configurations and wipe out any changes made for special boot options.
    petalinux_project_restore_boot_config

    # Modify the project configuration for EMMC boot.
    petalinux_project_set_boot_config_emmc_no_bit

    # DEBUG
    if [ "$DEBUG" == "yes" ];
    then
      echo "Stop here and go check the platform-top.h file and make sure it is set for eMMC NO BIT boot"
      #read -p "Press ENTER to continue."
      read -t 10 -p "Pause here for 10 seconds"
      echo " "
    fi
   
    PLNX_BUILD_SUCCESS=-1

    echo "Entering PetaLinux build loop.  Stay here until Linux image is built successfully"
    while [ $PLNX_BUILD_SUCCESS -ne 0 ];
    do
      # Make sure that intermediary files get cleaned up.  This will also force
      # the rootfs to get rebuilt and generate a new image.ub file.
      petalinux-build -x distclean

      # Build PetaLinux project.
      petalinux-build 
      
      PLNX_BUILD_SUCCESS=$?
    done

    # Create boot image which does not contain the bistream image.
    petalinux-package --boot --fsbl images/linux/${FSBL_PROJECT_NAME}.elf --uboot --force

    # Copy the boot.bin file and name the new file BOOT_EMMC_No_Bit.BIN
    cp ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/images/linux/BOOT.BIN \
    ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/BOOT_EMMC_No_Bit.BIN

    # Copy the u-boot.elf file and name the new file u-boot_EMMC_No_Bit.elf
    cp ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/images/linux/u-boot.elf \
    ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/u-boot_EMMC_No_Bit.elf

    # Create a temporary Vivado TCL script which take the standard bitstream 
    # file format and modify it to allow u-boot to load it into the 
    # programmable logic on the Zynq device via PCAP interface.
    echo "write_cfgmem -format bin -interface spix1 -loadbit \"up 0x0 ./images/linux/system.bit\" -force images/linux/system.bit.bin" > swap_bits.tcl
    
    # Launch vivado in batch mode to clean output products from the hardware platform.
    vivado -mode batch -source swap_bits.tcl

    # Copy the bit-swapped bitstream to the PetaLinux project folder
    cp ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/images/linux/system.bit.bin \
    ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/.

    # Remove the temporary Vivado script.
    rm -f swap_bits.tcl
  fi

  # If the SD no bit boot option is set, then perform the steps needed to  
  # build BOOT.BIN for booting from SD with the bistream loaded from a file
  # on the SD card instead of from the BOOT.BIN container image.
  if [ "$BUILD_BOOT_SD_NO_BIT_OPTION" == "yes" ]
  then
    # Restore project configurations and wipe out any changes made for special boot options.
    petalinux_project_restore_boot_config

    # Modify the project configuration for sd boot.
    petalinux_project_set_boot_config_sd_no_bit

    # DEBUG
    if [ "$DEBUG" == "yes" ];
    then
      echo "Stop here and go check the platform-top.h file and make sure it is set for SD boot"
      #read -p "Press enter to continue"
      read -t 10 -p "Pause here for 10 seconds"
      echo " "
    fi

    PLNX_BUILD_SUCCESS=-1

    echo "Entering PetaLinux build loop.  Stay here until Linux image is built successfully"
    while [ $PLNX_BUILD_SUCCESS -ne 0 ];
    do
      # Make sure that intermediary files get cleaned up.  This will also force
      # the rootfs to get rebuilt and generate a new image.ub file.
      petalinux-build -x distclean

      # Build PetaLinux project.
      petalinux-build 

      PLNX_BUILD_SUCCESS=$?
    done
   
    # Create boot image which does not contain the bistream image.
    petalinux-package --boot --fsbl images/linux/${FSBL_PROJECT_NAME}.elf --uboot --force
   
    # Copy the boot.bin file and name the new file BOOT_SD_No_Bit.BIN
    cp ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/images/linux/BOOT.BIN \
    ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/BOOT_SD_No_Bit.BIN

    # Copy the u-boot.elf file and name the new file u-boot_SD_No_Bit.elf
    cp ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/images/linux/u-boot.elf \
    ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/u-boot_SD_No_Bit.elf

    # Create a temporary Vivado TCL script which take the standard bitstream 
    # file format and modify it to allow u-boot to load it into the 
    # programmable logic on the Zynq device via PCAP interface.
    echo "write_cfgmem -format bin -interface spix1 -loadbit \"up 0x0 hw_platform/system_wrapper.bit\" -force images/linux/system.bit.bin" > swap_bits.tcl

    # Launch vivado in batch mode to clean output products from the hardware platform.
     vivado -mode batch -source swap_bits.tcl

    # Copy the bit-swapped bitstream to the PetaLinux project folder
    cp ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/images/linux/system.bit.bin \
    ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/.

    # Remove the temporary Vivado script.
    rm -f swap_bits.tcl
  fi

  # If the SD boot option is set, then perform the steps needed to  
  # build BOOT.BIN for booting from SD with the bistream loaded from 
  # the BOOT.BIN container image on the SD card.
  if [ "$BUILD_BOOT_SD_OPTION" == "yes" ]
  then
    # Restore project configurations and wipe out any changes made for special boot options.
    petalinux_project_restore_boot_config

    # Modify the project configuration for sd boot.
    petalinux_project_set_boot_config_sd

    # DEBUG
    if [ "$DEBUG" == "yes" ];
    then
      echo "Stop here and go check the platform-top.h file and make sure it is set for SD boot"
      #read -p "Press enter to continue"
      read -t 10 -p "Pause here for 10 seconds"
      echo " "
    fi

    PLNX_BUILD_SUCCESS=-1

    echo "Entering PetaLinux build loop.  Stay here until Linux image is built successfully"
    while [ $PLNX_BUILD_SUCCESS -ne 0 ];
    do
      # Make sure that intermediary files get cleaned up.  This will also force
      # the rootfs to get rebuilt and generate a new image.ub file.
      petalinux-build -x distclean

      # Import the hardware description into the PetaLinux project again.  
      # This *might* fix an issue with being able to build a working SDSoC platform.
      petalinux-config --silentconfig --get-hw-description=./hw_platform/ -p ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}
   
      # Build PetaLinux project.
      petalinux-build 

      PLNX_BUILD_SUCCESS=$?
    done

    # If the SD OOB boot option is set, then perform the steps needed to  
    # build BOOT.BIN for booting from SD without any bistream loaded from 
    # the BOOT.BIN container image on the SD card or from U-Boot during
    # second stage boot.  This allows the same SD boot.bin to boot on any
    # of the SOMs.
    if [ "$BUILD_BOOT_SD_OOB_OPTION" == "yes" ]
    then
      # Create boot image which does not contain the bistream image.
      petalinux-package --boot --fsbl images/linux/${FSBL_PROJECT_NAME}.elf --uboot --force

      # Copy the boot.bin file and name the new file BOOT_SD_OOB.BIN
      cp ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/images/linux/BOOT.BIN \
      ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/BOOT_SD_OOB.bin
    fi

    # Create boot image which DOES contain the bistream image.
    petalinux-package --boot --fsbl images/linux/${FSBL_PROJECT_NAME}.elf --fpga hw_platform/system_wrapper.bit --uboot --force

    # Copy the boot.bin file and name the new file BOOT_SD.BIN
    cp ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/images/linux/BOOT.BIN \
    ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/BOOT_SD.bin
    
    # Copy the u-boot.elf file and name the new file u-boot_SD.elf
    cp ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/images/linux/u-boot.elf \
    ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/u-boot_SD.elf
  fi

  # Change to HDL scripts folder.
  cd ${START_FOLDER}/${HDL_SCRIPTS_FOLDER}

  # Clean the hardware project output products using the HDL TCL scripts.
  echo "set argv [list board=${HDL_BOARD_NAME}_${PLNX_VER} project=${HDL_PROJECT_NAME} clean=yes jtag=yes version_override=yes]" > cleanup.tcl
  echo "set argc [llength \$argv]" >> cleanup.tcl
  echo "source ./make.tcl -notrace" >> cleanup.tcl

  # Launch vivado in batch mode to clean output products from the hardware platform.
  # DEBUG !!!Uncomment the next line before public release!!!
  #vivado -mode batch -source cleanup.tcl

  # Change to PetaLinux project folder.
  cd ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/

  # Package the bitstream within the PetaLinux pre-built folder.
  petalinux-package --prebuilt --fpga images/linux/system.bit --force

  # Rename the pre-built bitstream file to download.bit so that the default 
  # format for the petalinux-boot command over jtag will not need the bit file 
  # specified explicitly.
  mv -f pre-built/linux/implementation/system.bit \
  pre-built/linux/implementation/download.bit

  # Create script to copy the image files to tftpboot folder and launch Petalinux JTAG boot
  # This will boot to u-boot, then the user can use tftpboot (run netboot) to boot the Linux image
  echo "#!/bin/sh" > cptftp_jtag.sh
  echo "rm -rf ${TFTP_HOST_FOLDER}/*"  >> cptftp_jtag.sh
  echo "cp -rf ./*.bin ${TFTP_HOST_FOLDER}/." >> cptftp_jtag.sh
  echo "cp -rf ./images/linux/* ${TFTP_HOST_FOLDER}/." >> cptftp_jtag.sh
  #echo "sync&&sync" >> cptftp_jtag.sh
  echo "echo \"petalinux-boot --jtag --fpga --bitstream ./images/linux/system.bit --u-boot\"" >> cptftp_jtag.sh
  echo "sync && sync && petalinux-boot --jtag --fpga --bitstream ./images/linux/system.bit --u-boot" >> cptftp_jtag.sh
  chmod 777 ./cptftp_jtag.sh
  
  # Change to PetaLinux projects folder.
  cd ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/

  # Copy the image.ub to the pre-built images folder.
  cp ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/images/linux/image.ub \
  ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/pre-built/linux/images/.

  # If the BOOT_QSPI_OPTION is set, copy the BOOT_QSPI.BIN to the 
  # pre-built images folder.
  if [ "$BUILD_BOOT_QSPI_OPTION" == "yes" ]
  then
    cp ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/BOOT_QSPI.bin \
    ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/pre-built/linux/images/

    # Also copy the u-boot_QSPI.elf file to the pre-build images folder.
    cp ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/u-boot_QSPI.elf \
    ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/pre-built/linux/images/
  fi

  # If the BOOT_EMMC_OPTION is set, copy the BOOT_EMMC.BIN to the 
  # pre-built images folder.
  if [ "$BUILD_BOOT_EMMC_OPTION" == "yes" ]
  then
    cp ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/BOOT_EMMC.bin \
    ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/pre-built/linux/images/

    # Also copy the u-boot_EMMC.elf file to the pre-build images folder.
    cp ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/u-boot_EMMC.elf \
    ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/pre-built/linux/images/
  fi

  # If the BOOT_EMMC_NO_BIT_OPTION is set, copy the BOOT_EMMC_No_Bit.BIN and 
  # the system.bit.bin files into the pre-built images folder.
  if [ "$BUILD_BOOT_EMMC_NO_BIT_OPTION" == "yes" ]
  then
    cp ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/BOOT_EMMC_No_Bit.BIN \
    ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/pre-built/linux/images/

    cp ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/system.bit.bin \
    ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/pre-built/linux/images/

    # Also copy the u-boot_EMMC_No_Bit.elf file to the pre-build images folder.
    cp ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/u-boot_EMMC_No_Bit.elf \
    ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/pre-built/linux/images/
  fi

  # Change to PetaLinux  # If the BOOT_SD_OPTION is set, copy the BOOT_SD.BIN to the 
  # pre-built images folder.
  if [ "$BUILD_BOOT_SD_OPTION" == "yes" ]
  then
    # Copy the BOOT_SD.BIN to the pre-built images folder.
    cp ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/BOOT_SD.bin \
    ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/pre-built/linux/images/

    # Also copy the u-boot_SD.elf file to the pre-build images folder.
    cp ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/u-boot_SD.elf \
    ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/pre-built/linux/images/
  fi
  
  # If the BOOT_SD_OOB_OPTION is set, copy the BOOT_SD_OOB.BIN to the 
  # pre-built images folder.
  if [ "$BUILD_BOOT_SD_OOB_OPTION" == "yes" ]
  then
    cp ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/BOOT_SD_OOB.bin \
    ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/pre-built/linux/images/
  fi
  
  # If the BOOT_SD_NO_BIT_OPTION is set, copy the BOOT_EMMC_No_Bit.BIN and 
  # the system.bit.bin files into the pre-built images folder.
  if [ "$BUILD_BOOT_SD_NO_BIT_OPTION" == "yes" ]
  then
    cp ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/BOOT_SD_No_Bit.BIN \
    ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/pre-built/linux/images/

    cp ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/system.bit.bin \
    ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/pre-built/linux/images/

    # Also copy the u-boot_SD_No_Bit.elf file to the pre-build images folder.
    cp ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/u-boot_SD_No_Bit.elf \
    ${START_FOLDER}/${PETALINUX_PROJECTS_FOLDER}/${PETALINUX_PROJECT_NAME}/pre-built/linux/images/
  fi

  # Package the hardware source into a BSP package output.
  petalinux-package --bsp -p ${PETALINUX_PROJECT_NAME} \
  --hwsource ${START_FOLDER}/${HDL_PROJECTS_FOLDER}/${HDL_PROJECT_NAME}/${HDL_BOARD_NAME}_${PLNX_VER}/ \
  --output ${PETALINUX_PROJECT_NAME} --force

  # Change to PetaLinux scripts folder.
  cd ${START_FOLDER}/${PETALINUX_SCRIPTS_FOLDER}
}

build_hw_platform ()
{
  # Change to HDL projects folder.
  cd ${START_FOLDER}/${HDL_PROJECTS_FOLDER}

  # Check to see if the Vivado hardware project has not been built.  
  # If it hasn't then build it now.  
  # If it has then fall through and build the PetaLinux BSP
  if [ ! -e ${HDL_PROJECT_NAME}/${HDL_BOARD_NAME}_${PLNX_VER}/${HDL_BOARD_NAME}.xsa ]
  then
    ls -al ${HDL_PROJECT_NAME}/${HDL_BOARD_NAME}_${PLNX_VER}/${HDL_BOARD_NAME}/
    echo " "
    echo "No built Vivado HW project ${HDL_PROJECT_NAME}/${HDL_BOARD_NAME}_${PLNX_VER} found."
    echo "Will build the hardware platform now."
    echo " "

    # DEBUG
    if [ "$DEBUG" == "yes" ];
    then
      read -t 5 -p "Pause here for 5 seconds"
      echo " "
    fi
      
    # Change to HDL scripts folder.
    cd ${START_FOLDER}/${HDL_SCRIPTS_FOLDER}
    # Launch vivado in batch mode to build hardware platforms for the selected target boards.
    # NOTE that at this time, the argv make assist script is responsible for adding board= and project=
    # this script is responsible for putting them in the correct order (board, then project)
    vivado -mode batch -notrace -source make_${HDL_PROJECT_NAME}.tcl -tclargs ${HDL_BOARD_NAME} ${HDL_PROJECT_NAME} 
    #vivado -mode batch -source make_${HDL_PROJECT_NAME}.tcl
  else
    echo " "
    echo "Found Vivado HW project ${HDL_PROJECT_NAME}/${HDL_BOARD_NAME}_${PLNX_VER}."
    echo "Will build the PetaLinux BSP now."
    echo " "

    # DEBUG
    if [ "$DEBUG" == "yes" ];
    then
      read -t 5 -p "Pause here for 5 seconds"
      echo " "
    fi  
  fi
}

# This function is responsible for first creating all of the hardware
# platforms needed for generating PetaLinux BSPs and once the hardware
# platforms are ready, they can be specificed in HDL_BOARD_NAME variable 
# before the call to create_petalinux_bsp.
#
# Once the PetaLinux BSP creation is complete, a BSP package file with the
# name specified in the PETALINUX_PROJECT_NAME variable can be distributed
# for use to others.
#
# NOTE:  If there is more than one hardware platform to be built, they will
#        all be built before any PetaLinux projects are created.  If you
#        are looking to save some time and only build for a specific target
#        be sure to comment out the other build targets in the 
#        make_<platform>.tcl hardware platform automation script AND comment
#        out the other BSP automated projects below otherwise, everything
#        will build which can take a very long time if you have multiple
#        hardware platforms and BSP projects defined.
main_make_function ()
{
  #
  # Create the hardware platform (if necessary) 
  # and build the PetaLinux BSP for the UZ3EG_IOCC target.
  
  if [ "$BUILD_UZ3EG_IOCC" == "yes" ]
  then
    HDL_BOARD_NAME=UZ3EG_IOCC
    PETALINUX_PROJECT_NAME=uz3eg_iocc_${PLNX_VER}
    PETALINUX_ROOTFS_NAME=uz3eg_iocc
    build_hw_platform
    create_petalinux_bsp
  fi
  
  # Create the hardware platform (if necessary) 
  # and build the PetaLinux BSP for the UZ3EG_PCIEC target.

  if [ "$BUILD_UZ3EG_PCIEC" == "yes" ]
  then
    HDL_BOARD_NAME=UZ3EG_PCIEC
    PETALINUX_PROJECT_NAME=uz3eg_pciec_${PLNX_VER}
    PETALINUX_ROOTFS_NAME=uz3eg_pciec
    build_hw_platform
    create_petalinux_bsp
  fi
  
  #
  # Create the hardware platform (if necessary) 
  # and build the PetaLinux BSP for the UZ7EV_EVCC target.
  
  if [ "$BUILD_UZ7EV_EVCC" == "yes" ]
  then
    HDL_BOARD_NAME=UZ7EV_EVCC
    PETALINUX_PROJECT_NAME=uz7ev_evcc_${PLNX_VER}
    PETALINUX_ROOTFS_NAME=uz7ev_evcc
    build_hw_platform
    create_petalinux_bsp
  fi

}

# First source any tools scripts to setup the environment needed to call both
# PetaLinux and Vivado from this make script.
source_tools_settings

# Call the main_make_function declared above to start building everything.
main_make_function


