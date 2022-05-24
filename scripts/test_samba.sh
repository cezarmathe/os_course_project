#!/usr/bin/env bash

set -euxo pipefail

IP="$(vagrant ssh -- ip addr \
    | grep '192.168' \
    | tr -s ' ' \
    | cut -d ' ' -f 3 \
    | cut -d '/' -f 1)"

function test_samba() {
    local username
    username="${1}"; shift
    local password
    password="${1}"; shift

    mkdir -p "samba/${username}"
    sudo mount -t cifs \
        "//${IP}/${username}" \
        "./samba/${username}" \
        -o "username=${username},password=${password},workgroup=workgroup,iocharset=utf8"
    ls -alh "./samba/${username}"
    sudo umount "./samba/${username}"
}

test_samba "profesor" "Password1234."
test_samba "student" "Password1234."
