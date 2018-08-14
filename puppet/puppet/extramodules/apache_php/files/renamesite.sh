#!/usr/bin/env bash

FROMUSER=$1
TOUSER=$2

CURHOME=$( getent passwd "${FROMUSER}" | cut -d: -f6 )

sed -i -r -e "/^${FROMUSER}:/s/${FROMUSER}/${TOUSER}/g" /etc/passwd /etc/shadow

TOHOME=$( getent passwd "${TOUSER}" | cut -d: -f6 )

mv ${CURHOME} ${TOHOME}
