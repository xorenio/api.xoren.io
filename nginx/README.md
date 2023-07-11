*.pem# Nginx

This Docker image is built on top of the nginx:alpine Docker image. It includes the docker.sh file, which is executed during runtime.


## Docker environment variables


| Name | Default | Description |
| -------- | -------- | -------- |
| SWOOLE_PORT | 8000 | Specifies the port used by Laravel Swoole to the Nginx image. |
| NGINX_BLOCK_BOTS | 0 | Enables the bots blocking script in Nginx. |
| NGINX_BLOCK_SCANNERS | 0 | Enables the scanners blocking script in Nginx. |
| TZ | Europe/London | Sets the POSIX time zone for the system. |
| TZENCODE | en_GB | Defines the locale encoding setting. |
| LANG | en_GB.UTF-8 | Defines the default language and character encoding. |
| LANGUAGE | en_GB.UTF-8 | Defines the preferred language and character encoding. |
| LC_ALL | en_GB.UTF-8 | Sets the locale for all aspects of the system. |


## Nginx Conf.d

The `conf.d/api.conf` file handles incoming requests and determines where they should be routed. It manages the routing of requests to Laravel, the websocket server, or a file.

On the other hand, the `conf.d/default.conf` file is a file that you can use to overwrite the existing default configuration file in the same location. By replacing the default.conf file, you can ensure that it does not interfere with your custom configuration settings and allows you to have full control over the Nginx configuration for your specific needs.


## Nginx Snippets

The `snippets/common.conf` file contains common Nginx server configurations that are shared across different server blocks.

The `snippets/locations.conf` file includes the location blocks that define how Nginx handles requests for specific URLs or paths.

the `snippets/ssl.conf` file contains SSL-related settings and configurations


## Nginx Blocking

Blocking configs are sourced from https://www.knthost.com/nginx/nginx-reverse-proxy-setup-freebsd