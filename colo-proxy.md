# COLO-proxy

## Architecture

![colo-proxy](https://github.com/wangchenghku/COLO/blob/master/.resources/colo-proxy.png)

- Filter mirror: copy and forward client's packets to SVM
- COLO compare: compare PVM's and SVM's net packets
- Filter rewriter: adjust tcp packets' ack and tcp packets' seq

COLO implements the per TCP connection response packet comparison, and considers the SVM as valid replica, if the response packets of each TCP connection from the PVM and SVM are identical.

### Guest send packet route

Secondary:

Guest --> TCP Rewriter Filter  
If the packet is TCP packet,we will adjust seq and update TCP checksum. Then send it to redirect client filter. Otherwise directly send to redirect client filter.

Redirect Client Filter --> Redirect Server Filter  
Forward packet to primary.

## Components introduction
Filter-redirector is a netfilter plugin. It gives qemu the ability to redirect net packet. Redirector can redirect filter's net packet to outdev, and redirect indev's packet to filter.

## Usage

```
-chrdev socket ,id=id [TCP options or unix options] [,server] [,nowait]
	server specifies that the socket shall be a listening socket.
	nowait specifies that QEMU should not block waiting for a client to connect to a listening socket.

-object filter-redirector,id=id,netdev=netdevid,indev=chardevid,outdev=chardevid[,queue=all|rx|tx]

    queue all|rx|tx is an option that can be applied to any netfilter.
    tx: the filter is attached to the transmit queue of the netdev, where it will receive packets sent by the netdev.
    Note: On receiving a packet, QEMU calls tap_send.

    filter-redirector on netdev netdevid,redirect filter’s net packet to chardev chardevid,and redirect indev’s packet to filter.

Primary(ip:10.22.1.2):
-netdev tap,id=hn0,vhost=off,script=/etc/qemu-ifup,downscript=/etc/qemu-ifdown
-device e1000,id=e0,netdev=hn0,mac=52:a4:00:12:78:66
-chardev socket,id=mirror0,host=10.22.1.2,port=9003,server,nowait
-object filter-mirror,id=m0,netdev=hn0,queue=tx,outdev=mirror0

Secondary(ip:10.22.1.3):
-netdev tap,id=hn0,vhost=off,script=/etc/qemu-ifup,downscript=/etc/qemu-ifdown
-device e1000,netdev=hn0,mac=52:a4:00:12:78:66
-chardev socket,id=red0,host=10.22.1.2,port=9003
-object filter-redirector,id=f1,netdev=hn0,queue=tx,indev=red0
```

Note:

1. Primary COLO must be started firstly, because COLO-proxy needs chardev socket server running before secondary started.
