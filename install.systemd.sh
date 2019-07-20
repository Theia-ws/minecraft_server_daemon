#!/bin/sh

cd $(dirname $0)

. ./config

INSTALL_SOURCE_DIR=./
UNIT_DIR=/etc/systemd/system
INSTALLD_UNIT_FILENAME=${MINECRAFT_SERVER_SERVICE_NAME}.service
SERVICE_CONFIG_DIR=/etc/sysconfig
SERVICE_LIB_DIR=/usr/local/lib/${MINECRAFT_SERVER_SERVICE_NAME}
BIN_DIR=/usr/local/bin

cild_file_sed(){
	grep -l "[[[${2}]]]" ${INSTALL_SOURCE_DIR}${1}/* | xargs sed -i -e "s/\[\[\[${2}\]\]\]/${3}/g"
}

. ./installer.core.sh

replace_env_val common
replace_env_val systemd
install_unit systemd
install_config
install_lib systemd
make_server_root
clean

systemctl daemon-reload
systemctl enable ${MINECRAFT_SERVER_SERVICE_NAME}
systemctl start ${MINECRAFT_SERVER_SERVICE_NAME}
