Overview
--------

Mongoose is small and easy to use web server.

On UNIX, mongoose is a command line utility. Running `mongoose` in
terminal, optionally followed by configuration parameters
(`mongoose [OPTIONS]`) or configuration file name
(`mongoose [config_file_name]`) starts the
web server. Mongoose does not detach from terminal. Pressing `Ctrl-C` keys
would stop the server.

When started, mongoose first searches for the configuration file.
If configuration file is specified explicitly in the command line, i.e.
`mongoose path_to_config_file`, then specified configuration file is used.
Otherwise, mongoose would search for file `mongoose.conf` in the same directory
where binary is located, and use it.
Configuration file is a sequence of lines, each line containing
command line argument name and it's value. Empty lines, and lines beginning
with `#`, are ignored. Here is the example of `mongoose.conf` file:

    # mongoose.conf file
    document_root c:\www
    listening_ports 8080,8043s

When configuration file is processed, mongoose process command line arguments,
if they are specified. Command line arguments therefore can override
configuration file settings. Command line arguments must start with `-`.
For example, if `mongoose.conf` has line
`document_root /var/www`, and mongoose has been started as
`mongoose -document_root /etc`, then `/etc` directory will be served as
document root, because command line options take priority over
configuration file.

Command Line Options
--------------------
```

     -C cgi_pattern
         All files that fully match cgi_pattern are treated as CGI.
         Default: "**.cgi$|**.pl$|**.php$"

     -I cgi_interpreter
         Use cgi_interpreter as a CGI interpreter for all CGI scripts
         regardless script extension.  Mongoose decides which interpreter
         to use by looking at the first line of a CGI script.

     -a access_log_file
         Access log file. Default: "", no logging is done.

     -e error_log_file
         Error log file. Default: "", no errors are logged.

     -p listening_ports
         Comma-separated list of ports to listen on. Default: "8080"

     -r document_root
         Location of the WWW root directory. Default: "."

     -t num_threads
         Number of worker threads to start. Default: "10"

```