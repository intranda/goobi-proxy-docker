#!/bin/bash

# abort script on error
set -e
# treat undefined vars as errors
set -u
# disable globbing
set -f

# any error in pipelined commands is an error (not just the last command)
# not supported by dash. unsure about /bin/sh
set -o pipefail

export APACHE_CONFDIR=${SERVER_ROOT}/conf
export SV=""

# SSL stuff
export LISTEN_HTTPS="# SSL disabled"
export REDIR_XOR_COMMON="goobi-common.conf"

export MOD_REMOTEIP="# mod_remoteip disabled"
export SITEMAP="# sitemap disabled"
export REDIRECT_INDEX="# REDIRECT_INDEX_TO is not set"
export REDIRECT_SLASH="# REDIRECT_INDEX_TO is not set"
export APACHE_ALIASES="# SERVERALIASES is not set"
export CERTBOT_ALIASES=""

if [[ -v SERVERALIASES ]]; then
    APACHE_ALIASES="ServerAlias $SERVERALIASES"
    # the leading space in the echo below is important!
    CERTBOT_ALIASES=$(echo -n " $SERVERALIASES" | tr ' ' ',')
fi

if [ $ENABLE_REDIRECT_INDEX -eq 1 ]
then
    REDIRECT_INDEX="redirect 301 /index.html ${REDIRECT_INDEX_TO}"
    REDIRECT_SLASH="redirectmatch 301 ^/$ ${REDIRECT_INDEX_TO}"
fi

render_template () {
    local SRC="$1"
    local DEST="$2"

    RENDERVARS=""
    # using $SV global variable here to work around broken
    # quoting / function arguments in bash :/
    for MYVAR in $(echo "$SV" | tr " " "\n")
    do
        RENDERVARS="${RENDERVARS} \$${MYVAR}"
    done
    echo "rendering template with vars ${SV}:"
    echo "${SRC} ->"
    echo "$DEST"
    envsubst "$RENDERVARS" < "$SRC" > "$DEST"
}


# -v tests if a var is set
# new since bash 4.2, if this doesn't work maybe just do: $cmd || true
if [[ -v SOLR_INCLUDES ]]; then
    echo -e "$SOLR_INCLUDES" > ${APACHE_CONFDIR}/solr-restrictions.conf
fi

if [ $ENABLE_SSL -eq 1 ]
then
    echo "Enabling SSL"
    LISTEN_HTTPS="Listen $HTTPS_PORT"
    REDIR_XOR_COMMON="https_redir.conf"

    # render HTTPS vhost
    SV=""
    SV="${SV} SERVERNAME"
    SV="${SV} APACHE_ALIASES"
    SV="${SV} SERVERADMIN"
    SV="${SV} HTTPS_PORT"
    SV="${SV} LISTEN_HTTPS"
    render_template ${APACHE_CONFDIR}/https_vhost.conf.template \
                    ${APACHE_CONFDIR}/https_vhost.conf
    # get certifcate once / ensure they are current
    echo "Running certbot to get LetsEncrypt Certificates"
    certbot certonly --non-interactive --standalone --http-01-port "$HTTP_PORT" --keep-until-expiring --email "$LE_EMAIL" --agree-tos --no-eff-email -d "${SERVERNAME}${CERTBOT_ALIASES}"
fi

# render HTTP vhost
SV=""
SV="${SV} SERVERNAME"
SV="${SV} APACHE_ALIASES"
SV="${SV} SERVERADMIN"
SV="${SV} HTTP_PORT"
SV="${SV} REDIR_XOR_COMMON"
render_template ${APACHE_CONFDIR}/http_vhost.conf.template \
                ${APACHE_CONFDIR}/http_vhost.conf

# render common config
SV=""
SV="${SV} CUSTOM_CONFIG"
SV="${SV} REDIRECT_INDEX"
SV="${SV} REDIRECT_SLASH"
render_template ${APACHE_CONFDIR}/goobi-common.conf.template \
                ${APACHE_CONFDIR}/goobi-common.conf


if [ $USE_MOD_REMOTEIP -eq 1 ]
then
   echo "Enabling mod_remoteip"
   MOD_REMOTEIP="LoadModule remoteip_module modules/mod_remoteip.so"
fi

# render main httpd.conf
SV=""
SV="${SV} SERVER_ROOT"
SV="${SV} HTTP_PORT"
SV="${SV} HTTPS_PORT"
SV="${SV} LISTEN_HTTPS"
SV="${SV} SERVERNAME"
SV="${SV} SERVERADMIN"
SV="${SV} HTTPS_DOMAIN"
SV="${SV} MOD_REMOTEIP"
SV="${SV} REMOTEIP_HEADER"
SV="${SV} REMOTEIP_INTERNAL_PROXY"
SV="${SV} CUSTOM_CONFIG"
render_template ${APACHE_CONFDIR}/httpd.conf.template \
                ${APACHE_CONFDIR}/httpd.conf

# render viewer config section
if [ $ENABLE_VIEWER -eq 1 ]
then
    SV=""
    SV="${SV} VIEWER_HTTP_PORT"
    SV="${SV} VIEWER_AJP_PORT"
    SV="${SV} VIEWER_PATH"
    SV="${SV} VIEWER_CONTAINER"
    SV="${SV} SOLR_PORT"
    SV="${SV} SOLR_PATH"
    SV="${SV} SOLR_CONTAINER"
    echo "Enabling Viewer"
    render_template ${APACHE_CONFDIR}/viewer.conf.template \
                    ${APACHE_CONFDIR}/viewer.conf
fi

# render workflow config section
if [ $ENABLE_WORKFLOW -eq 1 ]
then
    echo "Enabling Workflow"
    SV=""
    SV="${SV} WORKFLOW_HTTP_PORT"
    SV="${SV} WORKFLOW_AJP_PORT"
    SV="${SV} WORKFLOW_PATH"
    SV="${SV} WORKFLOW_CONTAINER"
    SV="${SV} ITM_AJP_PORT"
    SV="${SV} ITM_PATH"
    SV="${SV} ITM_CONTAINER"
    render_template ${APACHE_CONFDIR}/workflow.conf.template \
                    ${APACHE_CONFDIR}/workflow.conf
fi

# render vocabulary config section
if [ $ENABLE_VOCABULARY -eq 1 ]
then
    echo "Enabling Vocabulary"
    SV=""
    SV="${SV} VOCABULARY_HTTP_PORT"
    SV="${SV} VOCABULARY_PATH"
    SV="${SV} VOCABULARY_CONTAINER"
    render_template ${APACHE_CONFDIR}/vocabulary.conf.template \
                    ${APACHE_CONFDIR}/vocabulary.conf
fi

# render samples config section
if [ $ENABLE_SAMPLES -eq 1 ]
then
    echo "Enabling Samples"
    SV=""
    SV="${SV} SAMPLES_HTTP_PORT"
    SV="${SV} SAMPLES_PATH"
    SV="${SV} SAMPLES_CONTAINER"
    render_template ${APACHE_CONFDIR}/samples.conf.template \
                    ${APACHE_CONFDIR}/samples.conf
fi

# render robots.txt, optionally with sitemap
if [ $ENABLE_SITEMAP -eq 1 ]
then
    echo "Enabling Sitemap"
    SITEMAP="Sitemap: ${SITEMAP_LOCATION}"
fi
SV=""
SV="${SV} VIEWER_PATH"
SV="${SV} WORKFLOW_PATH"
SV="${SV} SITEMAP"
render_template ${APACHE_CONFDIR}/robots.txt.template \
                /var/www/robots.txt


# TODO: make cronjob for certbot and start cron in the background
# alternatively: second container with access to shared volume for
# letsencrypt config/keys/certs (but then we need to think about how to
# notify apache in case of new certs / regularly restart it just in case
#
# cronjob command should be something like this:
# certbot certonly --webroot --webroot-path /var/www --email "$LE_EMAIL" --agree-tos --no-eff-email -d "$SERVERNAME"
# easiest solution for now is something like restarting the container daily

# ported from httpd-foreground wrapper:
# Apache gets grumpy about PID files pre-existing
rm -f ${SERVER_ROOT}/logs/httpd.pid

echo "Starting Apache2..."
echo "with extra args:"
echo "$@"
exec /usr/local/apache2/bin/httpd -DFOREGROUND "$@"
