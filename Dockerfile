FROM docker.io/library/httpd:2.4 

LABEL org.opencontainers.image.authors="Moritz Bellach <moritz.bellach@intranda.com>"
LABEL org.opencontainers.image.source="https://github.com/intranda/goobi-proxy-docker"
LABEL org.opencontainers.image.description="Goobi - http reverse proxy"

# put this first so we don't have to reinstall stuff
# every time we change a var or a file
RUN apt-get update && \
    apt-get -y upgrade && \
    apt-get -y install \
                gettext-base \
                certbot \
               && \
    rm -rf /var/lib/apt/lists/*


ENV SERVER_ROOT="/usr/local/apache2"

ENV ENABLE_SSL=1
ENV LE_EMAIL="admin@intranda.com"

ENV HTTP_PORT="80"
ENV HTTPS_PORT="443"

# this must be the fqdn under which this server/image is reachable from the public internet
# especially important for LetsEncrypt!
ENV SERVERNAME="localhost"
ENV SERVERADMIN="support@intranda.com"

ENV REMOTEIP_HEADER="X-Forwarded-For"
ENV REMOTEIP_INTERNAL_PROXY=""
ENV USE_MOD_REMOTEIP=0

ENV ENABLE_SITEMAP=0
ENV SITEMAP_LOCATION=""
ENV CUSTOM_CONFIG=""


ENV ENABLE_VIEWER=0
ENV VIEWER_HTTP_PORT=8080
ENV VIEWER_AJP_PORT=8009
ENV VIEWER_PATH="/viewer"
ENV VIEWER_CONTAINER="viewer"

ENV SOLR_PORT=8983
ENV SOLR_PATH="/solr"
ENV SOLR_CONTAINER="solr"
ENV SOLR_INCLUDES="Require all denied"

ENV ENABLE_WORKFLOW=0
ENV WORKFLOW_HTTP_PORT=8080
ENV WORKFLOW_AJP_PORT=8009
ENV WORKFLOW_PATH="/goobi"
ENV WORKFLOW_CONTAINER="workflow"

ENV ITM_AJP_PORT=8009
ENV ITM_PATH="/itm"
ENV ITM_CONTAINER="itm"

ENV ENABLE_REDIRECT_INDEX=1
ENV REDIRECT_INDEX_TO="${VIEWER_PATH}/"

COPY httpd.conf.template ${SERVER_ROOT}/conf/httpd.conf.template
COPY http_vhost.conf.template ${SERVER_ROOT}/conf/http_vhost.conf.template
COPY https_vhost.conf.template ${SERVER_ROOT}/conf/https_vhost.conf.template
COPY https_redir.conf ${SERVER_ROOT}/conf/https_redir.conf
COPY goobi-common.conf.template ${SERVER_ROOT}/conf/goobi-common.conf.template
COPY viewer.conf.template ${SERVER_ROOT}/conf/viewer.conf.template
COPY workflow.conf.template ${SERVER_ROOT}/conf/workflow.conf.template
COPY robots.txt.template ${SERVER_ROOT}/conf/robots.txt.template
COPY entrypoint.sh /

RUN mkdir -p /var/www && \
    mkdir -p /etc/letsencrypt && \
    chmod 755 /entrypoint.sh

# expose is only for documentation / easy usage of the docker command
# it has no effect on being able to forward ports
EXPOSE ${HTTP_PORT}
EXPOSE ${HTTPS_PORT}

# if we want to keep the certs / cerbot keys&config persistent
# between container restarts, we could use this
VOLUME /etc/letsencrypt
# this is for static content, that might change independently from the image
VOLUME /var/www
# this is another static content directory, that may be used if one connects
# to the server with a hostname, that is not covered by a vhost
VOLUME ${SERVER_ROOT}/htdocs

# TODO: if we decide to run cron/certbot in this same container,
# we should probably use some kind of process manager / supervisor instead
# here is an older comparison, maybe something better has been made since then
# https://ahmet.im/blog/minimal-init-process-for-containers/
# for now: just run once, restart the container to get new certs

# TODO: maybe use "-g" to send signals to all children as well?
# not sure in the case of apache
ENTRYPOINT ["/entrypoint.sh"]
