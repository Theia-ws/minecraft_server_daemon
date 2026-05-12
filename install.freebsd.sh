#!/bin/sh

execute_file_path="$(cd $(dirname $0) && pwd)/$(basename $0)"
execute_paramator="$@"
cd $(dirname $0)

. ./config
. ./common/FUNC_COMMON

INSTALL_SOURCE_DIR="./"
UNIT_DIR="/etc/rc.d"
INSTALLD_UNIT_FILENAME="${MINECRAFT_SERVER_SERVICE_NAME}"
SERVICE_CONFIG_DIR="/usr/local/etc/${MINECRAFT_SERVER_SERVICE_NAME}"
INIT_SYS_NAME="freebsd"
SERVICE_LIB_DIR="/usr/local/lib/${MINECRAFT_SERVER_SERVICE_NAME}"
BIN_DIR="/usr/local/bin"
[ -z "${MINECRAFT_SERVER_ROOT}" ] && MINECRAFT_SERVER_ROOT="/var/db/${MINECRAFT_SERVER_SERVICE_NAME}"

cild_file_sed(){
	REPLACE_VALUE=$(echo "${3}" | sed -e 's/\//\\\//g')
	find "${INSTALL_SOURCE_DIR}${1}/" -type f -maxdepth 1 -exec grep -q "[[[${2}]]]" {} \; -exec sed -i "" -e "s/\[\[\[${2}\]\]\]/${REPLACE_VALUE}/g" {} +
}

make_execute_user(){
	id ${MINECRAFT_SERVER_EXECUTE_USER} > /dev/null  2>&1
	[ "${?}" -ne 0 ] && pw useradd -n ${MINECRAFT_SERVER_EXECUTE_USER} -s /sbin/nologin -m
}

update_property() {
    KEY="${1}"
    VALUE="${2}"

    if grep -q "^[[:space:]]*${KEY}=" "${SERVER_PROPERTIES}"; then
        sed -i '' -e "s|^[[:space:]]*${KEY}=.*|${KEY}=${VALUE}|" "${MINECRAFT_SERVER_ROOT}/server.properties"
    else
        echo "${KEY}=${VALUE}" >> "${MINECRAFT_SERVER_ROOT}/server.properties"
    fi
}

. ./installer.core.sh

check_can_install
if [ "${?}" -eq 1 ]; then
	exit 1
fi
install_dep_pkgs
if [ "${?}" -eq 1 ]; then
	exit 1
fi
make_execute_user

RCON_PASSWORD=$(make_password)

replace_env_val "common"
replace_env_val "${INIT_SYS_NAME}"
install_unit "${INIT_SYS_NAME}"
install_config
install_lib "${INIT_SYS_NAME}"
make_server_root
clean

service_start
