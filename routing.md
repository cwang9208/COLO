## Basic IP Routing
![routing](https://github.com/wangchenghku/COLO/blob/master/.resources/routing.png)
Device C is acting as a router between these two networks. A router is a device that chooses different paths for the network packets, based on the addressing of the IP frame it is handling. Different routes connect to different different networks. The router will have more than one address as each route is part of a different network.

### Direct vs. Indirect Routing

Direct routing was observed in the first example when A communicated with C. It is also used in the last example for A to communicate with C. If the packet does not need to be forwarded, i.e. both the source and destination addresses have the same network number, direct routing is used.

Indirect routing is used when the network numbers of the source and destination do not match. This is the case where the packet must be forwarded by a node that knows how to reach the destination (a router).

In the last example, A wanted to send a packet to E. For A to know how to reach E, it must be given routing information that tells it who to send the packet to in oder to reach E. This special node is the "gateway" or router between the two networks. A Unix-style method for adding a routing entry to A is
```
route add [destination_ip] [gateway]
```
In this case,
```
route add 200.1.3.2 200.1.2.3.1
```
will tell A to use C as the gateway to reach E.

In most case it will not be necessary to manually add this routing entry. It would normally be sufficient to set up C as the default gateway for all other nodes on both networks. The default gateway is the IP address of the machine to send all packets to that are not destined to a node on the directly-connected network.

## Advanced IP Routing
### The Netmask

For each entry in a routing table, perform a bit-wise logical AND between the destination IP address and the network mask. Compare the result with the Destination of the entry for a match.

```
# route -n
# don't resolve names

Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
0.0.0.0         202.45.128.1    0.0.0.0         UG    0      0        0 br0
10.21.1.0       0.0.0.0         255.255.255.0   U     1      0        0 eth5
10.22.1.0       0.0.0.0         255.255.255.0   U     0      0        0 eth4
169.254.0.0     0.0.0.0         255.255.0.0     U     1000   0        0 eth4
202.45.128.0    0.0.0.0         255.255.255.0   U     0      0        0 br0
```
The IFace column, is the network interface that the packets utilizing this route should use.