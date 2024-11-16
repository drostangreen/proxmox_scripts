#!/bin/bash

set -e

blacklist_graphics_drivers() {
	echo "options vfio_iommu_type1 allow_unsafe_interrupts=1" > /etc/modprobe.d/iommu_unsafe_interrupts.conf
	echo "options kvm ignore_msrs=1" > /etc/modprobe.d/kvm.conf
	echo "blacklist nouveau" >> /etc/modprobe.d/blacklist.conf
	echo "blacklist nvidia" >> /etc/modprobe.d/blacklist.conf
}

Help() {
    echo "Setups up PCI Passthrough on Proxmox"
    echo
    echo "options:"
    echo "-a    Proxmox Host uses AMD CPU"
    echo "-n    Proxmox Host uses Intel CPU"
    echo "-h    show help"
    echo
    echo '######################################################'
    echo "long options:"
    echo "--amd                 Proxmox Host uses AMD CPU"
    echo "--intel               Proxmox Host uses Intel CPU"
    echo "--help                show help"
}

Error() {
    echo "Error at line $1"
}
trap 'Error $LINENO' ERR

while [ "$1" != "" ]; do
    case $1 in
    -a | --amd)
	iommu=amd_iommu=on
        ;;
    -i | --intel)
	iommu=intel_iommu=on
        ;;

    * )
        echo Invalid option
	Help
        exit 1
        ;;
    esac
    shift # remove the current value for `$1` and use the next
done

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"; Help
  exit 1
fi

########### Beginning of Script ############################

if [ -d /sys/firmware/efi ]
then
	cat "$iommu" > /etc/kernel/cmdlin
	proxmox-boot-tool refresh
else
	sed -i.bak 's/GRUB_CMDLINE_LINUX_DEFAULT="quiet"/GRUB_CMDLINE_LINUX_DEFAULT="quiet $iommu"/' /etc/default/grub	
	update-grub
fi

echo -e "vfio\nvfio_iommu_type1\nvfio_pci\nvfio_virqfd" >> /etc/modules

read -p "Would you like to Blacklist Graphics Drivers? (Y/n)"
if [[ $REPLY =~ ^[Nn]$ ]]
then
	echo "Graphics Drivers not Blacklisted. Please Reboot Proxmox host. PCI Passthrough Enabled."
	exit
else
	blacklist_graphics_drivers
	echo -e 'How to configure GPU for PCIe Passthrough\nlspci\nEnter PCI Idendifier		i.e. lspci -n -s ##.## -v\nCopy the HEX values from GPU here:\necho "options vfio-pci ids=####.####,####.#### disable_vga=1" > /etc/modprobe.d/vfio.conf"\nApply all changes\nupdate-initramfs -u -k all\nReboot Proxmox host'
	echo "See ./gpu_passthrough_setup.md for further steps for GPU passthrough."
fi

echo "Please Reboot Proxmox host. PCI Passthrough Enabled."

