## Nginx with PHP
Nginx uses a fastcgi backend to communicate with fastcgi servers. Therefore, we install the php5 FPM server for nginx to pass php files onto.
```
sudo apt-get install php5-fpm
```
The default nginx configuration that comes with Ubuntu already contains the configuration for php-fpm. Simply remove the comments on the php block so that
```
server {

        root /usr/share/nginx/html;

        # pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000
        #
        #location ~ \.php$ {
        #       fastcgi_split_path_info ^(.+\.php)(/.+)$;
        #        # NOTE: You should have "cgi.fix_pathinfo = 0;" in php.ini
        #
        #        # With php5-cgi alone:
        #       fastcgi_pass 127.0.0.1:9000;
        #        # With php5-fpm:
        #       fastcgi_pass unix:/var/run/php5-fpm.sock;
        #       fastcgi_index index.php;
        #        include fastcgi_params;
        #}

}
```
looks like
```
        # pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000
        #
        location ~ \.php$ {
                fastcgi_split_path_info ^(.+\.php)(/.+)$;
        #        # NOTE: You should have "cgi.fix_pathinfo = 0;" in php.ini
        #
        #        # With php5-cgi alone:
        #       fastcgi_pass 127.0.0.1:9000;
                # With php5-fpm:
                fastcgi_pass unix:/var/run/php5-fpm.sock;
                fastcgi_index index.php;
                include fastcgi_params;
        }
```