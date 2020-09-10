#!/bin/bash

if [[ -f ~root/.ssh/authorized_keys ]]; then
  [[ ! -d ~default/.ssh ]] && mkdir ~default/.ssh
  rsync ~root/.ssh/authorized_keys ~default/.ssh
  chown -Rf default:default ~default/.ssh
fi



