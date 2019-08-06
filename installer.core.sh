#!/bin/sh

check_install_user(){
	if [ `id -u` -eq 0 ]; then
		return 0
	fi
	echo "Need root parmissions for install."
	return 1
}

replace_env_val(){
	SERVICE_CONFIG_DIR_SED=`echo ${SERVICE_CONFIG_DIR} | sed -e 's/\//\\\\\//g'`
	SERVICE_LIB_DIR_SED=`echo ${SERVICE_LIB_DIR} | sed -e 's/\//\\\\\//g'`
	UNIT_DIR_SED=`echo ${UNIT_DIR} | sed -e 's/\//\\\\\//g'`
	BIN_DIR_SED=`echo ${BIN_DIR} | sed -e 's/\//\\\\\//g'`
	cild_file_sed ${1} "SERVICE_CONFIG_DIR" ${SERVICE_CONFIG_DIR_SED}
	cild_file_sed ${1} "MINECRAFT_SERVER_SERVICE_NAME" ${MINECRAFT_SERVER_SERVICE_NAME}
	cild_file_sed ${1} "SERVICE_LIB_DIR" ${SERVICE_LIB_DIR_SED}
	cild_file_sed ${1} "UNIT_DIR" ${UNIT_DIR_SED}
	cild_file_sed ${1} "BIN_DIR" ${BIN_DIR_SED}
}

install_unit(){
	[ -e ${INSTALL_SOURCE_DIR}${1}/unit ] && cp ${INSTALL_SOURCE_DIR}${1}/unit ${UNIT_DIR}/${INSTALLD_UNIT_FILENAME}
	chmod 755 ${UNIT_DIR}/${INSTALLD_UNIT_FILENAME}
}

install_config(){
	[ ! -e ${SERVICE_CONFIG_DIR} ] && mkdir -p ${SERVICE_CONFIG_DIR}
	[ -e ${INSTALL_SOURCE_DIR}config ] && cp ${INSTALL_SOURCE_DIR}config ${SERVICE_CONFIG_DIR}/${MINECRAFT_SERVER_SERVICE_NAME}
	chmod 755 ${SERVICE_CONFIG_DIR}/${MINECRAFT_SERVER_SERVICE_NAME}
}

install_lib(){
	[ ! -e ${SERVICE_LIB_DIR} ] && mkdir -p ${SERVICE_LIB_DIR}
	copy_lib common
	copy_lib ${1}
	chmod 755 ${SERVICE_LIB_DIR}/*
	[ ! -e ${BIN_DIR}/${MINECRAFT_SERVER_SERVICE_NAME} ] && ln -s ${SERVICE_LIB_DIR}/${MINECRAFT_SERVER_SERVICE_NAME} ${BIN_DIR}/${MINECRAFT_SERVER_SERVICE_NAME}
}

copy_lib(){
	ls ${INSTALL_SOURCE_DIR}${1}/FUNC_* > /dev/null 2>&1
	[ $? -eq 0 ] && cp ${INSTALL_SOURCE_DIR}${1}/FUNC_* ${SERVICE_LIB_DIR}/
	ls ${INSTALL_SOURCE_DIR}${1}/EXEC_* > /dev/null 2>&1
	[ $? -eq 0 ] && cp ${INSTALL_SOURCE_DIR}${1}/EXEC_* ${SERVICE_LIB_DIR}/
	[ -e ${INSTALL_SOURCE_DIR}${1}/master ] && cp ${INSTALL_SOURCE_DIR}${1}/master ${SERVICE_LIB_DIR}/${MINECRAFT_SERVER_SERVICE_NAME}
}

make_server_root(){
	[ ! -e ${MINECRAFT_SERVER_ROOT} ] && mkdir -p ${MINECRAFT_SERVER_ROOT}
	[ ! -e ${MINECRAFT_SERVER_ROOT}/eula.txt ] && echo "eula=${eula}" > ${MINECRAFT_SERVER_ROOT}/eula.txt
	chown -R ${MINECRAFT_SERVER_EXECUTE_USER}:${MINECRAFT_SERVER_EXECUTE_GROUP} ${MINECRAFT_SERVER_ROOT}
}

clean(){
	${SERVICE_LIB_DIR}/${MINECRAFT_SERVER_SERVICE_NAME} build
	rm -rf `pwd`
}
