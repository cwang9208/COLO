### Server Configuration
File postgresql.conf is read on server startup and when the server receives a SIGHUP signal.
```
listen_addresses = 'localhost'		# what IP address(es) to listen on;
					# defaults to 'localhost'; use '*' for all
max_connections = 100
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
   - Note: Remote TCP/IP connections will not be possible unless the server is started with an appropriate value for the `listen_addresses` configuration parameter, since the default behavior is to listen for TCP/IP connections only on the local loopback address localhost.

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
