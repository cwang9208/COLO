#!/bin/sh
# usage:
# (1) change @disk_path to your own path of disk image 
# (2) set @nbdserver to your nbdserver ip:prot
# (3) set @forward_dev to interface for forward packet
# (4) sh secondary-colo.sh

disk_path=/mnt/sdb/pure_IMG/redhat/redhat-7.0.img
active_disk=/mnt/ramfs/active_disk.img
hidden_disk=/mnt/ramfs/hidden_disk.img
nbdserver=192.168.2.88:8889
forward_dev=eth1

tmp_disk_size=`./qemu-img info $disk_path |grep 'virtual size' |awk  '{print $3}'`

net_param="-netdev tap,id=hn0,script=/etc/qemu-ifup,downscript=/etc/qemu-ifdown,colo_script=./scripts/colo-proxy-script.sh,forward_nic=${forward_dev},vhost=on -device virtio-net-pci,id=net-pci0,netdev=hn0"

block_param="-drive if=none,file=$disk_path,id=colo1 -drive if=virtio,driver=replication,mode=secondary,throttling.bps-total-max=70000000,file.file.filename=$active_disk,file.driver=qcow2,file.backing.file.filename=$hidden_disk,file.backing.driver=qcow2,file.backing.allow-write-backing-file=on,file.backing.backing.backing_reference=colo1"

cmdline="x86_64-softmmu/qemu-system-x86_64 -enable-kvm $net_param -boot c $block_param -vnc :7 -m 2048 -smp 2 -device piix3-usb-uhci -device usb-tablet -monitor stdio -incoming tcp:0:8888"

function create_image()
{
    ./qemu-img create -f qcow2 $1 $tmp_disk_size
}

function prepare_temp_images()
{
    grep -q "^none /mnt/ramfs ramfs" /proc/mounts
    if [[ $? -ne 0 ]]; then
        mkdir -p /mnt/ramfs/
        mount -t ramfs none /mnt/ramfs/ -o size=4G
    fi

    rm -rf $active_disk $hidden_disk
    create_image $active_disk
    create_image $hidden_disk
}

prepare_temp_images

echo $cmdline
echo
echo "Please Enter: nbd_server_start $nbdserver"
echo "Please Enter: nbd_server_add -w colo1"
echo
modprobe xt_SECCOLO
modprobe nf_conntrack_colo
modprobe nfnetlink_colo
modprobe nf_conntrack_ipv4
modprobe kvm-intel
rmmod vhost_net
modprobe vhost-net experimental_zcopytx=0
exec $cmdline
