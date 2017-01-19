# vlan

## Installation
```
sudo apt-get install vlan
```

## Configuration

1. Load the 8021q module into the kernel. 
```
sudo modprobe 8021q
```

2. Create a new interface that is a member of a specific VLAN, VLAN id 10 is used in this example. Keep in mind you can only use physical interfaces as a base, creating VLAN's on virtual interfaces (i.e. eth0:1) will not work. We use the physical interface eth0 in this example. This command will add an additional interface next to the interfaces which have been configured already, so your existing configuration of eth0 will not be affected.
```
sudo vconfig add eth0 10
```
3. Assign an address to the new interface.
```
sudo ip addr add 10.0.0.1/24 dev eth0.10
```
4. Starting the new interface.
```
sudo ip link set up eth0.10
```
