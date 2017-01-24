# Subnet Masking and Routing

The Class B address 131.5.252.19 is part of a subnet where the first 23 bits form the subnet address and the last 9 bits form the host address. What is the subnet mask? Answer:
```
  							   Binary 					Dotted Decimal
Address 		10000011.00000101.11111100.00010011 	131.5.252.19
Subnet Mask 	11111111.11111111.11111110.00000000 	255.255.254.0
Subnet Address 	10000011.00000101.11111100.00000000 	131.5.252.0
```
How many host addresses are there on the subnet? Answer: 2^9 = 512.

What is the range of host addresses for this subnet. Ans: The bits in the address that correspond to a 1 in the subnet mask are fixed, but the bits in the address that correspond to a 0 in the subnet mask are free to vary. The smallest possible value is to make all the bits that are free to vary 0. The largest value is to make all the bits that are free to vary 1. Hence the smallest value is 10000011.00000101.11111100.00000000 = 131.5.252.0

and the largest value is 10000011.00000101.11111101.11111111 = 131.5.253.255

```
NAME
       route - show / manipulate the IP routing table

OPTIONS
       -n     show numerical addresses instead of trying to determine symbolic
              host  names.  This  is useful if you are trying to determine why
              the route to your nameserver has vanished.


Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
default         cisco3560x-202. 0.0.0.0         UG    0      0        0 eth0
10.0.0.0        *               255.0.0.0       U     0      0        0 br0
link-local      *               255.255.0.0     U     1000   0        0 br0
202.45.128.0    *               255.255.255.0   U     1      0        0 eth0
```
The IFace column, is the network interface that the packets utilizing this route should use.