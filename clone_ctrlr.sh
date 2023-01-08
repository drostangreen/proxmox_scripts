#!/bin/bash

Help(){
    echo Use this script with the following flags
    echo "-v    select the starting VMID"
    echo "-c    selects the template VMID to use"
    echo "-s    select the storage to use"
	echo "-n	set the number of vms"
}

while getopts hv:c:s:n: flag
do
    case $flag in
        h)
        Help
        exit 0
        ;;

        v)
        START=$OPTARG
        ;;

        c)
        clonevmid=$OPTARG
        ;;

        s)
        storage=$OPTARG
        ;;

		n)
		n=$OPTARG
		;;

        \?)
        echo "Invalid Flag"
        exit 1
        ;;

    esac
done

node=0					# don't touch
counter=0				# don't touch

END=$(($START+$n-1))	# Sets the last VMID based on the number of nodes requested

for (( vmid=$START; vmid<=$END; vmid++ )); 
do
	if [ $node == 3 ]
	then
		node=0
	fi
	count=$((count+1))
	node=$((node+1))
	echo "Creating $vmid now......";
	qm clone $clonevmid $vmid --name ctrlr$count --full true --storage $storage --target pve-cluster$node > /dev/null
done

echo "Cloning Complete!"
