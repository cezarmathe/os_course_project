#!/usr/bin/env bash

set -euxo pipefail

# add ubuntu user (by default this vm comes with the vagrant user)
sudo useradd -m -d /home/ubuntu -s /bin/bash -G sudo ubuntu
echo 'ubuntu:proiectso' | sudo chpasswd

# add more users
sudo useradd -m -d /home/student -s /bin/bash student
sudo useradd -m -d /home/profesor -s /bin/bash -G sudo profesor
sudo useradd -m -d /home/decan -s /bin/bash -G sudo decan
sudo useradd -m -d /home/secretar -s /bin/bash secretar
sudo useradd -m -d /home/paznic -s /bin/bash -G sudo paznic

# install packages
# - nginx: web server
# - ufw: firewall
# - samba: network file sharing
# - openssh-server: ssh server (sshd)
# - sendmail: mail
# - vsftpd: ftp
sudo apt-get install --yes \
    nginx \
    ufw \
    samba \
    openssh-server \
    sendmail \
    vsftpd

# add firewall rules, enable firewall
sudo ufw allow ssh
sudo ufw allow http
sudo ufw allow samba
sudo ufw allow https
sudo ufw allow mail
sudo ufw enable

# enable services
sudo systemctl enable --now nginx
sudo systemctl enable --now ssh
sudo systemctl enable --now smbd

# configure nginx
sudo rm /etc/nginx/sites-enabled/default

# This function creates basic nginx virtual hosts.
function create_nginx_virtual_host() {
    # the virtual host name
    local name
    name="${1}"; shift

    # create www root
    sudo mkdir "/var/www/${name}"

    # declare nginx config
    local config
    config=$(cat <<EOF
server {
    listen 80;
    listen [::]:80;

    server_name ${name};

    root /var/www/${name};
    index index.html;

    location / {
    try_files \$uri \$uri/ =404;
    }
}
EOF
    )

    # declare index.html for this vhost
    local index
    index=$(cat <<EOF
<html>
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title>Site-ul ${name}</title>
    </head>
    <body>
        <h1>Bun venit pe ${name}!</h1>
        <p>Acesta este un site servit de <a href="https://www.nginx.com/">nginx</a>.</p>
    </body>
</html>
EOF
    )

    # create the nginx vhost config file
    echo "${config}" \
        | sudo tee "/etc/nginx/sites-available/${name}.conf"
    # create the index.html for this vhost
    echo "${index}" \
        | sudo tee "/var/www/${name}/index.html"
    # enable this vhost
    sudo ln -s \
        "/etc/nginx/sites-available/${name}.conf" \
        "/etc/nginx/sites-enabled/${name}.conf"
    # add the name of this vhosts to the list of known hosts for this machine
    echo "${name} 127.0.0.1" | sudo tee -a /etc/hosts
}

create_nginx_virtual_host "cezarmathe.com"
create_nginx_virtual_host "mathecezar.com"

sudo systemctl reload nginx

# configure samba

# This function creates samba users and directories.
#
# - name: name of user
# - password: password for user
# - ro (read-only): yes | no
# - public: yes | no
# - gok (guest ok): yes | no
# - browse: yes | no
function create_samba_user_dir() {
    local name
    name="${1}"; shift
    local password
    password="${1}"; shift
    local ro
    ro="${1}"; shift
    local public
    public="${1}"; shift
    local gok
    gok="${1}"; shift
    local browse
    browse="${1}"; shift
    local dmask
    dmask="${1}"; shift
    local cmask
    cmask="${1}"; shift

    local config
    config=$(cat <<EOF
[${name}]
comment=${name}'s Files
path=/home/${name}
read only=${ro}
public=${public}
guest ok=${gok}
browseable=${browse}
valid users=${name}
directory mask=${dmask}
create mask=${cmask}
EOF
    )

    echo "${config}" | sudo tee -a /etc/samba/smb.conf
    printf "%s\n%s\n" "${password}" "${password}"  | smbpasswd -s -a "${name}"
    sudo systemctl reload smbd
}

create_samba_user_dir \
    "student" \
    "Password1234." \
    "yes" \
    "yes" \
    "yes" \
    "yes" \
    "0700" \
    "0700"
create_samba_user_dir \
    "profesor" \
    "Password1234." \
    "yes" \
    "yes" \
    "yes" \
    "yes" \
    "0700" \
    "0700"

sudo systemctl restart smbd
sudo systemctl restart nmbd

# configure sendmail

# update /etc/hosts
sudo sed -i 's/127.0.0.1 localhost/127.0.0.1 localhost Ubuntu.lan Ubuntu/g; s/127.0.1.1 ubuntu2110.localdomain/127.0.1.1 Ubuntu.lan Ubuntu/g' /etc/hosts
# configure sendmail automatically
printf "\n\n\n" | sudo sendmailconfig

# configure ftp

# update config file
sudo sed -i 's/#write_enable=YES/write_enable=YES/g' /etc/vsftpd.conf
sudo systemctl restart vsftpd
