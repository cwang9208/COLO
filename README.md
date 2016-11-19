# Install Xen with Remus and DRBD on Ubuntu 12.10

## Install a new Ubuntu 12.10 system
Both Servers 
```
Choose 'Use entire disk with LVM'
```

Network setup
```
sudo apt-get install bridge-utils
sudo vi /etc/network/interfaces
#
auto xenbr0
iface xenbr0 inet dhcp
bridge_ports eth0

auto eth0
iface eth0 inet manual
#
```

```
vi /etc/hosts
#
147.8.177.50 cheng-HP-Compaq-Elite-8300-SFF
147.8.179.243 wang-HP-Compaq-Elite-8300-SFF
#
```

## Builing the Linux Kernel
#### Download
```
git clone git://git.kernel.org/pub/scm/linux/kernel/git/jeremy/xen.git linux-2.6-xen
cd linux-2.6-xen
git checkout -b xen/next-2.6.32 origin/xen/next-2.6.32
```

#### Configure 
From the build directory configure the Kernel your are going to build using one of:
```
make menuconfig
```
![configure kernel](https://github.com/wangchenghku/Remus/blob/master/.resources/config%20kernel.png)

#### Build

Now compile the Kernel using:
```
make
``` 
Now two things will happen. The kernel will be built, and the modules will be built.

#### Installation
Install the Kernel Modules
```
make modules_install
```
Install the new Kernel onto the system using:
```
make install
```
The `make install` command also executes a `update-grub` command which will make the grub aware of the new kernel image available.

Building and Installation
![lspci](https://github.com/wangchenghku/Remus/blob/master/.resources/lspic.png)

1. Move the base driver tar file to the directory of your choice. For example, use '/home/username/e1000e' or '/usr/local/src/e1000e'.

2. Untar/unzip the archive, where <x.x.x> is the version number for the driver tar file:
   tar zxf e1000e-<x.x.x>.tar.gz

3. Change to the driver src directory, where <x.x.x> is the version number for the driver tar:
   cd e1000e-<x.x.x>/src/

4. Compile the driver module:
   ```
   make install
   ```
   The binary will be installed as:
   /lib/modules/<KERNEL VERSION>/updates/drivers/net/ethernet/intel/e1000e/e1000e.ko

   The install location listed above is the default location. This may differ for various Linux distributions.

5. Load the module using the modprobe command:
   ```
   modprobe <e1000e> [parameter=port1_value,port2_value]
   ```

   Make sure that any older e1000e drivers are removed from the kernel before loading the new module:
   ```
   rmmod e1000e; modprobe e1000e
   ```

## Install Xen

There are a number of prerequisites for building a Xen source release. Make sure you have all the following installed, either by visiting the project webpage or installing a pre-built package provided by your OS distributor:
* GCC v3.4 or later
* GNU Make
* GNU Binutils
* Development install of zlib (e.g., zlib-dev)
* Development install of Python v2.3 or later (e.g., python-dev)
* Development install of curses (e.g., libncurses-dev)
* Development install of openssl (e.g., openssl-dev)
* Development install of x11 (e.g. xorg-x11-dev)
* Development install of uuid (e.g. uuid-dev)
* bridge-utils package (/sbin/brctl)
* iproute package (/sbin/ip)
* hotplug or udev
* GNU bison and GNU flex
* GNU gettext
* 16-bit x86 assembler, loader and compiler (dev86 rpm or bin86 & bcc debs)
* ACPI ASL compiler (iasl)

Make sure that "hgext.mq=" is uncommented in /etc/mercurial/hgrc.d/hgext.rc
```
cd /usr/src
hg clone -r RELEASE-4.1.2 http://xenbits.xen.org/xen-4.1-testing.hg xen-4.1.2
```
Apply the following set of patches:

1. 01_remus_compression.patch - adds checkpoint compression functionality (also available in upstream xen i.e xen unstable)
2. 02_persistent_bitmap.patch - creates a permanent mapping of the PV guest in xc_domain_save, instead of mapping/unmapping in batches of 4MB. This patch will have no effect on HVMs.
3. 03_config_fixups.patch
4. 04_stats_fix.patch - pretty printing of remus checkpoint stats for post processing and analysis
5. 05_timeouts.patch - increases the failure detection timeout. Once your installation is stable, please adjust the timeout values in this patch according to your needs.
6. 06_qdisc_3.4_fix.patch - This patch enables support for sch_plug modules when using 3.4+ dom0 kernels.

```
wget http://remusha.wikidot.com/local--files/configuring-and-installing-remus/01_remus_compression.patch -O /tmp/01_remus_compression.patch
wget http://remusha.wikidot.com/local--files/configuring-and-installing-remus/02_persistent_bitmap.patch -O /tmp/02_persistent_bitmap.patch
wget http://remusha.wikidot.com/local--files/configuring-and-installing-remus/03_config_fixups.patch -O /tmp/03_config_fixups.patch
wget http://remusha.wikidot.com/local--files/configuring-and-installing-remus/04_stats_fix.patch -O /tmp/04_stats_fix.patch
wget http://remusha.wikidot.com/local--files/configuring-and-installing-remus/05_timeouts.patch -O /tmp/05_timeouts.patch
wget http://remusha.wikidot.com/local--files/configuring-and-installing-remus/06_qdisc_3.4_fix.patch -O /tmp/06_qdisc_3.4_fix.patch

###NOTE: Make sure "hgext.mq=" line is uncommented in /etc/mercurial/hgrc.d/hgext.rc else the following commands wont work.
cd /usr/src/xen-4.1.2
hg qinit
hg qimport /tmp/01_remus_compression.patch
hg qpush
hg qimport /tmp/02_persistent_bitmap.patch
hg qpush
hg qimport /tmp/03_config_fixups.patch
hg qpush
hg qimport /tmp/04_stats_fix.patch
hg qpush
hg qimport /tmp/05_timeouts.patch
hg qpush
hg qimport /tmp/06_qdisc_3.4_fix.patch
hg qpush

make clean
make install-xen
make tools
```

Once you have done "make tools", you should be having a tools/ioemu-remote directory that contains the qemu device model code, to be used for HVM domUs. The qemu device model code currently does not handle drbd disk backed HVM domUs properly. Apply the following patch drbd-hvm-fix. 
```
cd /usr/src/xen-4.1.2/tools/qemu-xen-traditional-dir-remote
wget http://remusha.wikidot.com/local--files/configuring-and-installing-remus/drbd-hvm-fix
patch -p1 <drbd-hvm-fix
cd /usr/src/xen-4.1.2
make install-tools

update-grub2
```

Fix init.d scripts to start xend daemon on boot
```
update-rc.d xencommons defaults 19 18
update-rc.d xend defaults 20 21
update-rc.d xendomains defaults 21 20

reboot
```

##Install DRBD
Server #1
```
apt-get install autoconf build-essential
wget http://remusha.wikidot.com/local--files/configuring-and-installing-remus/drbd-8.3.11-remus.tar.gz
cd ./drbd-8.3.11
./autogen.sh
./configure --prefix=/usr --localstatedir=/var --sysconfdir=/etc --with-km
make
make install
cd drbd
make clean all
make install
vi /etc/modules
# add drbd
#
tar zcvf drbd.tgz ./drbd-8.3.11
# scp to the other machine
```

Server #2
```
tar zxvf ./drbd.tgz
cd ./drbd-8.3.11
make install
cd drbd
make install
vi /etc/modules
# add drbd
#
```

Both Servers
![lvreduce](https://github.com/wangchenghku/Remus/blob/master/.resources/lvreduce.png)
```
cp /home/user/drbd-8.3.11/scripts/global_common.conf.protoD /etc/drbd.d/global_common.conf
cp /home/user/drbd-8.3.11/scripts/testvms_protoD.res /etc/drbd.d/SystemHA_protoD.res
lvcreate -n drbdtest -L 10G ubuntu
vi /etc/drbd.d/SystemHA_protoD.res
#
resource drbd-vm {
        device /dev/drbd1;
        disk /dev/ubuntu/drbdtest;
        meta-disk internal;
        on cheng-HP-Compaq-Elite-8300-SFF {
                address 147.8.177.50:7791;
        }
        on wang-HP-Compaq-Elite-8300-SFF {
                address 147.8.179.243:7791;
        }
}
#

#Create the meta-data for the SystemHA-disk and then bring up the resource. Do this on both machines
drbdadm create-md drbd-vm
###answer y or yes for all questions, in the above command
drbdadm up drbd-vm

###Sanity check. You should see something like this in the output
```

Server #1 - this will override all of the DRBD data on server #2
```
drbdadm -- --overwrite-data-of-peer primary drbd-vm
```

Watch the progress of the transfer (either server)
```
cat /proc/drbd
```
