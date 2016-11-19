# Install Xen with Remus and DRBD on Ubuntu 12.10

## Install a new Ubuntu 12.10 system

### Setting up apt-get to use a http-proxy
If you are behind a proxy server you have probably to set this commands to pass through.

#### Temporary proxy session
This is a temporary method that you can manually use each time you want to use apt-get through a http-proxy. This method is useful if you only want to temporarily use a http-proxy.
Enter this line in the terminal prior to using apt-get

```
export http_proxy=http://10.22.1.1:3128
```

#### APT configuration file method
This method uses the apt.conf file which is found in your /etc/apt/ directory. This method is useful if you only want apt-get (and not other applications) to use a http-proxy permanently.
On some installations there will be no apt-conf file set up. This procedure will either edit an existing apt-conf file or create a new apt-conf file.
```
gksudo gedit /etc/apt/apt.conf
```

Add this line to your /etc/apt/apt.conf file.

```
Acquire::http::Proxy "http://10.22.1.1:3128";
```

Save the apt.conf file.

#### BASH rc method
This method adds a two lines to your .bashrc file in your $HOME directory. This method is useful if you would like apt-get and other applications for instance wget, to use a http-proxy.
```
gedit ~/.bashrc
```

Add these lines to the bottom of your ~/.bashrc file
```
http_proxy=http://10.22.1.1:3128
export http_proxy
```

Save the file. Close your terminal window and then open another terminal window or source the ~/.bashrc file:
```
source ~/.bashrc
```

### Builing the Linux Kernel

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

### Install Xen

First, there are a number of prerequisites for building a Xen source release. Make sure you have all the following installed, either by visiting the project webpage or installing a pre-built package provided by your OS distributor:
* GCC v4.1 or later
* GNU Make
* GNU Binutils
* Development install of zlib (e.g., zlib-dev)
* Development install of Python v2.3 or later (e.g., python-dev)
* Development install of curses (e.g., libncurses-dev)
* Development install of openssl (e.g., openssl-dev)
* Development install of x11 (e.g. xorg-x11-dev)
* Development install of uuid (e.g. uuid-dev)
* Development install of yajl (e.g. libyajl-dev)
* Development install of libaio (e.g. libaio-dev) version 0.3.107 or greater.
* Development install of GLib v2.0 (e.g. libglib2.0-dev)
* Development install of Pixman (e.g. libpixman-1-dev)
* pkg-config
* bridge-utils package (/sbin/brctl)
* iproute package (/sbin/ip)
* GNU bison and GNU flex
* GNU gettext
* 16-bit x86 assembler, loader and compiler (dev86 rpm or bin86 & bcc debs)
* ACPI ASL compiler (iasl)

In addition to the above there are a number of optional build prerequisites. Omitting these will cause the related features to be disabled at compile time:
* Development install of Ocaml (e.g. ocaml-nox and ocaml-findlib). Required to build ocaml components which includes the alternative ocaml xenstored.
* cmake (if building vtpm stub domains)
* markdown
* figlet (for generating the traditional Xen start of day banner)
* systemd daemon development files
* Development install of libnl3 (e.g., libnl-3-200, libnl-3-dev, etc).  Required if network buffering is desired when using Remus with libxl. See docs /README.remus for detailed information.

Second, you need to acquire a suitable kernel for use in domain 0.

[NB. Unless noted otherwise, all the following steps should be performed with root privileges.]

1. Download and untar the source tarball file. This will be a file named xen-unstable-src.tgz, or xen-$version-src.tgz. You can also pull the current version from the git or mercurial repositories at http://xenbits.xen.org/
  ```
  tar xzf xen-unstable-src.tgz
  ```
  Assuming you are using the unstable tree, this will untar into xen-unstable. The rest of the instructions use the unstable tree as an example, substitute the version for unstable.

2. cd to xen-unstable (or whatever you sensibly rename it to).

3. For the very first build, or if you want to destroy build trees, perform the following steps:
  ```
  # if behind proxy, then enablt git over http for xen configure file.
  ./configure --enable-githttp
  make world
  make install
  ```
  See the documentation in the INSTALL file for more info.

  This will create and install onto the local machine. It will build the xen binary (xen.gz), the tools and the documentation.
