## How to setup/test COLO

### Hardware requirements
There is at least one directly connected nic to forward the network requests from client to secondary vm. The directly connected nic must not be used by any other purpose.

### Network link topology
```
=================================normal ======================================
                                +--------+
                                |client  |
         master                 +----+---+                    slave
-------------------------+           |            + -------------------------+
   PVM                   |           +            |                          |
+-------+         +----[eth0]-----[switch]-----[eth0]---------+              |
|guest  |     +---+-+    |                        |       +---+-+            |
|     [tap0]--+ br0 |    |                        |       | br0 |            |
|       |     +-----+  [eth1]-----[forward]----[eth1]--+  +-----+     SVM    |
+-------+                |                        |    |            +-------+|
                         |                        |    |  +-----+   | guest ||
                       [eth2]---[checkpoint]---[eth2]  +--+br1  |-[tap0]    ||
                         |                        |       +-----+   |       ||
                         |                        |                 +-------+|
-------------------------+                        +--------------------------+
e.g.
master:
br0: 192.168.0.33
eth1: 192.168.1.33
eth2: 192.168.2.33

slave:
br0: 192.168.0.88
br1: no ip address
eth1: 192.168.1.88
eth2: 192.168.2.88
```
NOTE: br0 is setup by adminitrator but br1 is setup by colo now.

### Test environment prepare

- Prepare host kernel

  colo-proxy kernel module need cooperate with linux kernel.
  
  You should patch colo-patch-for-kernel.patch into kernel codes,

  then compile kernel and intall the new kernel (Recommend kernel-3.18.10)

```
# patch -p1 < 0001-colo-patch-for-kernel.patch

# make menuconfig
# make
# make modules_install install
```
- Proxy module
  - proxy module is used for network packets compare.
```
# git clone https://github.com/coloft/colo-proxy.git
# cd ./colo-proxy
# make
# make install
```
- Modified iptables
  - We have add a new rule to iptables command.
```
# git clone https://github.com/coloft/iptables.git
# cd ./iptables
# git checkout colo
# ./autogen.sh && ./configure
# make && make install
```
- libnftnl
- arptables
  - Please get the latest arptables and then compile and install

- Qemu colo
  - Checkout the latest colo branch from colo-v1.5-basic or
    - colo-v1.5-developing(More features)

```
# cd qemu
# ./configure --target-list=x86_64-softmmu --enable-colo
# make
```

- Set Up the Bridge and network environment
  - You must setup you network environment like above picture(Network link topology Normal). 


- Qemu-ifup/Qemu-ifdown
  - We need a script to bring up the TAP interface.
  - a qemu-ifdown script is needed to reset you networking configuration which is configured by qemu-ifup script

```
NOTE: Don't forget to change this script file permission to be executable

Master:
root@master# cat /etc/qemu-ifup
#!/bin/sh
switch=br0
if [ -n "$1" ]; then
         ip link set $1 up
         brctl addif ${switch} $1
fi
root@master# cat /etc/qemu-ifdown
!/bin/sh
switch=br0
if [ -n "$1" ]; then
        brctl delif ${switch} $1
fi
Slave:
like Master side
```

### Test steps
***(Note: We apply two scripts to help completing step (1) ~ step (2), primary-colo.sh secondary-colo.sh)***

- (1) Load modeule
```
# modprobe xt_PMYCOLO (For slave side, modprobe xt_SECCOLO)
# modprobe nf_conntrack_colo (Other colo module will be automatically loaded by
script colo-proxy-script.sh)
# modprobe xt_mark
# modprobe kvm-intel
```
- (2) Startup qemu
- *Master side:*
```
# x86_64-softmmu/qemu-system-x86_64 -machine pc-i440fx-2.3,accel=kvm,usb=off \
-netdev tap,id=hn0,script=/etc/qemu-ifup,downscript=/etc/qemu-ifdown,\
colo_script=./scripts/colo-proxy-script.sh,forward_nic=eth1 -device virtio-net-pci,id=net-pci0,netdev=hn0 \
-boot c -drive if=virtio,id=disk1,driver=quorum,read-pattern=fifo,cache=none,aio=native,\
children.0.file.filename=/mnt/sdb/pure_IMG/redhat/redhat-7.0.img,children.0.driver=raw \
-vnc :7 -m 2048 -smp 2 -device piix3-usb-uhci -device usb-tablet -monitor stdio -S
```

- *Slave side:*
```
# x86_64-softmmu/qemu-system-x86_64 -machine pc-i440fx-2.3,accel=kvm,usb=off \
-netdev tap,id=hn0,script=/etc/qemu-ifup,downscript=/etc/qemu-ifdown,\
colo_script=./scripts/colo-proxy-script.sh,forward_nic=eth1 -device virtio-net-pci,id=net-pci0,netdev=hn0 \
-drive if=none,driver=raw,file=/mnt/sdb/pure_IMG/redhat/redhat-7.0.img,id=colo1,cache=none,aio=native \
-drive if=virtio,driver=replication,mode=secondary,throttling.bps-total-max=70000000,\
file.file.filename=/mnt/ramfs/active_disk.img,file.driver=qcow2,\
file.backing.file.filename=/mnt/ramfs/hidden_disk.img,\
file.backing.driver=qcow2,\
file.backing.backing.backing_reference=colo1,\
file.backing.allow-write-backing-file=on \
-vnc :7 -m 2048 -smp 2 -device piix3-usb-uhci -device usb-tablet -monitor stdio -incoming tcp:0:8888
```
***Note:***

1. Active disk, hidden disk and nbd target's length should be the same.

- (3) On Secondary VM's QEMU monitor, issue command (This command must be run before command in step (4))
```
(qemu) nbd_server_start 192.168.2.88:8889
(qemu) nbd_server_add -w colo1
```
- (4) On Primary VM's QEMU monitor, issue command: 
```
(qemu) child_add disk1 child.driver=replication,child.mode=primary,child.file.host=192.168.2.88,child.file.port=8889,child.file.export=colo1,child.file.driver=nbd,child.ignore-errors=on
(qemu) migrate_set_capability colo on
(qemu) migrate tcp:192.168.2.88:8888
```
***Note:***

1. host is the secondary physical machine's hostname or IP

- (5) Done
  - You will see two runing VMs, whenever you make changes to PVM, SVM will be synced. 
