#!/bin/bash

Help(){
    echo Use this script with the following flags
    echo "-v    select the starting VMID *REQUIRED"
    echo "-s    select storage target (use shared storage if available) *REQUIRED"
}

# Place the name of the distros you would like to see created
# Order matters they must match up one for one
# Below is what I use but you can modify it to your liking
distro=(
    debian10
    debian11
    ubuntu2004
    ubuntu2204
    rocky8
    rocky9
    fedora37
    opensuse154
)
url=(
    https://cloud.debian.org/images/cloud/buster/latest/debian-10-generic-amd64.qcow2
    https://cloud.debian.org/images/cloud/bullseye/latest/debian-11-generic-amd64.qcow2
    https://cloud-images.ubuntu.com/minimal/releases/focal/release/ubuntu-20.04-minimal-cloudimg-amd64.img
    https://cloud-images.ubuntu.com/minimal/releases/jammy/release/ubuntu-22.04-minimal-cloudimg-amd64.img
    https://dl.rockylinux.org/pub/rocky/8/images/x86_64/Rocky-8-GenericCloud-Base.latest.x86_64.qcow2
    https://dl.rockylinux.org/pub/rocky/9/images/x86_64/Rocky-9-GenericCloud-Base.latest.x86_64.qcow2
    https://download.fedoraproject.org/pub/fedora/linux/releases/37/Cloud/x86_64/images/Fedora-Cloud-Base-37-1.7.x86_64.qcow2
    https://download.opensuse.org/repositories/Cloud:/Images:/Leap_15.4/images/openSUSE-Leap-15.4.x86_64-1.0.1-NoCloud-Build2.188.qcow2
)

while getopts hv:s: flag
do
    case $flag in
        h)
        Help
        exit 0
        ;;

        v)
        VMID=$OPTARG-1
        ;;

        s)
        storage=$OPTARG
        ;;

        \?)
        echo "Invalid Flag"
        exit 1
        ;;

    esac
done

echo "Removing any old qcow2 or img files"; rm -f *.qcow2 *.img > /dev/null

template_create () {
    sshkeys=~/tadmin_pub_key
    
    echo "Downloading $image now"; wget -qO $image $url

    # installing qemu-guest-agent into the downloaded qcow2 image, then removing machine-id
    echo "Updating $image"; virt-customize -a $image --update > /dev/null
    echo "Installing qemu-guest-agent"; virt-customize -a $image --install qemu-guest-agent > /dev/null
    echo "Removing /etc/machine-id"; virt-customize -a $image --run-command '>/etc/machine-id' > /dev/null

    # create VM, resize the disk, import disk and create Cloud Init drive. Then set default settings for vm
    echo "Creating $VMID with name ${distro[$index]}-template-ga"; qm create $VMID --memory 1024 --core 1 --name ${distro[$index]}-template-ga --net0 virtio,bridge=vmbr0 > /dev/null
    echo "Resizing disk"; qemu-img resize $image 10G > /dev/null
    echo "Importing disk"; qm importdisk $VMID $image $storage --format qcow2 > /dev/null
    if [ -f /mnt/pve/$storage/images/$VMID/*-$VMID-disk-0.qcow2 ]; then
        echo "Setting Virtual Drive to scsi0 on shared storage"; qm set $VMID --scsihw virtio-scsi-pci --scsi0 $storage:$VMID/vm-$VMID-disk-0.qcow2,discard=on,ssd=1,format=qcow2 > /dev/null
    else
        echo "Setting Virtual Drive to scsi0"; qm set $VMID --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-$VMID-disk-0,discard=on,ssd=1 > /dev/null
    fi
    echo "Add Cloud Init drive"; qm set $VMID --ide2 $storage:cloudinit > /dev/null
    echo "Set bootdisk to scsi0"; qm set $VMID --boot c --bootdisk scsi0 > /dev/null
    echo "Set serial connecton"; qm set $VMID --serial0 socket --vga serial0 > /dev/null
    echo "Enabling qemu-guest-agent in Proxmox"; qm set $VMID --agent 1 > /dev/null

    # Below is Cloud Init. Switch the Commented line if you'd like to set a password.
    # The Proxmox team does recommend only using SSH key and now password. You will not be able to 
    # log in from the console in this case.
    # qm set $VMID --ciuser tadmin --cipassword $cipassword --ipconfig0 ip=dhcp --sshkeys $sshkeys
    echo "Defining Cloud Init params"; qm set $VMID --ciuser tadmin --ipconfig0 ip=dhcp --sshkeys $sshkeys > /dev/null

    echo "Converting $VMID to Template"; qm template $VMID > /dev/null

    echo "Deleting $image file"; rm $image > /dev/null
} 

for index in ${!distro[*]};
do
    ((VMID=VMID+1))
    image=${distro[$index]}.qcow2
    template_create
done

echo "All Templates Created"