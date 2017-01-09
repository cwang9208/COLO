# COLO-proxy

## Architecture

![colo-proxy](https://github.com/wangchenghku/COLO/blob/master/.resources/colo-proxy.png)

- Filter mirror: copy and forward client's packets to SVM
- COLO compare: compare PVM's and SVM's net packets
- Filter rewriter: adjust tcp packets' ack and tcp packets' seq

COLO implements the per TCP connection response packet comparison, and considers the SVM as valid replica, if the response packets of each TCP connection from the PVM and SVM are identical.

## Components introduction
Filter-redirector is a netfilter plugin. It gives qemu the ability to redirect net packet. Redirector can redirect filter's net packet to outdev, and redirect indev's packet to filter.

## Usage
Secondary(ip:3.3.3.8):
```
-netdev tap,id=hn0,vhost=off,script=/etc/qemu-ifup,down script=/etc/qemu-ifdown
-device e1000,netdev=hn0,mac=52:a4:00:12:78:66
-chardev socket,id=red0,host=3.3.3.3,port=9003
-chardev socket,id=red1,host=3.3.3.3,port=9004
-object filter-redirector,id=f1,netdev=hn0,queue=tx,indev=red0
-object filter-redirector,id=f2,netdev=hn0,queue=rx,outdev=red1
```