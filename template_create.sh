#!/bin/bash

Help(){
    echo Use this script with the following flags
    echo "-v    select the VMID to use for template *REQUIRED"
    echo "-d    set the distro name *REQUIRED"
    echo "-u    set the url of the image to download *REQUIRED"
    echo "-p    set the password for the created user with Cloud Init"
    echo "-s    set the ssh key file to be used"
}

while getopts hv:d:u:p:s: flag
do
    case $flag in
        h)
        Help
        exit 0
        ;;

        v)
        VMID=$OPTARG
        ;;

        d)
        distro=$OPTARG
        ;;

        u)
        url=$OPTARG
        ;;

        p)
        cipassword=$OPTARG
        ;;

        s)
        sshkeys=$OPTARG
        ;;

        \?)
        echo "Invalid Flag"
        exit 1
        ;;

    esac
done


function pause(){
   read -p "$*"
}

# Uncomment below line to "hard code" the ssh keys. It takes precidence over the above flag.
# sshkeys=~/.ssh/id_rsa.pub
image=$distro.qcow2

echo "Downloading $image now"; wget -qO $image $url

# installing qemu-guest-agent into the downloaded qcow2 image, then removing machine-id
virt-customize -a $image --update
virt-customize -a $image --install qemu-guest-agent
virt-customize -a $image --run-command '>/etc/machine-id'

# create VM, resize the disk, import disk and create Cloud Init drive. Then set default settings for vm
qm create $VMID --memory 1024 --core 1 --name $distro-template-ga --net0 virtio,bridge=vmbr0
qemu-img resize $image 10G
qm importdisk $VMID $image local-lvm
qm set $VMID --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-$VMID-disk-0,discard=on,ssd=1
qm set $VMID --ide2 local-lvm:cloudinit
qm set $VMID --boot c --bootdisk scsi0
qm set $VMID --serial0 socket --vga serial0
qm set $VMID --agent 1

# Below is Cloud Init. Switch the Commented line if you'd like to set a password.
# The Proxmox team does recommend only using SSH key and now password. You will not be able to 
# log in from the console in this case.
# qm set $VMID --ciuser tadmin --cipassword $cipassword --ipconfig0 ip=dhcp --sshkeys $sshkeys
qm set $VMID --ciuser tadmin --ipconfig0 ip=dhcp --sshkeys $sshkeys

# Comment this line to skip the pause to check settings
pause 'Press [Enter] key to create finish creating template...'

echo Converting $VMID to Template; qm template $VMID > /dev/null

echo Deleting $image file; rm $image

echo "Your New Template is Ready!"