# rproxy-ssl-apache
a reverse proxy with ssl support for goobi workflow and viewer, based on apache

## configuration
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
