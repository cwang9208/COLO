# Proxy Design (Userspace scheme)

![colo-proxy](https://github.com/wangchenghku/COLO/blob/master/.resources/colo-proxy.png)

- Filter mirror: copy and forward client's packets to SVM
- COLO compare: compare PVM's and SVM's net packets
- Filter rewriter: adjust tcp packets' ack and tcp packets' seq

COLO implements the per TCP connection response packet comparison, and considers the SVM as valid replica, if the response packets of each TCP connection from the PVM and SVM are identical.