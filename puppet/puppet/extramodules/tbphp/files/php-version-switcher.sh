#!/bin/bash

SOCKET_NAME=$1
PHP_VERSION=$2

if [ "${PHP_VERSION}X" == "7X" ]; then
    PHP_VERSION=70
fi

if [ -z "${SOCKET_NAME}" ]; then
    echo 1st parameter needs to be the php-fpm poolname. Quitting..
    echo
    exit;
fi

if [ -z "${PHP_VERSION}" ]; then
    echo 2nd parameter needs to be the php-fpm version. Quitting..
    echo
    exit;
fi

SWITCHER_DIR=/var/run/php-fpm7-switcher
TBLOCAL_USER=${SOCKET_NAME}
USER_HOMEDIR=$( eval echo "~${TBLOCAL_USER}" )

setUtilAliasses(){
    local COMMAND=$1

    if [ -f ${USER_HOMEDIR}/.bashrc ]; then

        sed -i -e "/^alias ${COMMAND}/d" ${USER_HOMEDIR}/.bashrc_local

        case "${PHP_VERSION}" in
            5*)
                local PHP_COMMAND=$( which --skip-alias php )
                ;;
            7?)
                local PHP_COMMAND=$( which --skip-alias php${PHP_VERSION} )
                ;;
        esac

        test_command=$( which --skip-alias ${COMMAND} )
        if [ $? -ne 0 ]; then
            echo command ${COMMAND} does not exist
            return
        fi
        local PHP_COMMAND_TO=$( which --skip-alias ${COMMAND} )

        # echo setting command alias ${COMMAND} to ${PHP_COMMAND} ${PHP_COMMAND_TO}

        # echo "alias ${COMMAND}=\"${PHP_COMMAND} ${PHP_COMMAND_TO}\"" >> ${USER_HOMEDIR}/.bashrc_local
    fi

}

whichVersion(){
    local socket=$( readlink -f ${SWITCHER_DIR}/${SOCKET_NAME}.sock )
    # echo ${socket}
    case ${socket} in
    *php70*)
        VERSION=70
        ;;
    *php71*)
        VERSION=71
        ;;
    *php72*)
        VERSION=72
        ;;
    *php73*)
        VERSION=73
        ;;
    /run/php-fpm*)
        VERSION=56
        ;;
    *)
        echo unknown php version: ${socket}, doing nothing
        ;;
esac
}

if [ ! -L ${SWITCHER_DIR}/${SOCKET_NAME}.sock ]; then
    echo file ${SWITCHER_DIR}/${SOCKET_NAME}.sock does not exist. Stopping
    echo
    exit;
fi

whichVersion
echo "Current active version: $VERSION"

case "${PHP_VERSION}" in
    5*)
        PHP_SOCKDIR_5=/var/run/php-fpm

        ln -sf ${PHP_SOCKDIR_5}/${SOCKET_NAME}.sock ${SWITCHER_DIR}/${SOCKET_NAME}.sock
        sed -i -r -e "/${SOCKET_NAME}.sock/s#- (.*)\$#- ${PHP_SOCKDIR_5}/${SOCKET_NAME}.sock#g" /etc/tmpfiles.d/php7-switcher-pool-${SOCKET_NAME}.conf
        whichVersion
        sudo -u ${TBLOCAL_USER} ln -sf /usr/bin/php ${USER_HOMEDIR}/private/bin/php
        echo "New active version: $VERSION"
        ;;
    7?)

        PHP_SOCKDIR_7=/var/opt/remi/php${PHP_VERSION}/run/php-fpm

        ln -sf ${PHP_SOCKDIR_7}/${SOCKET_NAME}.sock ${SWITCHER_DIR}/${SOCKET_NAME}.sock
        sed -i -r -e "/${SOCKET_NAME}.sock/s#- (.*)\$#- ${PHP_SOCKDIR_7}/${SOCKET_NAME}.sock#g" /etc/tmpfiles.d/php7-switcher-pool-${SOCKET_NAME}.conf
        whichVersion
        sudo -u ${TBLOCAL_USER} ln -sf /usr/bin/php${VERSION} ${USER_HOMEDIR}/private/bin/php
        echo "New active version: $VERSION"
        ;;
    *)
        echo unknown php version: ${PHP_VERSION}, doing nothing
        ;;
esac

# setUtilAliasses wp
# setUtilAliasses composer

