echo "{'execute':'qmp_capabilities'}
{'execute': 'human-monitor-command', 'arguments': {'command-line': 'drive_add -n buddy driver=replication,mode=primary,file.driver=nbd,file.host=3.3.3.8,file.port=8889,file.export=colo-disk0,node-name=node0'}}
{'execute':'x-blockdev-change', 'arguments':{'parent': 'colo-disk0', 'node': 'node0' } }
{'execute': 'migrate-set-capabilities', 'arguments': {'capabilities': [ {'capability': 'x-colo', 'state': true } ] } }
{'execute': 'migrate', 'arguments': {'uri': 'tcp:3.3.3.8:8888' } }"
echo "{'execute': 'trace-event-set-state', 'arguments': {'name': 'colo*', 'enable': true} }"

disk_path=/home/cheng/ubuntu14.04.raw

net_param="-netdev tap,id=hn0,vhost=off,script=/etc/qemu-ifup,downscript=/etc/qemu-ifdown -device e1000,id=e0,netdev=hn0 -chardev socket,id=mirror0,host=3.3.3.3,port=9003,server,nowait -chardev socket,id=compare1,host=3.3.3.3,port=9004,server,nowait -chardev socket,id=compare0,host=3.3.3.3,port=9001,server,nowait -chardev socket,id=compare0-0,host=3.3.3.3,port=9001 -chardev socket,id=compare_out,host=3.3.3.3,port=9005,server,nowait -chardev socket,id=compare_out0,host=3.3.3.3,port=9005 -object filter-mirror,id=m0,netdev=hn0,queue=tx,outdev=mirror0 -object filter-redirector,netdev=hn0,id=redire0,queue=rx,indev=compare_out -object filter-redirector,netdev=hn0,id=redire1,queue=rx,outdev=compare0 -object colo-compare,id=comp0,primary_in=compare0-0,secondary_in=compare1,outdev=compare_out0"


cmdline="x86_64-softmmu/qemu-system-x86_64 -enable-kvm -boot c -m 2048 -smp 2 -qmp stdio -vnc :7 -name primary -cpu qemu64,+kvmclock -device piix3-usb-uhci -device usb-tablet $net_param -drive if=virtio,id=colo-disk0,driver=quorum,read-pattern=fifo,vote-threshold=1,children.0.file.filename=$disk_path,children.0.driver=raw -S"

#x86_64-softmmu/qemu-system-x86_64 -enable-kvm -boot c -m 2048 -smp 2 -qmp stdio -vnc :7 -name primary -cpu qemu64,+kvmclock -device piix3-usb-uhci -device usb-tablet -netdev tap,id=hn0,vhost=off,script=/etc/qemu-ifup,downscript=/etc/qemu-ifdown -device e1000,id=e0,netdev=hn0,mac=52:a4:00:12:78:66 -drive if=virtio,id=colo-disk0,driver=quorum,read-pattern=fifo,vote-threshold=1,children.0.file.filename=/sda4/vdisk.raw,children.0.driver=raw

#exec $cmdline

gdb --args $cmdline
