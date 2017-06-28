## KVM Virtual Networking

### Sockets
Sockets can be used to connect together VLANs from multiple QEMU processes. The way this works is that one QEMU process connects to a socket in another process. When data appears on the VLAN in the first QEMU process, it is forwarded to the corresponding VLAN in the other QEMU process, and vice versa.
```
 +------------+                                      +------------+
 |   Guest A  |                                      |   Guest B  |
 |            |                                      |            |
 |   +----+   |                                      |   +----+   |
 |   |vNIC|   |                                      |   |vNIC|   |
 +------------+                                      +------------+
       ^        +--------+                +--------+        ^
       |        |        |                |        |        |
       +------->+ VLAN 1 +<--> Socket <-->+ VLAN 2 +<-------+
                |        |                |        |
                +--------+                +--------+
```
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
```
                                                    +-------+
                                                    |  TAP  |
                                                    | Device|
                                                    |(QTAP0)|
                                                    +---+---+
 +-------------+                                        |
 |   Guest OS  |        +------+                    +---+-----+
 |             |        |      |                    | Kernel  |
 |   +----+    |<------>+ VLAN +<-->   File    <--->+ TUN/TAP |      
 |   |vNIC|    |        |      |     Descriptor     | Driver  |
 +-------------+        +------+                    +---------+
```
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
