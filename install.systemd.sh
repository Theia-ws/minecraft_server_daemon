#!/bin/sh

execute_file_path="$(cd $(dirname $0) && pwd)/$(basename $0)"
execute_paramator="$@"
cd $(dirname $0)

. ./config

INSTALL_SOURCE_DIR="./"
UNIT_DIR="/etc/systemd/system"
INSTALLD_UNIT_FILENAME="${MINECRAFT_SERVER_SERVICE_NAME}.service"
SERVICE_CONFIG_DIR="/etc/sysconfig"
SERVICE_LIB_DIR="/usr/local/lib/${MINECRAFT_SERVER_SERVICE_NAME}"
BIN_DIR="/usr/local/bin"

check_can_install(){
	endcode=0
	switch_execute_user "Sudo is required to install. Please input your account password." "Need root parmissions for install." ${execute_file_path} ${execute_paramator}
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
replace_env_val systemd
install_unit systemd
install_config
install_lib systemd
make_server_root
clean

systemctl daemon-reload
systemctl enable ${MINECRAFT_SERVER_SERVICE_NAME}
systemctl start ${MINECRAFT_SERVER_SERVICE_NAME}
