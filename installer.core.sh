#!/bin/sh

. common/FUNC_COMMON

check_can_install(){
	endcode=0
	switch_execute_user "Sudo is required to install. Please input your account password." "Need root parmissions for install." ${execute_file_path} ${execute_paramator}
	if [ $? -ne 0 ]; then
		endcode=1
	fi
	return ${endcode}
}

install_dependent_package(){
	
	[ -z ${CURL_PATH} ] && CURL_PATH=$(command -v "curl" 2>/dev/null || echo "")
	[ -z ${JVM_PATH} ] && JVM_PATH=$(command -v "java" 2>/dev/null || echo "")
	[ -z ${SCREEN_PATH} ] && SCREEN_PATH=$(command -v "screen" 2>/dev/null || echo "")
	
	command -v "apt-get" > /dev/null 2>&1
	if [ $? -eq 0 ]; then
		
		apt-get update
		
		command -v "sudo" > /dev/null 2>&1
		if [ $? -ne 0 ]; then
			apt-get install -y sudo
			[ $? -ne 0 ] && return 1
		fi
		
		command -v "${CURL_PATH}" > /dev/null 2>&1
		if [ $? -ne 0 ]; then
			apt-get install -y curl
			[ $? -ne 0 ] && return 1
		fi
		
		command -v "git" > /dev/null 2>&1
		if [ $? -ne 0 ]; then
			apt-get install -y git
			[ $? -ne 0 ] && return 1
		fi
		
		command -v "jq" > /dev/null 2>&1
		if [ $? -ne 0 ]; then
			apt-get install -y jq
			[ $? -ne 0 ] && return 1
		fi
		
		command -v "${JVM_PATH}" > /dev/null 2>&1
		if [ $? -ne 0 ]; then
			apt-get install -y openjdk-21-jre-headless
			[ $? -ne 0 ] && return 1
		fi
		
		command -v "${SCREEN_PATH}" > /dev/null 2>&1
		if [ $? -ne 0 ]; then
			apt-get install -y screen
			[ $? -ne 0 ] && return 1
		fi
		
		return 0
		
	fi
	
	command -v "pkg" > /dev/null 2>&1
	if [ $? -eq 0 ]; then
		
		command -v "${CURL_PATH}" > /dev/null 2>&1
		if [ $? -ne 0 ]; then
			pkg install -y curl
			[ $? -ne 0 ] && return 1
		fi
		
		command -v "git" > /dev/null 2>&1
		if [ $? -ne 0 ]; then
			pkg install -y git
			[ $? -ne 0 ] && return 1
		fi
		
		command -v "jq" > /dev/null 2>&1
		if [ $? -ne 0 ]; then
			pkg install -y jq
			[ $? -ne 0 ] && return 1
		fi
		
		command -v "${JVM_PATH}" > /dev/null 2>&1
		if [ $? -ne 0 ]; then
			pkg install -y openjdk21-jre
			[ $? -ne 0 ] && return 1
		fi
		
		command -v "${SCREEN_PATH}" > /dev/null 2>&1
		if [ $? -ne 0 ]; then
			pkg install -y screen
			[ $? -ne 0 ] && return 1
		fi
		
		return 0
		
	fi
	
	command -v "yum" > /dev/null 2>&1
	if [ $? -eq 0 ]; then
		
		command -v "sudo" > /dev/null 2>&1
		if [ $? -ne 0 ]; then
			apt-get install -y sudo
			[ $? -ne 0 ] && return 1
		fi
		
		command -v "${CURL_PATH}" > /dev/null 2>&1
		if [ $? -ne 0 ]; then
			yum install -y curl
			[ $? -ne 0 ] && return 1
		fi
		
		command -v "git" > /dev/null 2>&1
		if [ $? -ne 0 ]; then
			yum install -y git
			[ $? -ne 0 ] && return 1
		fi
		
		command -v "jq" > /dev/null 2>&1
		if [ $? -ne 0 ]; then
			yum install -y jq
			[ $? -ne 0 ] && return 1
		fi
		
		command -v "${JVM_PATH}" > /dev/null 2>&1
		if [ $? -ne 0 ]; then
			yum install -y java-21-openjdk-headless
			[ $? -ne 0 ] && return 1
		fi
		
		command -v "${SCREEN_PATH}" > /dev/null 2>&1
		if [ $? -ne 0 ]; then
			yum install -y epel-release
			yum install -y screen
			[ $? -ne 0 ] && return 1
		fi
		
		return 0
		
	fi
	
}

replace_env_val(){
	SERVICE_CONFIG_DIR_SED=$(echo "${SERVICE_CONFIG_DIR}" | sed -e 's/\//\\\//g')
	SERVICE_LIB_DIR_SED=$(echo "${SERVICE_LIB_DIR}" | sed -e 's/\//\\\//g')
	UNIT_DIR_SED=$(echo "${UNIT_DIR}" | sed -e 's/\//\\\//g')
	BIN_DIR_SED=$(echo "${BIN_DIR}" | sed -e 's/\//\\\//g')

	[ -z ${CURL_PATH} ] && CURL_PATH=$(command -v "curl" 2>/dev/null || echo "")
	[ -z ${JVM_PATH} ] && JVM_PATH=$(command -v "java" 2>/dev/null || echo "")
	[ -z ${SCREEN_PATH} ] && SCREEN_PATH=$(command -v "screen" 2>/dev/null || echo "")
	CURL_PATH_SED=$(echo "${CURL_PATH}" | sed -e 's/\//\\\//g')
	JVM_PATH_SED=$(echo "${JVM_PATH}" | sed -e 's/\//\\\//g')
	SCREEN_PATH_SED=$(echo "${SCREEN_PATH}" | sed -e 's/\//\\\//g')

	cild_file_sed ${1} "SERVICE_CONFIG_DIR" ${SERVICE_CONFIG_DIR_SED}
	cild_file_sed ${1} "MINECRAFT_SERVER_SERVICE_NAME" ${MINECRAFT_SERVER_SERVICE_NAME}
	cild_file_sed ${1} "SERVICE_LIB_DIR" ${SERVICE_LIB_DIR_SED}
	cild_file_sed ${1} "UNIT_DIR" ${UNIT_DIR_SED}
	cild_file_sed ${1} "BIN_DIR" ${BIN_DIR_SED}
	cild_file_sed ${1} "CURL_PATH" ${CURL_PATH_SED}
	cild_file_sed ${1} "JVM_PATH" ${JVM_PATH_SED}
	cild_file_sed ${1} "SCREEN_PATH" ${SCREEN_PATH_SED}
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
	if [ -e ${BIN_DIR}/${MINECRAFT_SERVER_SERVICE_NAME} ]; then
		unlink ${BIN_DIR}/${MINECRAFT_SERVER_SERVICE_NAME}
	fi
	ln -s ${SERVICE_LIB_DIR}/${MINECRAFT_SERVER_SERVICE_NAME} ${BIN_DIR}/${MINECRAFT_SERVER_SERVICE_NAME}
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
}

service_start(){
	${BIN_DIR}/${MINECRAFT_SERVER_SERVICE_NAME} enable
	${BIN_DIR}/${MINECRAFT_SERVER_SERVICE_NAME} start
}