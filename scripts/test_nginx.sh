#!/usr/bin/env bash

set -euxo pipefail

IP="$(vagrant ssh -- ip addr \
    | grep '192.168' \
    | tr -s ' ' \
    | cut -d ' ' -f 3 \
    | cut -d '/' -f 1)"

curl -H 'Host: cezarmathe.com' "${IP}"
curl -H 'Host: mathecezar.com' "${IP}"
