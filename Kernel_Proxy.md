## How to setup/test COLO

### Test environment prepare

- Prepare host kernel

  colo-proxy kernel module need cooperate with linux kernel.
  
  You should patch colo-patch-for-kernel.patch into kernel codes,

  then compile kernel and intall the new kernel (Recommend kernel-3.18.10)

```
# patch -p1 < 0001-colo-patch-for-kernel.patch

# make menuconfig
# make
# make modules_install install
```
- Proxy module
  - proxy module is used for network packets compare.
```
# git clone https://github.com/coloft/colo-proxy.git
# cd ./colo-proxy
# make
# make install
```
- Modified iptables
  - We have add a new rule to iptables command.
```
# git clone https://github.com/coloft/iptables.git
# cd ./iptables
# git checkout colo
# ./autogen.sh && ./configure
# make && make install
```
- Modified arptables
  - Please get the latest arptables and then compile and install

- Qemu colo
  - Checkout the latest colo branch from colo-v1.5-basic or
    - colo-v1.5-developing(More features)

```
# cd qemu
# ./configure --target-list=x86_64-softmmu --enable-colo
# make
```
