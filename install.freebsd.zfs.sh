#!/bin/sh

execute_file_path="$(cd $(dirname $0) && pwd)/$(basename $0)"
execute_paramator="$@"
cd $(dirname $0)

. ./config
. ./common/FUNC_COMMON
. ./freebsd.zfs/FUNC_DICTIONARY_MANAGER
. ./freebsd.zfs/config.zfs

INSTALL_SOURCE_DIR="./"
UNIT_DIR="/etc/rc.d"
INSTALLD_UNIT_FILENAME="${MINECRAFT_SERVER_SERVICE_NAME}"
SERVICE_CONFIG_DIR="/usr/local/etc/${MINECRAFT_SERVER_SERVICE_NAME}"
INIT_SYS_NAME="freebsd"
SERVICE_LIB_DIR="/usr/local/lib/${MINECRAFT_SERVER_SERVICE_NAME}"
BIN_DIR="/usr/local/bin"

cild_file_sed(){
	grep -l "[[[${2}]]]" ${INSTALL_SOURCE_DIR}${1}/* | xargs sed -i "" -e "s/\[\[\[${2}\]\]\]/${3}/g"
}

make_execute_user(){
	id ${MINECRAFT_SERVER_EXECUTE_USER} > /dev/null  2>&1
	[ $? -ne 0 ] && pw useradd -n ${MINECRAFT_SERVER_EXECUTE_USER} -s /sbin/nologin -m
}

install_zfs_config(){
	[ ! -e ${SERVICE_CONFIG_DIR} ] && mkdir -p ${SERVICE_CONFIG_DIR}
	[ -e ${INSTALL_SOURCE_DIR}freebsd.zfs/config.zfs ] && cp ${INSTALL_SOURCE_DIR}freebsd.zfs/config.zfs ${SERVICE_CONFIG_DIR}/${MINECRAFT_SERVER_SERVICE_NAME}.zfs
	chmod 755 ${SERVICE_CONFIG_DIR}/${MINECRAFT_SERVER_SERVICE_NAME}.zfs
}

make_zfs_volume(){
	
	loopend=`SNAPSHOT_TARGET_VOLUME__LOOPEND`
	
	for index in `seq 0 ${loopend}`; do

		volume=`SNAPSHOT_TARGET_VOLUME__GET_NAME $index`
		mountpoint=`SNAPSHOT_TARGET_VOLUME__GET_MOUNTPOINT $index`
		
		result=`zfs list -o mountpoint ${volume} 2> /dev/null`
		if [ $? -eq 1 ]; then
			zfs create -o atime=off -o mountpoint=${mountpoint} ${volume}
		fi
		
		chown -R ${MINECRAFT_SERVER_EXECUTE_USER}:${MINECRAFT_SERVER_EXECUTE_GROUP} ${mountpoint}
		
	done
	
}

make_backup_dir(){
	[ ! -e ${BACKUP_DIR} ] && mkdir ${BACKUP_DIR}
	chown -R ${MINECRAFT_SERVER_EXECUTE_USER}:${MINECRAFT_SERVER_EXECUTE_GROUP} ${BACKUP_DIR}
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
replace_env_val freebsd.zfs
install_unit ${INIT_SYS_NAME}
install_config
install_zfs_config
install_lib ${INIT_SYS_NAME}
install_lib freebsd.zfs
make_server_root
make_zfs_volume
make_backup_dir
clean

echo "${MINECRAFT_SERVER_SERVICE_NAME}_enable=\"YES\"" >> /etc/rc.conf
service ${MINECRAFT_SERVER_SERVICE_NAME} start
