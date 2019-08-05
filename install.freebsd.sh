#!/bin/sh

cd $(dirname $0)

. ./config

INSTALL_SOURCE_DIR="./"
UNIT_DIR="/etc/rc.d"
INSTALLD_UNIT_FILENAME="${MINECRAFT_SERVER_SERVICE_NAME}"
SERVICE_CONFIG_DIR="/usr/local/etc/${MINECRAFT_SERVER_SERVICE_NAME}"
SERVICE_LIB_DIR="/usr/local/lib/${MINECRAFT_SERVER_SERVICE_NAME}"
BIN_DIR="/usr/local/bin"


install_dependent_package(){
	which ${CURL_PATH} > /dev/null 2>&1
	[ $? -ne 0 ] && pkg install -y curl
	which git > /dev/null 2>&1
	[ $? -ne 0 ] && pkg install -y git
	which ${JVM_PATH} > /dev/null 2>&1
	[ $? -ne 0 ] && pkg install -y openjdk8-jre
	which ${SCREEN_PATH} > /dev/null 2>&1
	[ $? -ne 0 ] && pkg install -y screen
}

cild_file_sed(){
	grep -l "[[[${2}]]]" ${INSTALL_SOURCE_DIR}${1}/* | xargs sed -i "" -e "s/\[\[\[${2}\]\]\]/${3}/g"
}

make_execute_user(){
	id ${MINECRAFT_SERVER_EXECUTE_USER} > /dev/null  2>&1
	[ $? -ne 0 ] && pw useradd -n ${MINECRAFT_SERVER_EXECUTE_USER} -s /sbin/nologin -m
}

. ./installer.core.sh

install_dependent_package
make_execute_user
replace_env_val common
replace_env_val freebsd
install_unit freebsd
install_config
install_lib freebsd
make_server_root
clean

echo "${MINECRAFT_SERVER_SERVICE_NAME}_enable=\"YES\"" >> /etc/rc.conf
service ${MINECRAFT_SERVER_SERVICE_NAME} start
