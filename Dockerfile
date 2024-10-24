FROM docker.io/library/httpd:2.4 

LABEL org.opencontainers.image.authors="Matthias Geerdsen <matthias.geerdsen@intranda.com>"
# TODO FIXME point to new repo
LABEL org.opencontainers.image.source="https://github.com/intranda/goobi-docker-proxy"
LABEL org.opencontainers.image.description="Goobi combined - http reverse proxy"

ENV SERVER_ROOT="/usr/local/apache2"

ENV ENABLE_SSL=1
ENV HTTPS_DOMAIN=""

ENV HTTPD_PORT=80
ENV SERVERNAME="localhost"
ENV SERVERADMIN="support@intranda.com"

ENV REMOTEIP_HEADER="X-Forwarded-For"
ENV REMOTEIP_INTERNAL_PROXY=""
ENV USE_MOD_REMOTEIP=0
ENV SITEMAP_LOCATION=""
ENV CUSTOM_CONFIG=""

ENV REDIRECT_INDEX_TO="/viewer/"

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

COPY httpd.conf.template ${SERVER_ROOT}/conf/httpd.conf.template
COPY viewer.conf.template ${SERVER_ROOT}/conf/viewer.conf.template
COPY workflow.conf.template ${SERVER_ROOT}/conf/workflow.conf.template
COPY run.sh /
RUN mkdir /var/www && touch /var/www/index.html
COPY robots.txt /var/www/

RUN apt-get update && \
    apt-get -y upgrade && \
    apt-get -y install \
                gettext-base \
                certbot \
               && \
    rm -rf /var/lib/apt/lists/*

CMD ["/run.sh"]
