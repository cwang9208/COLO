# COLO

## Test environment prepare
- Qemu colo
  - Checkout the latest COLO branch from colo-v5.1-developing-COLO-frame-v21-with-shared-disk
```
# cd qemu
# ./configure --target-list=x86_64-softmmu --enable-colo --enable-gcrypt --enable-replication
# make -j
```

- Set Up the Bridge and network environment

- Qemu-ifup/Qemu-ifdown
  - We need a script to bring up the TAP interface. 
```
NOTE: Don't forget to change this script file permission to be executable

Primary:
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
Secondary:
like Primary side
```

## Test steps
**Note: Here the primary side host ip is 10.22.1.2, secondary side host ip is 10.22.1.3. Please change them according to your actual environment.**
- (1) Startup qemu
- *Primary side*
```
# x86_64-softmmu/qemu-system-x86_64 -enable-kvm -boot c -m 2048 -smp 2 -qmp stdio -vnc :7 -name primary -cpu qemu64,+kvmclock -device piix3-usb-uhci \
  -drive if=virtio,id=colo-disk0,driver=quorum,read-pattern=fifo,vote-threshold=1,children.0.file.filename=/local/ubuntu/ubuntu-server.img,children.0.driver=raw -S \
  -netdev tap,id=hn0,vhost=off,script=/etc/qemu-ifup,downscript=/etc/qemu-ifdown \
  -device e1000,id=e0,netdev=hn0,mac=52:a4:00:12:78:66 \
  -chardev socket,id=mirror0,host=10.22.1.2,port=9003,server,nowait -chardev socket,id=compare1,host=10.22.1.2,port=9004,server,nowait \
  -chardev socket,id=compare0,host=10.22.1.2,port=9001,server,nowait -chardev socket,id=compare0-0,host=10.22.1.2,port=9001 \
  -chardev socket,id=compare_out,host=10.22.1.2,port=9005,server,nowait \
  -chardev socket,id=compare_out0,host=10.22.1.2,port=9005 \
  -object filter-mirror,id=m0,netdev=hn0,queue=tx,outdev=mirror0 \
  -object filter-redirector,netdev=hn0,id=redire0,queue=rx,indev=compare_out -object filter-redirector,netdev=hn0,id=redire1,queue=rx,outdev=compare0 \
  -object colo-compare,id=comp0,primary_in=compare0-0,secondary_in=compare1,outdev=compare_out0
```
- *Secondary side*
```
# qemu-img create -f qcow2 /mnt/ramfs/active_disk.img 8G

# qemu-img create -f qcow2 /mnt/ramfs/hidden_disk.img 8G

# x86_64-softmmu/qemu-system-x86_64 -boot c -m 2048 -smp 2 -qmp stdio -vnc :7 -name secondary -enable-kvm -cpu qemu64,+kvmclock -device piix3-usb-uhci \
  -drive if=none,id=colo-disk0,file.filename=/local/ubuntu/ubuntu-server.img,driver=raw,node-name=node0 \
  -drive if=virtio,id=active-disk0,driver=replication,mode=secondary,file.driver=qcow2,top-id=active-disk0,file.file.filename=/mnt/ramfs/active_disk.img,file.backing.driver=qcow2,file.backing.file.filename=/mnt/ramfs/hidden_disk.img,file.backing.backing=colo-disk0  \
  -netdev tap,id=hn0,vhost=off,script=/etc/qemu-ifup,downscript=/etc/qemu-ifdown \
  -device e1000,netdev=hn0,mac=52:a4:00:12:78:66 -chardev socket,id=red0,host=10.22.1.2,port=9003 \
  -chardev socket,id=red1,host=10.22.1.2,port=9004 \
  -object filter-redirector,id=f1,netdev=hn0,queue=tx,indev=red0 \
  -object filter-redirector,id=f2,netdev=hn0,queue=rx,outdev=red1 \
  -object filter-rewriter,id=rew0,netdev=hn0,queue=all -incoming tcp:0:8888
```
- (2) On Secondary VM's monitor, issue command
```
{'execute':'qmp_capabilities'}
{ 'execute': 'nbd-server-start',
  'arguments': {'addr': {'type': 'inet', 'data': {'host': '10.22.1.3', 'port': '8889'} } }
}
{'execute': 'nbd-server-add', 'arguments': {'device': 'colo-disk0', 'writable': true } }
```
***Note***:  
a. The qmp command nbd-server-start and nbd-server-add must be run before running the qmp command migrate on primary QEMU  
b. Active disk, hidden disk and nbd target's length should be the same.

- (3) On Primary VM's monitor, issue command:
```
{'execute':'qmp_capabilities'}
{ 'execute': 'human-monitor-command',
  'arguments': {'command-line': 'drive_add -n buddy driver=replication,mode=primary,file.driver=nbd,file.host=10.22.1.3,file.port=8889,file.export=colo-disk0,node-name=node0'}}
{ 'execute':'x-blockdev-change', 'arguments':{'parent': 'colo-disk0', 'node': 'node0' } }
{ 'execute': 'migrate-set-capabilities',
      'arguments': {'capabilities': [ {'capability': 'x-colo', 'state': true } ] } }
{ 'execute': 'migrate', 'arguments': {'uri': 'tcp:10.22.1.3:8888' } }
```
- (4) Done
  - You will see two runing VMs, whenever you make changes to PVM, SVM will be synced.
