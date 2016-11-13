# Install Xen with Remus and DRBD on Ubuntu 14.04

## Install a new Ubuntu 14.04 system

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