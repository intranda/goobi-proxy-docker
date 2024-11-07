# goobi-proxy-docker
A reverse proxy with ssl (letsencrypt) support for Goobi Workflow and Viewer, based on apache

## Prerequisites
* [docker](https://docs.docker.com/get-docker/) (or [podman](https://podman.io/get-started))
* if you want to use Letsencrypt / SSL:
  * a server with a public IP (or a port forwarding for ports 80 and 443)
  * a (sub)domain pointing to that IP
* this repository

```bash
sudo apt install docker.io docker-compose
git clone https://github.com/intranda/goobi-proxy-docker.git
```

## Usage
gather information for the following environment variables:
* `SERVERNAME`: this should be the FQDN / (sub)domain, that points to your (public) IP
* `SERVERADMIN`: email address to be displayed on error pages
* `HTTP_PORT`: if different from the default of 80
* do you want to use SSL? (strongly recommended for public / production systems)
    * set `ENABLE_SSL=1`
    * `LE_EMAIL`: email address for registration with Letsencrypt
    * `HTTPS_PORT`: if different from the default of 443
    * decide on a path / volume to store Letsencrypt account data and SSL certificates and mount it to /etc/letsencrypt within the container
* if you want to enable access to a Goobi Viewer
    * set `ENABLE_VIEWER=1`
    * set `VIEWER_CONTAINER` to the container name / hostname / IP of the Goobi Viewer
* if you want to enable access to a Goobi Workflow
    * set `ENABLE_WORKFLOW=1`
    * set `WORKFLOW_CONTAINER` to the container name / hostname / IP of the Goobi Workflow
* if you want to serve static content / a landing page
    * decide on a path / volume and mount it to /var/www within the container
* all variables can be written to a file like `testenv_nossl`
* there are further variables in the `Dockerfile` in case your Goobi systems run on non-standard ports, paths, if you want to change the default redirect path etc.

example command to start the container:
```bash
docker run \
    --detach \
    --name goobi-proxy-docker \
    -v /path/to/letsencrypt_data:/etc/letsencrypt \
    -v /path/to/static_content:/var/www \
    -p 80:80 \
    -p 443:443 \
    --env-file=/path/to/your_variables.env \
    intranda/goobi-proxy-docker

```


## development notes
### general config
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
