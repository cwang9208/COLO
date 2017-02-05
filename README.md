# How to setup/test COLO

## Test environment prepare
- Qemu colo
  - Checkout the latest COLO branch from [colo-v5.1-developing-COLO-frame-v21-with-shared-disk](https://github.com/coloft/qemu/tree/colo-v5.1-developing-COLO-frame-v21-with-shared-disk)
```
# cd qemu
# git checkout 'colo-v5.1-developing-COLO-frame-v21-with-shared-disk'
# ./configure --target-list=x86_64-softmmu --enable-colo --enable-gcrypt --enable-replication
# make -j
```

- Set Up the Bridge and network environment

- Qemu-ifup/Qemu-ifdown
  - We need a script to bring up the TAP interface. 
```
NOTE: Don't forget to change this script file permission to be executable

Primary:
root@master# cat /etc/qemu-ifup
#!/bin/sh
switch=br0
if [ -n "$1" ]; then
         ip link set $1 up
         brctl addif ${switch} $1
fi
root@master# cat /etc/qemu-ifdown
!/bin/sh
switch=br0
if [ -n "$1" ]; then
        brctl delif ${switch} $1
fi
Secondary:
like Primary side
```

- Create a virtual machine
```
# dd if=/dev/zero of=ubuntu-server.img bs=1M count=8192
# x86_64-softmmu/qemu-system-x86_64 -m 2048 -smp 2 -boot order=cd -hda ubuntu-server.img -cdrom ubuntu-14.04.1-server-amd64.iso
hkucs-PowerEdge-R430:~$ x86_64-softmmu/qemu-system-x86_64 -m 2048 -smp 2 -hda ubuntu-server.img -netdev tap,id=hn0,vhost=off,script=/etc/qemu-ifup,downscript=/etc/qemu-ifdown -device e1000,id=e0,netdev=hn0,mac=52:a4:00:12:78:66 -vnc :7
# vi /etc/network/interfaces
auto eth0
iface eth0 inet static
	address 10.22.1.11
	# post-up command
	# Run command after bringing the interface up.

# set up apt-get to use a http-proxy
# vi /etc/apt/apt.conf
Acquire::https::proxy "http://10.22.1.1:3128";

# if you would like apt-get and other applications for instance wget, to use a http-proxy.
# Add these lines to the bottom of your ~/.bashrc file
http_proxy=http://10.22.1.1:3128
export http_proxy

# Save the file. Source the ~/.bashrc file:
source ~/.bashrc
```

- NFS
```
hkucs-PowerEdge-R430-1:~$ vi /etc/exports
#
/ubuntu  *(rw,sync,no_root_squash)
#
hkucs-PowerEdge-R430-1:~$ service nfs-kernel-server restart
hkucs-PowerEdge-R430-2/3:~$ sudo mount 10.22.1.1:/ubuntu /local/ubuntu
```

## Test steps
**Note: Here the primary side host ip is 10.22.1.2, secondary side host ip is 10.22.1.3. Please change them according to your actual environment.**
- (1) Startup qemu
- *Primary side*
```
# x86_64-softmmu/qemu-system-x86_64 -enable-kvm -boot c -m 2048 -smp 2 -qmp stdio -vnc :7 -name primary -cpu qemu64,+kvmclock -device piix3-usb-uhci \
  -drive if=virtio,id=colo-disk0,driver=quorum,read-pattern=fifo,vote-threshold=1,children.0.file.filename=/local/ubuntu/ubuntu-server.img,children.0.driver=raw -S \
  -netdev tap,id=hn0,vhost=off,script=/etc/qemu-ifup,downscript=/etc/qemu-ifdown \
  -device e1000,id=e0,netdev=hn0,mac=52:a4:00:12:78:66 \
  -chardev socket,id=mirror0,host=10.22.1.2,port=9003,server,nowait -chardev socket,id=compare1,host=10.22.1.2,port=9004,server,nowait \
  -chardev socket,id=compare0,host=10.22.1.2,port=9001,server,nowait -chardev socket,id=compare0-0,host=10.22.1.2,port=9001 \
  -chardev socket,id=compare_out,host=10.22.1.2,port=9005,server,nowait \
  -chardev socket,id=compare_out0,host=10.22.1.2,port=9005 \
  -object filter-mirror,id=m0,netdev=hn0,queue=tx,outdev=mirror0 \
  -object filter-redirector,netdev=hn0,id=redire0,queue=rx,indev=compare_out -object filter-redirector,netdev=hn0,id=redire1,queue=rx,outdev=compare0 \
  -object colo-compare,id=comp0,primary_in=compare0-0,secondary_in=compare1,outdev=compare_out0
```
- *Secondary side*
```
# qemu-img create -f qcow2 /local/ubuntu/active_disk.img 8G

# qemu-img create -f qcow2 /local/ubuntu/hidden_disk.img 8G

# x86_64-softmmu/qemu-system-x86_64 -boot c -m 2048 -smp 2 -qmp stdio -vnc :7 -name secondary -enable-kvm -cpu qemu64,+kvmclock -device piix3-usb-uhci \
  -drive if=none,id=colo-disk0,file.filename=/local/ubuntu/ubuntu-server.img,driver=raw,node-name=node0 \
  -drive if=virtio,id=active-disk0,driver=replication,mode=secondary,file.driver=qcow2,top-id=active-disk0,file.file.filename=/local/ubuntu/active_disk.img,file.backing.driver=qcow2,file.backing.file.filename=/local/ubuntu/hidden_disk.img,file.backing.backing=colo-disk0  \
  -netdev tap,id=hn0,vhost=off,script=/etc/qemu-ifup,downscript=/etc/qemu-ifdown \
  -device e1000,netdev=hn0,mac=52:a4:00:12:78:66 -chardev socket,id=red0,host=10.22.1.2,port=9003 \
  -chardev socket,id=red1,host=10.22.1.2,port=9004 \
  -object filter-redirector,id=f1,netdev=hn0,queue=tx,indev=red0 \
  -object filter-redirector,id=f2,netdev=hn0,queue=rx,outdev=red1 \
  -object filter-rewriter,id=rew0,netdev=hn0,queue=all -incoming tcp:0:8888
```
- (2) On Secondary VM's monitor, issue command
```
{'execute':'qmp_capabilities'}
{ 'execute': 'nbd-server-start',
  'arguments': {'addr': {'type': 'inet', 'data': {'host': '10.22.1.3', 'port': '8889'} } }
}
{'execute': 'nbd-server-add', 'arguments': {'device': 'colo-disk0', 'writable': true } }
```
***Note:***  
*a. The qmp command nbd-server-start and nbd-server-add must be run before running the qmp command migrate on primary QEMU  
b. Active disk, hidden disk and nbd target's length should be the same.*

- (3) On Primary VM's monitor, issue command:
```
{'execute':'qmp_capabilities'}
{ 'execute': 'human-monitor-command',
  'arguments': {'command-line': 'drive_add -n buddy driver=replication,mode=primary,file.driver=nbd,file.host=10.22.1.3,file.port=8889,file.export=colo-disk0,node-name=node0'}}
{ 'execute':'x-blockdev-change', 'arguments':{'parent': 'colo-disk0', 'node': 'node0' } }
{ 'execute': 'migrate-set-capabilities',
      'arguments': {'capabilities': [ {'capability': 'x-colo', 'state': true } ] } }
{ 'execute': 'migrate', 'arguments': {'uri': 'tcp:10.22.1.3:8888' } }
```
- (4) Done
  - You will see two runing VMs, whenever you make changes to PVM, SVM will be synced.

## Evaluate COLO performance with PostgreSQL

### PostgreSQL Installation from Source Code

#### Short Version
```
./configure
make
su
make install
adduser postgres
mkdir /usr/local/pgsql/data
chown postgres /usr/local/pgsql/data
su - postgres
/usr/local/pgsql/bin/initdb -D /usr/local/pgsql/data
/usr/local/pgsql/bin/postgres -D /usr/local/pgsql/data >logfile 2>&1 &
/usr/local/pgsql/bin/createdb test
/usr/local/pgsql/bin/psql test
```
#### Requirements
The following software packages are required for building PostgreSQL:
* GNU make version 3.80 or newer is required; other make programs or older GNU make versions will **not** work. To test for GNU make enter: `make --version`
* You need an ISO/ANSI C compiler (at least C89-compliant). Recent versions of GCC are recommended, but PostgreSQL is known to build using a wide variety of compilers from different vendors.
* tar is required to unpack the source distribution, in addition to either gzip or bzip2.
* The GNU Readline library is used by default.
* The zlib compression library is used by default.

If you are building from a Git tree instead of using a released source package, or if you want to do server development, you also need the following packages:
* GNU Flex and Bison are needed to build from a Git checkout, or if you changed the actual scanner and parser definition files. If you need them, be sure to get Flex 2.5.31 or later and Bison 1.875 or later. Other lex and yacc programs cannot be used.

#### Install pgbench
pgbench is a simple program for running benchmark tests on PostgreSQL. By default, pgbench tests a scenario that is loosely based on TPC-B, involving five SELECT, UPDATE, and INSERT commands per transaction.
```
cd contrib/pgbench/
make
```

### Client Authentication
#### The pg_hba.conf File
Client authentication is controlled by a configuration file, which traditionally is named pg_hba.conf and is stored in the database cluster's data directory.
A record can have one of the seven formats
```
local      database  user  auth-method  [auth-options]
host       database  user  address  auth-method  [auth-options]
```
The meaning of the fields is as follows:
- local
   - This record matches connection attempts using Unix-domain sockets. Without a record of this type, Unix-domain socket connections are disallowed.
- host
   - This record matches connection attempts made using TCP/IP.
   - Note: If you want to allow non-local connections, you need to add more "host" records.  In that case you will also need to make PostgreSQL listen on a non-local interface via the `listen_addresses` configuration parameter, or via the `-i` or `-h` command line switches.

- ***database***
  - Specifies which database name(s) this record matches. The value all specifies that it matches all databases.
- ***user***
  - Specifies which database user name(s) this record matches. The value all specifies that it matches all users.
- ***address***
  - 0.0.0.0/0 represents all IPv4 addresses, and ::0/0 represents all IPv6 addresses.
- ***auth-method***
  - trust
    - Allow the connection unconditionally.

Example pg_hba.conf Entries
```
# Allow any user from any host with IP address 192.168.93.x to connect
# to database "postgres" as the same user name
#
# TYPE  DATABASE        USER            ADDRESS                 METHOD
host    postgres        all             192.168.93.0/24         ident
```

### Usage

/usr/local/pgsql/bin/initdb initializes a PostgreSQL database cluster.
```
Options:
 [-D, --pgdata=]DATADIR     location for this database cluster
```
/usr/local/pgsql/bin/postgres is the PostgreSQL server.
```
Options:
  -D DATADIR         database directory
  -h HOSTNAME        host name or IP address to listen on
```
/usr/local/pgsql/bin/createdb creates a PostgreSQL database.
```
Usage:
  createdb [OPTION]... [DBNAME] [DESCRIPTION]

Connection options:
  -h, --host=HOSTNAME          database server host or socket directory
  -U, --username=USERNAME      user name to connect as
```

pgbench is a benchmarking tool for PostgreSQL.
```
Usage:
  pgbench [OPTION]... [DBNAME]

Initialization options:
  -i, --initialize         invokes initialization mode

Benchmarking options:
  -c, --client=NUM         number of concurrent database clients (default: 1)
  -t, --transactions=NUM   number of transactions each client runs (default: 10)

Common options:
  -h, --host=HOSTNAME      database server host or socket directory
  -U, --username=USERNAME  connect as specified database user
```
Before we start the benchmark, we have to initialize the database, which can be done by using the `-i` flag.
```
./pgbench -i pgbench
```

Let's perform a test:
```
./pgbench pgbench -c 20 -t 100
```
