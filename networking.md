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

## KVM Virtual Networking

### Sockets
Sockets can be used to connect together VLANs from multiple QEMU processes. The way this works is that one QEMU process connects to a socket in another process. When data appears on the VLAN in the first QEMU process, it is forwarded to the corresponding VLAN in the other QEMU process, and vice versa.
For example, you might start Guest A with
```
qemu -net nic -net socket, listen=:8010...

-net nic,[vlan=n][,macaddr=mac]
Create a new Network Interface Card and connect it to VLAN n (n = 0 is the default). Optionally, the MAC can be changed to mac.
```
This QEMU process is hosting a guest with an NIC connected to VLAN 0, which in turn has a socket interface listening for connections on port 8010.

You could start Guest B with
```
qemu -net nic,vlan=2 -net socket,vlan=2,connect=127.0.0.1:8010...
```
This QEMU process would then have a guest with an NIC connected to VLAN 2, which in turn has a socket interface connected to VLAN 0, in the first QEMU process. Thus any data transmitted by Guest A is received by Guest B, and vice versa.

### TAP interfaces
A VLAN can be made available through a TAP device in the host OS. Any data transmitted through this device will appear on a VLAN in the QEMU process and thus be received by other interfaces on the VLAN and data sent to the VLAN will be received by the TAP device.
This works using the kernel's TUN/TAP device driver. This driver basically allows a users-space application to obtain a file descriptor, which is connected to a network device.

- What is the TUN ?

  The TUN is Virtual Point-to-Point network device. TUN driver was designed as low level kernel support for IP tunneling. It provides to userland application two interfaces:
    1. /dev/tunX	- character device;
    2. tunX	- virtual Point-to-Point interface.

  Userland application can write IP frame to /dev/tunX and kernel will receive this frame from tunX interface. In the same time every frame that kernel writes to tunX interface can be read by userland application from /dev/tunX device.

- What is the TAP ?

  The TAP is a Virtual Ethernet network device. TAP driver was designed as low level kernel support for Ethernet tunneling. It provides to userland application two interfaces:
    1. /dev/tapX	- character device;
    2. tapX	- virtual Ethernet interface.

  Userland application can write Ethernet frame to /dev/tapX and kernel will receive this frame from tapX interface. In the same time every frame that kernel writes to tapX interface can be read by userland application from /dev/tapX device.

- What is the difference between TUN driver and TAP driver?

  TUN works with IP frames. TAP works with Ethernet frames.

```
-net tap[,vlan=n][,ifname=name][,script=file][,downscript=dfile]
```
Connect the host TAP network interface *name* to VLAN n.

Use the network script *file* to configure it and the networking script *dfile* to deconfigure it. If *name* is not provided, the OS automatically provides one. The default configure script is /etc/qemu-ifup and the default network deconfigure script is /etc/qemu-ifdown.

## Data Link Layer
### How LANs work
#### LAN Addresses
LAN (or MAC or physical) address:
- 48 bit MAC address (for most LANs) burned in the adapter ROM  
- E.g. 20:30:65:25:5a:93

### The ARP protocol
#### ARP: Address Resolution Protocol
- Each IP node (Host, Router) on LAN has ARP module, table
- ARP Table: IP/MAC address mappings for some LAN nodes
 
#### ARP protocol: in one LAN
- A knows B’s IP address, want to learn physical address of B
- A broadcast ARP query pkt, containing B’s IP address
  - All machines on LAN receive ARP query
- B receives ARP packet, replies to A with its (B’s) physical layer address

#### Routing to another LAN
- A creates IP packet with source A, destination B
- Routing: A finds that R is next hop
- A uses ARP to get R’s physical layer address for 111.111.111.110
- A creates Ethernet frame with
  - R’s physical address as dest
  - A, B IP datagram
- A's data link layer sends Ethernet frame
- R's data link layer receives Ethernet frame
- R removes IP datagram from Ethernet frame, sees its destined to B
- R uses ARP to get B’s physical layer address
- R creates frame containing A-to-B IP datagram sends to B

### Interconnecting LANs
#### bridges
- Bridges learn which hosts can be reached through which interfaces: maintain filtering tables
  - when frame received, bridge "learns" location of the sender: incoming LAN segment
  - records sender location in filtering table

- Filtering table entry:
  - (Node LAN Address, Bridge interface, Time Stamp)