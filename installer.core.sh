#!/bin/sh

. common/FUNC_COMMON

DPPKG_JSON="./dppkg.json"
PKGER_JSON="./pkger.json"

check_can_install(){
	endcode=0
	switch_execute_user "Sudo is required to install. Please input your account password." "Need root permissions for install." ${execute_file_path} ${execute_paramator}
	if [ $? -ne 0 ]; then
		endcode=1
	fi
	return ${endcode}
}

install_dep_pkgs(){
	get_os_info
    if ! command -v "jq" >/dev/null 2>&1; then
        case "${PKG_MGR_NAME}" in
            APT)
                apt-get -y update
                ;;
            *)
                ;;
        esac
        PKG_NAME="jq"
        PKG_MGR_PKG_NAME="jq"
        echo "--------------------------------------------------"
        echo ">>> Installing package: ${PKG_NAME}"
        case "${PKG_MGR_NAME}" in
            APK)
                apk add jq
                ;;
            APT)
                apt-get -y install jq
                ;;
            PKG)
                pkg install -y jq
                ;;
            YUM)
                yum -y install jq
                ;;
            *)
                echo "[ERROR] Unsupported package manager: ${PKG_MGR_NAME}"
                return 1
                ;;
        esac
    fi

    rep_update
    
    tmpfile=$(mktemp)
    jq -c '.[]' "${DPPKG_JSON}" > "${tmpfile}"
    while IFS= read -r PKG_JSON; do
        install_dep_pkg "${PKG_JSON}" || {
            rm -f "${tmpfile}"
            return 1
        }
    done < "${tmpfile}"
    rm -f "${tmpfile}"
    
}

get_os_info(){
    UNAME_M=$(uname -m)
    UNAME_OS_STRING=$(uname -s | tr '[:upper:]' '[:lower:]')
    UNAME_S=$(uname -s)
    case "$UNAME_S" in
        Linux)
            if [ -f /etc/os-release ]; then
                . /etc/os-release
                DIST_ID=${ID}
                DIST_LIKE=${ID_LIKE}
                if [ "$DIST_ID" = "alpine" ]; then
                    PKG_MGR_NAME="APK"
                elif echo "${DIST_LIKE}" | grep -q "debian"; then
                    PKG_MGR_NAME="APT"
                elif [ "${DIST_ID}" = "debian" ]; then
                    PKG_MGR_NAME="APT"
                elif echo "${DIST_LIKE}" | grep -Eqw "rhel|fedora"; then
                    PKG_MGR_NAME="YUM"
                elif [ "${DIST_ID}" = "fedora" ]; then
                    PKG_MGR_NAME="YUM"
                else
                    return 1
                fi
            else
                return 1
            fi
            ;;
        FreeBSD)
            PKG_MGR_NAME="PKG"
            DIST_ID="FreeBSD"
            ;;
        *)
            return 1
            ;;
    esac
}

install_dep_pkg(){
    PKG_JSON="$1"
    PKG_NAME=$(get_json_value "Name" "${PKG_JSON}")

    if [ -z "${PKG_NAME}" ]; then
        echo "[ERROR] Package name not found in JSON: ${PKG_JSON}"
        return 1
    elif command -v "${PKG_NAME}" >/dev/null 2>&1; then
        echo "[INFO] ${PKG_NAME} is already installed."
        return 0
    fi

    echo "--------------------------------------------------"
    echo ">>> Installing package: ${PKG_NAME}"

    CAN_USE_OS_PKG=$(get_json_value "CAN_USE_OS_PKG" "${PKG_JSON}")
    [ "${CAN_USE_OS_PKG}" = "true" ] && CAN_USE_OS_PKG=1 || CAN_USE_OS_PKG=0
    PKG_VERSION=$(get_json_value "PKG_VERSION" "${PKG_JSON}")

    if [ "${CAN_USE_OS_PKG}" -eq 1 ]; then
        echo "[INFO] Installing ${PKG_NAME} using OS package manager."
        PKG_MGR_PKG_NAME=$(get_json_value "PKG_MGR_PKG_NAME" "${PKG_JSON}")
        if [ -z "${PKG_MGR_PKG_NAME}" ]; then
            echo "[ERROR] Package manager package name not found for ${PKG_NAME}"
            return 1
        fi
        install_pkg "${PKG_MGR_PKG_NAME}"
        if [ $? -ne 0 ]; then
            echo "[ERROR] Failed to install ${PKG_NAME} using OS package manager."
            return 1
        fi
        echo "[INFO] Successfully installed ${PKG_NAME} using OS package manager."
        return 0
    else
        echo "[INFO] Installing ${PKG_NAME} manually."
        
        PKG_URL=$(get_json_value "PKG_URL" "${PKG_JSON}")
        if [ -z "${PKG_URL}" ]; then
            echo "[ERROR] Package URL not found for ${PKG_NAME}"
            return 1
        fi
        TMP_FILE_PATH=$(get_json_value "TMP_FILE_PATH" "${PKG_JSON}")
        if [ -z "${TMP_FILE_PATH}" ]; then
            echo "[ERROR] Temporary file path not found for ${PKG_NAME}"
            return 1
        fi
        DOWNLOAD_CMD=$(get_json_value "DOWNLOAD_CMD" "${PKG_JSON}")
        if [ -z "${DOWNLOAD_CMD}" ]; then
            echo "[ERROR] Download command not found for ${PKG_NAME}"
            return 1
        fi
        echo "[INFO] Downloading ${PKG_NAME} from ${PKG_URL}"
        ${DOWNLOAD_CMD}
        if [ $? -ne 0 ]; then
            echo "[ERROR] Failed to download ${PKG_NAME}"
            return 1
        fi
        echo "[INFO] Download completed for ${PKG_NAME}"

        INSTALL_PATH=$(get_json_value "INSTALL_PATH" "${PKG_JSON}")
        if [ -z "${INSTALL_PATH}" ]; then
            echo "[ERROR] Install path not found for ${PKG_NAME}"
            return 1
        fi
        MAKE_INSTALL_PATH_CMD=$(get_json_value "MAKE_INSTALL_PATH_CMD" "${PKG_JSON}")
        if [ -z "${MAKE_INSTALL_PATH_CMD}" ]; then
            echo "[ERROR] Make install path command not found for ${PKG_NAME}"
            return 1
        fi
        echo "[INFO] Creating install directory for ${PKG_NAME}"
        ${MAKE_INSTALL_PATH_CMD}
        if [ $? -ne 0 ]; then
            echo "[ERROR] Failed to create install directory for ${PKG_NAME}"
            return 1
        fi

        DPKG_CMD=$(get_json_value "DPKG_CMD" "${PKG_JSON}")
        if [ -z "${DPKG_CMD}" ]; then
            echo "[ERROR] DPKG command not found for ${PKG_NAME}"
            return 1
        fi
        echo "[INFO] Installing ${PKG_NAME}"
        ${DPKG_CMD}
        if [ $? -ne 0 ]; then
            echo "[ERROR] Failed to install ${PKG_NAME}"
            return 1
        fi
        echo "[INFO] Installation completed for ${PKG_NAME}"

        TAR_ROOT=$(eval $(get_json_value "TAR_ROOT" "${PKG_JSON}"))

        RM_TMP_FILE_CMD=$(get_json_value "RM_TMP_FILE_CMD" "${PKG_JSON}")
        if [ -z "${RM_TMP_FILE_CMD}" ]; then
            echo "[ERROR] Remove temp file command not found for ${PKG_NAME}"
            return 1
        fi
        echo "[INFO] Cleaning up temporary files for ${PKG_NAME}"
        ${RM_TMP_FILE_CMD}
        if [ $? -ne 0 ]; then
            echo "[WARNING] Failed to remove temporary files for ${PKG_NAME}"
            # 警告だが、インストールは成功しているので続行
        fi

        export $(echo "${PKG_NAME}" | tr '[:lower:]' '[:upper:]')_PATH=$(get_json_value "EXECUTION_BIN" "${PKG_JSON}")

        echo "[INFO] Successfully installed ${PKG_NAME} manually."
        return 0
    fi
}

rep_update(){
    case "${PKG_MGR_NAME}" in
        APK | APT | PKG | YUM)
            REP_UPDATE_CMD=$(jq --arg pkg_mgr "${PKG_MGR_NAME}" -r '.["REP_UPDATE"][$pkg_mgr]' "${PKGER_JSON}")
            ${REP_UPDATE_CMD}
            ;;
        *)
            echo "[ERROR] Unsupported package manager: ${PKG_MGR_NAME}"
            return 1
            ;;
    esac
}

install_pkg(){
    PKG_MGR_PKG_NAME="$1"
    case "${PKG_MGR_NAME}" in
        APK | APT | PKG | YUM)
            INSTALL_CMD=$(jq --arg pkg_mgr "${PKG_MGR_NAME}" -r '.["INSTALL"][$pkg_mgr]' "${PKGER_JSON}")
            INSTALL_CMD=$(echo "$INSTALL_CMD" | sed "s/{PKG_MGR_PKG_NAME}/${PKG_MGR_PKG_NAME}/g")
            ${INSTALL_CMD}
            ;;
        *)
            echo "[ERROR] Unsupported package manager: ${PKG_MGR_NAME}"
            return 1
            ;;
    esac
}

get_json_value(){
    VAR_NAME="$1"
    PKG_JSON="$2"
    VAR_VALUE=$(echo "${PKG_JSON}" | jq --arg os "${UNAME_OS_STRING}" --arg dist "${DIST_ID}" --arg var "${VAR_NAME}" -r '.[$os][$dist][$var] // .[$os]["_common"][$var] // .["_common"][$var] // .[$var] // empty')
    VAR_VALUE=$(echo "${VAR_VALUE}" | sed "s#{PKG_VERSION}#${PKG_VERSION}#g" | sed "s#{INSTALL_PATH}#${INSTALL_PATH}#g" | sed "s#{TMP_FILE_PATH}#${TMP_FILE_PATH}#g" | sed "s#{PKG_URL}#${PKG_URL}#g" | sed "s#{TAR_ROOT}#${TAR_ROOT}#g" | sed "s#{UNAME_OS_STRING}#${UNAME_OS_STRING}#g" | sed "s#{UNAME_M}#${UNAME_M}#g")
    echo "${VAR_VALUE}"
}

replace_env_val(){
	SERVICE_CONFIG_DIR_SED=$(echo "${SERVICE_CONFIG_DIR}" | sed -e 's/\//\\\//g')
	SERVICE_LIB_DIR_SED=$(echo "${SERVICE_LIB_DIR}" | sed -e 's/\//\\\//g')
	UNIT_DIR_SED=$(echo "${UNIT_DIR}" | sed -e 's/\//\\\//g')
	BIN_DIR_SED=$(echo "${BIN_DIR}" | sed -e 's/\//\\\//g')

	[ -z ${CURL_PATH} ] && CURL_PATH=$(command -v "curl" 2>/dev/null || echo "")
	[ -z ${JAVA_PATH} ] && JAVA_PATH=$(command -v "java" 2>/dev/null || echo "")
    [ -z ${SUDO_PATH} ] && SUDO_PATH=$(command -v "sudo" 2>/dev/null || echo "")
	[ -z ${TMUX_PATH} ] && TMUX_PATH=$(command -v "tmux" 2>/dev/null || echo "")
	CURL_PATH_SED=$(echo "${CURL_PATH}" | sed -e 's/\//\\\//g')
	JAVA_PATH_SED=$(echo "${JAVA_PATH}" | sed -e 's/\//\\\//g')
    SUDO_PATH_SED=$(echo "${SUDO_PATH}" | sed -e 's/\//\\\//g')
	TMUX_PATH_SED=$(echo "${TMUX_PATH}" | sed -e 's/\//\\\//g')

	cild_file_sed ${1} "SERVICE_CONFIG_DIR" ${SERVICE_CONFIG_DIR_SED}
	cild_file_sed ${1} "MINECRAFT_SERVER_SERVICE_NAME" ${MINECRAFT_SERVER_SERVICE_NAME}
    cild_file_sed ${1} "MINECRAFT_SERVER_EXECUTE_USER" ${MINECRAFT_SERVER_EXECUTE_USER}
	cild_file_sed ${1} "SERVICE_LIB_DIR" ${SERVICE_LIB_DIR_SED}
	cild_file_sed ${1} "UNIT_DIR" ${UNIT_DIR_SED}
	cild_file_sed ${1} "BIN_DIR" ${BIN_DIR_SED}
	cild_file_sed ${1} "CURL_PATH" ${CURL_PATH_SED}
	cild_file_sed ${1} "JAVA_PATH" ${JAVA_PATH_SED}
    cild_file_sed ${1} "SUDO_PATH" ${SUDO_PATH_SED}
	cild_file_sed ${1} "TMUX_PATH" ${TMUX_PATH_SED}
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