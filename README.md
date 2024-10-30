# rproxy-ssl-apache
a reverse proxy with ssl support for goobi workflow and viewer, based on apache

## configuration
### general
* via env vars
* use ENABLE_XY=1 plus XY=foo or XY_SETTING=bar
* because setting vars to empty strings in docker-compose.yml doesn't seem to set the var, which makes entrypoints difficult to write in bash
### include structure
#### ssl enabled case
* httpd.conf
  * http_vhost.conf
    * https_redir.conf
  * https_vhost.conf
    * goobi-common.conf
      * viewer.conf
      * workflow.conf

#### ssl disabled case
* httpd.conf
  * http_vhost.conf
    * goobi-common.conf
      * viewer.conf
      * workflow.conf
