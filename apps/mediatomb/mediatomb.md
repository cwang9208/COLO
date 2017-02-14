
## Initial Installation
### First Time Launch

When starting MediaTomb for the first time, a .mediatomb directory will be created in your home. Further, a default server configuration file, called config.xml will be generated in that directory.

#### Using Sqlite Database

If you are using sqlite - you are ready to go, the database file will be created automatically and will be located ~/.mediatomb/mediatomb.db If needed you can adjust the database file name and location in the server configuration file.

## Command Line Options

### IP Address
```
--ip or -i
```
The server will bind to the given IP address.

### Port
```
--port or -p
```
Specify the server port that will be used for the web user interface, for serving media and for UPnP requests.

### Configuration File
```
--config or -c
```
By default MediaTomb will search for a file named "config.xml" in the ~/.mediatomb directory.

### Home Directory
```
--home or -m
```
Specify an alternative home directory. By default MediaTomb will try to retrieve the users home directory from the environment, then it will look for a .mediatomb directory in users home. If .mediatomb was found we will try to find the default configuration file (config.xml), if not found we will create both, the .mediatomb directory and the default config file.

### Add Content
```
--add or -a
```
Add the specified directory or file name to the database without UI interaction. 