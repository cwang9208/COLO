echo "{'execute':'qmp_capabilities'}
{'execute': 'nbd-server-start', 'arguments': {'addr': {'type': 'inet', 'data': {'host': '3.3.3.8', 'port': '8889'} } } }
{'execute': 'nbd-server-add', 'arguments': {'device': 'colo-disk0', 'writable': true } }
{'execute': 'trace-event-set-state', 'arguments': {'name': 'colo*', 'enable': true} }"

disk_path=/home/cheng/ubuntu14.04.raw,driver=raw

net_param="-netdev tap,id=hn0,vhost=off,script=/etc/qemu-ifup,downscript=/etc/qemu-ifdown -device e1000,netdev=hn0 -chardev socket,id=red0,host=3.3.3.3,port=9003,reconnect=1 -chardev socket,id=red1,host=3.3.3.3,port=9004,reconnect=1 -object filter-redirector,id=f1,netdev=hn0,queue=tx,indev=red0 -object filter-redirector,id=f2,netdev=hn0,queue=rx,outdev=red1 -object filter-rewriter,id=rew0,netdev=hn0,queue=all"

#net_param="-netdev tap,id=hn0,vhost=off,script=/etc/qemu-ifup,downscript=/etc/qemu-ifdown -device e1000,netdev=hn0,mac=52:a4:00:12:78:66 -chardev socket,id=red0,host=3.3.3.3,port=9003,reconnect=1 -chardev socket,id=red1,host=3.3.3.3,port=9004,reconnect=1 -object filter-redirector,id=f1,netdev=hn0,queue=tx,indev=red0 -object filter-redirector,id=f2,netdev=hn0,queue=rx,outdev=red1"

cmdline="x86_64-softmmu/qemu-system-x86_64 -boot c -m 2048 -smp 2 -qmp stdio -vnc :7 -name secondary -enable-kvm -cpu qemu64,+kvmclock -device piix3-usb-uhci -device usb-tablet $net_param -drive if=none,id=colo-disk0,file.filename=$disk_path,node-name=node0 -drive if=virtio,id=active-disk0,driver=replication,mode=secondary,file.driver=qcow2,top-id=active-disk0,file.file.filename=/mnt/ramfs/active_disk.img,file.backing.driver=qcow2,file.backing.file.filename=/mnt/ramfs/hidden_disk.img,file.backing.backing=colo-disk0 -incoming tcp:0:8888"

#exec $cmdline
gdb --args $cmdline
