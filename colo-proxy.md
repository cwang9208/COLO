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

```
-object filter-redirector,id=id,netdev=netdevid,indev=chardevid,outdev=chardevid[,queue=all|rx|tx]

    queue all|rx|tx is an option that can be applied to any netfilter.
    rx: the filter is attached to the receive queue of the netdev, where it will receive packets sent to the netdev.
    tx: the filter is attached to the transmit queue of the netdev, where it will receive packets sent by the netdev.

    filter-redirector on netdev netdevid,redirect filter’s net packet to chardev chardevid,and redirect indev’s packet to filter.
```