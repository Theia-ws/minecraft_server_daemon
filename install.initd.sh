#!/bin/sh

cd $(dirname $0)

. ./config

INSTALL_SOURCE_DIR="./"
UNIT_DIR="/etc/rc.d/init.d"
INSTALLD_UNIT_FILENAME="${MINECRAFT_SERVER_SERVICE_NAME}"
SERVICE_CONFIG_DIR="/etc/sysconfig"
SERVICE_LIB_DIR="/usr/local/lib/${MINECRAFT_SERVER_SERVICE_NAME}"
BIN_DIR="/usr/local/bin"

check_can_install(){
	endcode=0
	check_install_user
	if [ $? -ne 0 ]; then
		endcode=1
	fi
	return ${endcode}
}

cild_file_sed(){
	grep -l "[[[${2}]]]" ${INSTALL_SOURCE_DIR}${1}/* | xargs sed -i -e "s/\[\[\[${2}\]\]\]/${3}/g"
}

. ./installer.core.sh

check_can_install
if [ $? -eq 1 ]; then
	exit 1
fi
replace_env_val common
replace_env_val initd
install_unit initd
install_config
install_lib initd
make_server_root
clean

chkconfig --add ${MINECRAFT_SERVER_SERVICE_NAME}
chkconfig ${MINECRAFT_SERVER_SERVICE_NAME} on
service ${MINECRAFT_SERVER_SERVICE_NAME} start
