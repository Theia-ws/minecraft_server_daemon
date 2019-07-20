#!/bin/sh

cd $(dirname $0)

. ./config
. ./freebsd.zfs/FUNC_DICTIONARY_MANAGER
. ./freebsd.zfs/config.zfs

INSTALL_SOURCE_DIR=./
UNIT_DIR=/etc/rc.d
INSTALLD_UNIT_FILENAME=${MINECRAFT_SERVER_SERVICE_NAME}
SERVICE_CONFIG_DIR=/usr/local/etc/${MINECRAFT_SERVER_SERVICE_NAME}
SERVICE_LIB_DIR=/usr/local/lib/${MINECRAFT_SERVER_SERVICE_NAME}
BIN_DIR=/usr/local/bin

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

check_can_install(){
	
	endcode=0
	
	loopend=`SNAPSHOT_TARGET_VOLUME__LOOPEND`
		
	for index in `seq 0 ${loopend}`; do
		
		volume=`SNAPSHOT_TARGET_VOLUME__GET_NAME ${index}`
		mountpoint=`SNAPSHOT_TARGET_VOLUME__GET_MOUNTPOINT ${index}`
		
		result=`zfs list -o mountpoint ${volume} 2> /dev/null`
		if [ $? -eq 0 ] && [ "${result}" = "${mountpoint}" ]; then
			echo "To be created volume is existed at different mount point.\nPlease \"${volume}\" volume\'s mount point is change to \"${mountpoint}\" or delete."
			endcode=1
		fi
		
	done
	
	return ${endcode}
	
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
make_execute_user
replace_env_val common
replace_env_val freebsd
replace_env_val freebsd.zfs
install_unit freebsd
install_config
install_zfs_config
install_lib freebsd
install_lib freebsd.zfs
make_server_root
make_zfs_volume
make_backup_dir
clean

echo "${MINECRAFT_SERVER_SERVICE_NAME}_enable=\"YES\"" >> /etc/rc.conf
service ${MINECRAFT_SERVER_SERVICE_NAME} start
