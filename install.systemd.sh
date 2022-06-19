#!/bin/sh

execute_file_path="$(cd $(dirname $0) && pwd)/$(basename $0)"
execute_paramator="$@"
cd $(dirname $0)

. ./config
. ./common/FUNC_COMMON

INSTALL_SOURCE_DIR="./"
UNIT_DIR="/etc/systemd/system"
INSTALLD_UNIT_FILENAME="${MINECRAFT_SERVER_SERVICE_NAME}.service"
SERVICE_CONFIG_DIR="/etc/sysconfig"
INIT_SYS_NAME="systemd"
SERVICE_LIB_DIR="/usr/local/lib/${MINECRAFT_SERVER_SERVICE_NAME}"
BIN_DIR="/usr/local/bin"

cild_file_sed(){
	grep -l "[[[${2}]]]" ${INSTALL_SOURCE_DIR}${1}/* | xargs sed -i -e "s/\[\[\[${2}\]\]\]/${3}/g"
}

make_execute_user(){
	id ${MINECRAFT_SERVER_EXECUTE_USER} > /dev/null  2>&1
	[ $? -ne 0 ] && useradd ${MINECRAFT_SERVER_EXECUTE_USER} -s /sbin/nologin -m
}

. ./installer.core.sh

check_can_install
if [ $? -eq 1 ]; then
	exit 1
fi
install_dependent_package
if [ $? -eq 1 ]; then
	exit 1
fi
make_execute_user

replace_env_val common
replace_env_val ${INIT_SYS_NAME}
install_unit ${INIT_SYS_NAME}
install_config
install_lib ${INIT_SYS_NAME}
make_server_root
clean

systemctl daemon-reload
systemctl enable ${MINECRAFT_SERVER_SERVICE_NAME}
systemctl start ${MINECRAFT_SERVER_SERVICE_NAME}
