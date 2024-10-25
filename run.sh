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

APACHE_CONFDIR=${SERVER_ROOT}/conf

# -v tests if a var is set
# new since bash 4.2, if this doesn't work maybe just do: $cmd || true
if [[ -v SOLR_INCLUDES ]]; then
    echo -e "$SOLR_INCLUDES" > ${APACHE_CONFDIR}/solr-restrictions.conf
fi

SUBSTVARS=""
SUBSTVARS="${SUBSTVARS} \$SERVER_ROOT"
SUBSTVARS="${SUBSTVARS} \$HTTPD_PORT"
SUBSTVARS="${SUBSTVARS} \$SERVERNAME"
SUBSTVARS="${SUBSTVARS} \$SERVERADMIN"
SUBSTVARS="${SUBSTVARS} \$REDIRECT_INDEX_TO"
SUBSTVARS="${SUBSTVARS} \$HTTPS_DOMAIN"
SUBSTVARS="${SUBSTVARS} \$REMOTEIP_HEADER"
SUBSTVARS="${SUBSTVARS} \$REMOTEIP_INTERNAL_PROXY"
SUBSTVARS="${SUBSTVARS} \$CUSTOM_CONFIG"
# TODO scheint unbenutzt, kann das weg oder ist das zukunftskram?
#SUBSTVARS="${SUBSTVARS} \$CONNECTOR_AJP_PORT"
#SUBSTVARS="${SUBSTVARS} \$CONNECTOR_HTTP_PORT"
#SUBSTVARS="${SUBSTVARS} \$CONNECTOR_PATH"
#SUBSTVARS="${SUBSTVARS} \$CONNECTOR_CONTAINER"

envsubst "$SUBSTVARS" < ${APACHE_CONFDIR}/httpd.conf.template > ${APACHE_CONFDIR}/httpd.conf

if [ $ENABLE_VIEWER -eq 1 ]
then
    SUBSTVARS=""
    SUBSTVARS="${SUBSTVARS} \$VIEWER_HTTP_PORT"
    SUBSTVARS="${SUBSTVARS} \$VIEWER_AJP_PORT"
    SUBSTVARS="${SUBSTVARS} \$VIEWER_PATH"
    SUBSTVARS="${SUBSTVARS} \$VIEWER_CONTAINER"
    SUBSTVARS="${SUBSTVARS} \$SOLR_PORT"
    SUBSTVARS="${SUBSTVARS} \$SOLR_PATH"
    SUBSTVARS="${SUBSTVARS} \$SOLR_CONTAINER"
    echo "enabling viewer"
    envsubst "$SUBSTVARS" < ${APACHE_CONFDIR}/viewer.conf.template > ${APACHE_CONFDIR}/viewer.conf
fi

if [ $ENABLE_WORKFLOW -eq 1 ]
then
    echo "enabling workflow"
    SUBSTVARS=""
    SUBSTVARS="${SUBSTVARS} \$WORKFLOW_HTTP_PORT"
    SUBSTVARS="${SUBSTVARS} \$WORKFLOW_AJP_PORT"
    SUBSTVARS="${SUBSTVARS} \$WORKFLOW_PATH"
    SUBSTVARS="${SUBSTVARS} \$WORKFLOW_CONTAINER"
    SUBSTVARS="${SUBSTVARS} \$ITM_AJP_PORT"
    SUBSTVARS="${SUBSTVARS} \$ITM_PATH"
    SUBSTVARS="${SUBSTVARS} \$ITM_CONTAINER"
    envsubst "$SUBSTVARS" < ${APACHE_CONFDIR}/workflow.conf.template > ${APACHE_CONFDIR}/workflow.conf
fi

if [ $USE_MOD_REMOTEIP -eq 1 ]
then
   echo "Enabling mod_remoteip"
   sed -i 's|#LoadModule remoteip_module modules/mod_remoteip.so|LoadModule remoteip_module modules/mod_remoteip.so|' ${APACHE_CONFDIR}/httpd.conf
fi

if [[ "$SITEMAP_LOCATION" != "" ]]
then
   echo "Setting Sitemap in robots.txt"
   sed -i -E "s|^.?Sitemap:.*$|Sitemap: $SITEMAP_LOCATION|" /var/www/robots.txt
fi

cat ${APACHE_CONFDIR}/httpd.conf

if [ $ENABLE_SSL -eq 1 ]
then
    certbot certonly --webroot --webroot-path /var/www -m rootmail@intranda.com --agree-tos --no-eff-email -d $HTTPS_DOMAIN
fi

echo "Starting Apache2..."
exec httpd-foreground
