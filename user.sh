#!/usr/bin/env bash

# shellcheck disable=SC2034
# shellcheck disable=SC2059

# ########## ######### ######### ######### ######### ######### ######### #######
# 工作模式
# ########## ######### ######### ######### ######### ######### ######### #######

set -euE -o pipefail

IFS=$'\n\t'

(
  # ########## ######### ######### ######### ######### ######### ######### #####
  # 定义 常量
  # ########## ######### ######### ######### ######### ######### ######### #####

  declare -ar ARR_ENV_COMMAND_DEPENDENT=(
    'command'
    'printf'
  )
  declare -ir INT_ENV_BASH_VERSINFO_MAJOR=5
  declare -ir INT_ERR_SYS_FALSE=180
  declare -ir INT_ERR_SYS_OK=0
  declare -ir INT_ERR_SYS_TRUE=150
  declare -ir INT_ERR_SYS_WARN=170
  declare -r STR_ENV_BOOL_OPTION_NO='no'
  declare -r STR_ENV_BOOL_OPTION_YES='yes'
  declare -r STR_BIZ_PARSE_OPTION_SEPARATOR='='
  declare -r STR_BIZ_PASSWORD_PFX='pw@'
  declare -r STR_BIZ_SCRIPT_VERSION='1.1.0'
  declare -r STR_BIZ_SH_TYPE='/bin/bash'
  declare -r STR_ENV_ROUTER_HELP='ROUTER_HELP'
  declare -r STR_ENV_ROUTER_RUN='ROUTER_RUN'
  declare -r STR_ENV_ROUTER_VERSION='ROUTER_VERSION'
  declare -r STR_TIP_BIZ_PARSE_OPTION_SEPARATOR='选项和参数 MUST NOT 包含 \"%s\" 字符.'
  declare -r STR_TIP_ENV_VALIDATE_BASH_COMMAND='当前环境非 Bash, MUST 以该解释器运行.'
  declare -r STR_TIP_ENV_VALIDATE_BASH_VERSION='当前环境 Bash 版本号 MUST >= %d.'
  declare -r STR_TIP_ENV_VALIDATE_COMMAND='当前脚本 MUST 依赖的命令缺失: "%s".'
  declare -r STR_TIP_ENV_VALIDATE_ROUTER='选项和参数解析失败.'

  # ########## ######### ######### ######### ######### ######### ######### #####
  # 定义 变量
  # ########## ######### ######### ######### ######### ######### ######### #####

  declare strBizIsAdmin='yes'
  declare strBizKeyPublic=''
  declare strBizUserGroup='keeper91'
  declare strBizUserName='keeper91'
  declare strTipBizParseOptionSeparator=''
  declare strTipEnvValidateBashCommand=''
  declare strTipEnvValidateBashVersion=''

  # ########## ######### ######### ######### ######### ######### ######### #####
  # 整理 变量
  # ########## ######### ######### ######### ######### ######### ######### #####

  read -r -d '' strBizKeyPublic << 'EOF' || true
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPwWyuNYd1wV/18aBJ8bWyf6aWTycOwpIpOj9BeL+CZO yemaomiaomiao@163.com
EOF

  printf -v strTipBizParseOptionSeparator "${STR_TIP_BIZ_PARSE_OPTION_SEPARATOR}" "${STR_BIZ_PARSE_OPTION_SEPARATOR}"
  printf -v strTipEnvValidateBashCommand "${STR_TIP_ENV_VALIDATE_BASH_COMMAND}" ''
  printf -v strTipEnvValidateBashVersion "${STR_TIP_ENV_VALIDATE_BASH_VERSION}" "${INT_ENV_BASH_VERSINFO_MAJOR}"

  # ########## ######### ######### ######### ######### ######### ######### #####
  # 定义 方法
  # ########## ######### ######### ######### ######### ######### ######### #####

  fun_biz_user_check_group() {
    declare strBizUserGroupCurrent=''
    declare -A arrCmdArgFmd=()

    fun_atm_var_copy "${1}" arrCmdArgFmd

    strBizUserGroupCurrent="${arrCmdArgFmd['group']:-${arrCmdArgFmd['name']:-${strBizUserGroup}}}"

    if ! (getent group "${strBizUserGroupCurrent}" > /dev/null 2>&1); then
      fun_log "${INT_ERR_SYS_TRUE}" "本系统 ${strBizUserGroupCurrent} 组名可新增."

      return "${INT_ERR_SYS_OK}"
    else
      fun_log "${INT_ERR_SYS_WARN}" "本系统 ${strBizUserGroupCurrent} 组名已存在."

      return "${INT_ERR_SYS_WARN}"
    fi
  }

  fun_biz_user_check_os() {
    declare strNrfOsIdTitle=''
    declare strOsId=''
    declare strOsVersionId=''
    declare strOsVersionIdMajor=''
    declare -i intErrSysCode="${INT_ERR_SYS_TRUE}"

    strOsId=$(grep '^ID=' /etc/os-release 2> /dev/null | cut -d= -f2 | tr -d '"' | tr -d "'")
    strOsId=${strOsId:-UnknownOsId}
    strOsVersionId=$(grep '^VERSION_ID=' /etc/os-release 2> /dev/null | cut -d= -f2 | tr -d '"' | tr -d "'")
    strOsVersionId=${strOsVersionId:-UnknownOsVersionId}

    strOsVersionIdMajor="${strOsVersionId%%.*}"

    fun_atm_str_case "${strOsId}" strNrfOsIdTitle

    case "${strOsId}" in
    ubuntu)
      (("${strOsVersionIdMajor}" >= 24)) || {
        intErrSysCode="${INT_ERR_SYS_FALSE}"
      }
      ;;
    debian)
      (("${strOsVersionIdMajor}" >= 12)) || {
        intErrSysCode="${INT_ERR_SYS_FALSE}"
      }
      ;;
    *)
      intErrSysCode="${INT_ERR_SYS_FALSE}"
      ;;
    esac

    fun_log "${intErrSysCode}" "OS 目前已支持: Ubuntu 26+ 或 Debian 12+, 当前: ${strNrfOsIdTitle} ${strOsVersionId}."

    return "${intErrSysCode}"
  }

  fun_biz_user_check_parse_option_separator() {
    declare -n strIptCmdArg="${1}"

    [[ "${strIptCmdArg}" != *"${STR_BIZ_PARSE_OPTION_SEPARATOR}"* ]] || {
      fun_log "${INT_ERR_SYS_FALSE}" "${strTipBizParseOptionSeparator}"

      return "${INT_ERR_SYS_FALSE}"
    }

    return "${INT_ERR_SYS_OK}"
  }

  fun_biz_user_check_privilege() {
    if sudo -n -v > /dev/null 2>&1; then
      fun_log "${INT_ERR_SYS_TRUE}" '本脚本 MUST 提前激活 sudo 权限以静默运行.'

      return "${INT_ERR_SYS_OK}"
    else
      fun_log "${INT_ERR_SYS_FALSE}" '本脚本 MUST 提前激活 sudo 权限以静默运行.'

      return "${INT_ERR_SYS_FALSE}"
    fi
  }

  fun_biz_user_check_sshd() {
    if systemctl is-active --quiet sshd || systemctl is-active --quiet ssh; then
      fun_log "${INT_ERR_SYS_TRUE}" '本系统 SSHD 服务已激活.'

      return "${INT_ERR_SYS_OK}"
    else
      fun_log "${INT_ERR_SYS_WARN}" '本系统 SSHD 服务未激活.'

      return "${INT_ERR_SYS_WARN}"
    fi
  }

  fun_biz_user_check_user() {
    declare strBizUserNameCurrent=''
    declare -A arrCmdArgFmd=()

    fun_atm_var_copy "${1}" arrCmdArgFmd

    strBizUserNameCurrent="${arrCmdArgFmd['name']:-${strBizUserName}}"

    if ! (id "${strBizUserNameCurrent}" > /dev/null 2>&1); then
      fun_log "${INT_ERR_SYS_TRUE}" "本系统 ${strBizUserNameCurrent} 用户可新增."

      return "${INT_ERR_SYS_OK}"
    else
      fun_log "${INT_ERR_SYS_WARN}" "本系统 ${strBizUserNameCurrent} 用户已存在."

      return "${INT_ERR_SYS_WARN}"
    fi
  }

  fun_biz_user_create_ssh() {
    declare strBizKeyContentCurrent=''
    declare strBizKeyDir=''
    declare strBizKeyFile=''
    declare strBizKeyPublicCurrent=''
    declare strBizUserNameCurrent=''
    declare -A arrCmdArgFmd=()

    fun_atm_var_copy "${1}" arrCmdArgFmd

    strBizKeyPublicCurrent="${arrCmdArgFmd['public']:-${strBizKeyPublic}}"
    strBizUserNameCurrent="${arrCmdArgFmd['name']:-${strBizUserName}}"

    strBizKeyDir="/home/${strBizUserNameCurrent}/.ssh"
    strBizKeyFile="/home/${strBizUserNameCurrent}/.ssh/authorized_keys"

    if [[ -f "${strBizKeyPublicCurrent}" ]]; then
      strBizKeyContentCurrent="$(cat "${strBizKeyPublicCurrent}")"
    else
      strBizKeyContentCurrent="${strBizKeyPublicCurrent}"
    fi

    [[ "${strBizKeyContentCurrent}" == ssh-* ]] || {
      fun_log "${INT_ERR_SYS_WARN}" "本脚本 SSH 公钥内容不合法."

      return "${INT_ERR_SYS_WARN}"
    }

    sudo mkdir -p "${strBizKeyDir}"
    sudo chmod 700 "${strBizKeyDir}"

    if sudo grep -qF -- "${strBizKeyContentCurrent}" "${strBizKeyFile}" 2> /dev/null; then
      fun_log "${INT_ERR_SYS_WARN}" '该用户 SSH 公钥内容已存在.'

      return "${INT_ERR_SYS_WARN}"
    fi

    sudo tee -a "${strBizKeyFile}" > /dev/null <<< "${strBizKeyContentCurrent}"
    sudo chmod 600 "${strBizKeyFile}"

    sudo chown -R "${strBizUserNameCurrent}:${strBizUserNameCurrent}" "${strBizKeyDir}"

    fun_log "${INT_ERR_SYS_OK}" "本脚本 SSH 公钥内容已部署."
  }

  fun_biz_user_create_user() {
    declare strBizIsAdminCurrent=''
    declare strBizUserGroupCurrent=''
    declare strBizUserNameCurrent=''
    declare strBizUserPasswordCurrent=''
    declare -A arrCmdArgFmd=()

    fun_atm_var_copy "${1}" arrCmdArgFmd

    strBizIsAdminCurrent="${arrCmdArgFmd['admin']:-${strBizIsAdmin}}"
    strBizUserGroupCurrent="${arrCmdArgFmd['group']:-${arrCmdArgFmd['name']:-${strBizUserGroup}}}"
    strBizUserNameCurrent="${arrCmdArgFmd['name']:-${strBizUserName}}"
    strBizUserPasswordCurrent="${STR_BIZ_PASSWORD_PFX}${strBizUserNameCurrent}"

    ! (id "${strBizUserNameCurrent}" > /dev/null 2>&1) || {
      fun_log "${INT_ERR_SYS_WARN}" "本脚本 ${strBizUserNameCurrent} 用户已跳过."

      return "${INT_ERR_SYS_WARN}"
    }

    getent group "${strBizUserGroupCurrent}" > /dev/null 2>&1 || {
      sudo groupadd "${strBizUserGroupCurrent}"
    }

    sudo useradd -m -s "${STR_BIZ_SH_TYPE}" -g "${strBizUserGroupCurrent}" "${strBizUserNameCurrent}"

    if [[ "${strBizIsAdminCurrent}" == "${STR_ENV_BOOL_OPTION_YES}" ]]; then
      sudo usermod -aG sudo "${strBizUserNameCurrent}"
    fi

    sudo chpasswd <<< "${strBizUserNameCurrent}:${strBizUserPasswordCurrent}"

    sudo chage -d 0 "${strBizUserNameCurrent}"

    sudo chmod 750 "/home/${strBizUserNameCurrent}"

    fun_log \
      "${INT_ERR_SYS_OK}" \
      "本脚本 ${strBizUserNameCurrent} 用户已创建, ${strBizUserPasswordCurrent} 密码已生成(首次登录 MUST 修改)."
  }

  fun_biz_user_parse_option() {
    declare -n arrIptCmdArg="${1}"

    declare item=''
    declare strNrfValue=''
    declare -i intNrfIndex=0
    declare -A arrTmpCmdArgFmd=()
    declare -A arrTmpCmdOptionFmd=()

    arrTmpCmdOptionFmd['router']="${STR_ENV_ROUTER_RUN}"

    while (("${intNrfIndex}" < "${#arrIptCmdArg[@]}")); do
      item="${arrIptCmdArg[intNrfIndex]}"

      case "${item}" in
      -h | -H | --help)
        arrTmpCmdOptionFmd['router']="${STR_ENV_ROUTER_HELP}"
        ;;
      -v | -V | --version)
        arrTmpCmdOptionFmd['router']="${STR_ENV_ROUTER_VERSION}"
        ;;
      -a | --admin)
        fun_biz_user_parse_option_value 'admin' "${!arrIptCmdArg}" intNrfIndex strNrfValue || return $?
        arrTmpCmdArgFmd['admin']="${strNrfValue}"
        ;;
      -g | --group)
        fun_biz_user_parse_option_value 'group' "${!arrIptCmdArg}" intNrfIndex strNrfValue || return $?
        arrTmpCmdArgFmd['group']="${strNrfValue}"
        ;;
      -n | --name)
        fun_biz_user_parse_option_value 'name' "${!arrIptCmdArg}" intNrfIndex strNrfValue || return $?
        arrTmpCmdArgFmd['name']="${strNrfValue}"
        ;;
      -p | --public)
        fun_biz_user_parse_option_value 'public' "${!arrIptCmdArg}" intNrfIndex strNrfValue || return $?
        arrTmpCmdArgFmd['public']="${strNrfValue}"
        ;;
      *)
        arrTmpCmdOptionFmd['router']=''

        fun_log "${INT_ERR_SYS_FALSE}" "${STR_TIP_ENV_VALIDATE_ROUTER}"

        return "${INT_ERR_SYS_FALSE}"
        ;;
      esac

      intNrfIndex=$(("${intNrfIndex}" + 1))
    done

    fun_atm_var_copy arrTmpCmdOptionFmd "${2}"
    fun_atm_var_copy arrTmpCmdArgFmd "${3}"
  }

  fun_biz_user_parse_option_value() {
    declare -n arrIptCmdArg="${2}"

    declare item=''
    declare strIptOptionKey="${1}"
    declare -a arrTmpValue=()
    declare -i intIptCmdArgIndexNext=$(("${3}" + 1))

    while (("${intIptCmdArgIndexNext}" < "${#arrIptCmdArg[@]}")); do
      item="${arrIptCmdArg[intIptCmdArgIndexNext]}"

      case "${item}" in
      -*)
        break
        ;;
      *) ;;
      esac

      case "${strIptOptionKey}" in
      admin)
        fun_biz_user_check_parse_option_separator item || return $?

        [[ "${item}" =~ ^("${STR_ENV_BOOL_OPTION_YES}"|"${STR_ENV_BOOL_OPTION_NO}")$ ]] || {
          fun_log \
            "${INT_ERR_SYS_FALSE}" \
            "${strIptOptionKey} 参数 MUST 是以下选项: ${STR_ENV_BOOL_OPTION_YES} 或 ${STR_ENV_BOOL_OPTION_NO}."

          return "${INT_ERR_SYS_FALSE}"
        }
        ;;
      group)
        fun_biz_user_check_parse_option_separator item || return $?

        fun_atm_str_is_alpha_num_underscore_dash "${item}" || {
          fun_log "${INT_ERR_SYS_FALSE}" "${strIptOptionKey} 参数 MUST 是以下字符的组合: 字母, 数字, 下划线和中划线."

          return "${INT_ERR_SYS_FALSE}"
        }
        ;;
      name)
        fun_biz_user_check_parse_option_separator item || return $?

        fun_atm_str_is_alpha_num_underscore_dash "${item}" || {
          fun_log "${INT_ERR_SYS_FALSE}" "${strIptOptionKey} 参数 MUST 是以下字符的组合: 字母, 数字, 下划线和中划线."

          return "${INT_ERR_SYS_FALSE}"
        }
        ;;
      public)
        fun_biz_user_check_parse_option_separator item || return $?

        [[ -f "${item}" || "${item}" == ssh-* ]] || {
          fun_log "${INT_ERR_SYS_FALSE}" "${strIptOptionKey} 参数 MUST 是以下选项: 有效的文件路径或公钥字符串."

          return "${INT_ERR_SYS_FALSE}"
        }
        ;;
      *) ;;
      esac

      case "${item}" in
      *)
        arrTmpValue+=("${item}")

        intIptCmdArgIndexNext=$(("${intIptCmdArgIndexNext}" + 1))
        ;;
      esac
    done

    case "${strIptOptionKey}" in
    admin | group | name | public)
      [[ "${#arrTmpValue[@]}" -eq 1 ]] || {
        fun_log "${INT_ERR_SYS_FALSE}" "${strIptOptionKey} 参数 MUST 有且仅有 1 个."

        return "${INT_ERR_SYS_FALSE}"
      }
      ;;
    *) ;;
    esac

    printf -v "${3}" '%d' $(("${intIptCmdArgIndexNext}" - 1))
    printf -v "${4}" '%s' "$(
      IFS="${STR_BIZ_PARSE_OPTION_SEPARATOR}"
      echo "${arrTmpValue[*]}"
    )"
  }

  fun_biz_user_show_help() {
    declare strEnvBashSource="${BASH_SOURCE[0]}"
    declare strTxtHelp=''

    read -r -d '' strTxtHelp << 'EOF' || true
Usage:
  ____STR_SYS_BASH_SOURCE____ [OPTION] [ARGUMENT]

Description:
  创建 Ubuntu/Debian 用户账号, 配置 SSH 公钥.

Options & Arguments:
  -h, -H, --help           显示脚本帮助文档
  -v, -V, --version        显示脚本版本号
  -a, --admin <yes|no>     是否赋予 sudo 管理员权限 (默认: yes)
  -g, --group <组名>       指定用户主组 (默认: keeper)
  -n, --name <用户名>      指定用户名 (默认: keeper)
  -p, --public <公钥/路径> 指定 SSH 免密登录 pub 文件路径 OR 公钥字符串 (默认: ssh-ed25519)

Examples:
  $ ____STR_SYS_BASH_SOURCE____

  $ ____STR_SYS_BASH_SOURCE____ \
    -a yes \
    -g keeper \
    -n keeper \
    -p 'ssh-ed25519 XXX'

Remarks:
1) OS 版本要求: Ubuntu 24+ / Debian 12+
2) Bash 版本要求: 5+
3) 脚本: MUST 提前激活 sudo 权限以静默运行
4) 用户首次登录: MUST 修改密码
EOF

    strTxtHelp="${strTxtHelp//____STR_SYS_BASH_SOURCE____/${strEnvBashSource}}"

    printf '%s\n' "${strTxtHelp}"
  }

  fun_biz_user_show_version() {
    declare strTxtVersion=''

    read -r -d '' strTxtVersion << 'EOF' || true
____STR_BIZ_SCRIPT_VERSION____
EOF

    strTxtVersion="${strTxtVersion//____STR_BIZ_SCRIPT_VERSION____/${STR_BIZ_SCRIPT_VERSION}}"

    printf '%s\n' "${strTxtVersion}"
  }

  main() {
    local -a arrPssCmdArg=()
    local -A arrNrfCmdArgFmd=()
    local -A arrNrfCmdOptionFmd=()
    local -A arrPssCmdArgFmd=()
    local -A arrPssCmdOptionFmd=()

    arrPssCmdArg=("${@}")
    arrNrfCmdArgFmd=()
    arrNrfCmdOptionFmd=()
    arrPssCmdArgFmd=()
    arrPssCmdOptionFmd=()

    fun_env_validate_bash_command || return $?
    fun_env_validate_bash_version || return $?
    fun_env_validate_command || return $?

    fun_biz_user_parse_option arrPssCmdArg arrNrfCmdOptionFmd arrNrfCmdArgFmd || return $?

    case "${arrNrfCmdOptionFmd['router']:-}" in
    "${STR_ENV_ROUTER_HELP}")
      fun_biz_user_show_help
      ;;
    "${STR_ENV_ROUTER_VERSION}")
      fun_biz_user_show_version
      ;;
    "${STR_ENV_ROUTER_RUN}")
      fun_atm_var_copy arrNrfCmdArgFmd arrPssCmdArgFmd

      fun_biz_user_check_os || return $?
      fun_biz_user_check_sshd && true
      fun_biz_user_check_privilege || return $?
      fun_biz_user_check_user arrPssCmdArgFmd && true
      fun_biz_user_check_group arrPssCmdArgFmd && true

      fun_biz_user_create_user arrPssCmdArgFmd && true
      fun_biz_user_create_ssh arrPssCmdArgFmd && true
      ;;
    *)
      return "${INT_ERR_SYS_FALSE}"
      ;;
    esac
  }

  fun_atm_str_case() {
    printf -v "${2}" '%s' "${1^}"
  }

  fun_atm_str_is_alpha_num_underscore_dash() {
    [[ "${1}" =~ ^[a-zA-Z0-9_-]+$ ]]
  }

  fun_atm_var_copy() {
    declare -n mxdIptVarSource="${1}"
    declare -n mxdIptVarTarget="${2}"

    declare key=''
    declare strVarAttr=''

    strVarAttr="$(declare -p "${!mxdIptVarSource}" 2> /dev/null)"

    if [[ "${strVarAttr}" == "declare -A"* ]]; then
      mxdIptVarTarget=()
      for key in "${!mxdIptVarSource[@]}"; do
        mxdIptVarTarget["${key}"]="${mxdIptVarSource[${key}]}"
      done
    else
      mxdIptVarTarget=("${mxdIptVarSource[@]}")
    fi
  }

  fun_env_validate_bash_command() {
    [[ -n "${BASH_VERSION:-}" ]] || {
      fun_log "${INT_ERR_SYS_FALSE}" "${strTipEnvValidateBashCommand}"

      return "${INT_ERR_SYS_FALSE}"
    }

    return "${INT_ERR_SYS_OK}"
  }

  fun_env_validate_bash_version() {
    [[ "${BASH_VERSINFO[0]:-}" -ge "${INT_ENV_BASH_VERSINFO_MAJOR}" ]] || {
      fun_log "${INT_ERR_SYS_FALSE}" "${strTipEnvValidateBashVersion}"

      return "${INT_ERR_SYS_FALSE}"
    }

    return "${INT_ERR_SYS_OK}"
  }

  fun_env_validate_command() {
    declare strEnvCommand=''
    declare strEnvCommandMissed=''
    declare strTmpCommand=''
    declare -a arrEnvCommandMissed=()

    for strEnvCommand in "${ARR_ENV_COMMAND_DEPENDENT[@]}"; do
      command -v "${strEnvCommand}" > /dev/null 2>&1 || arrEnvCommandMissed+=("${strEnvCommand}")
    done

    [[ ${#arrEnvCommandMissed[@]} -eq 0 ]] || {
      strEnvCommandMissed=$(
        IFS=','
        declare strTmpCommand="${arrEnvCommandMissed[*]}"
        printf '%s' "${strTmpCommand//,/$', '}"
      )

      printf -v strTipEnvValidateBashVersion "${STR_TIP_ENV_VALIDATE_COMMAND}" "${strEnvCommandMissed}"

      fun_log "${INT_ERR_SYS_FALSE}" "${strTipEnvValidateBashVersion}"

      return "${INT_ERR_SYS_FALSE}"
    }

    return "${INT_ERR_SYS_OK}"
  }

  fun_log() {
    declare -ir INT_FUN_PRM_COUNT_EXPECTED=2
    declare -r REG_NUM_LNR_0_255='^(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])$'

    declare strIptLogMsg="${2}"
    declare strTipLogMsgValidateCodeRange=''
    declare strTipLogMsgValidatePrmNumber=''
    declare -i intIptFunPrmCount="${#}"
    declare -i intIptLogCode="${1}"

    local strNrfLog=''
    local -a arrPssLogMsgPrm=()

    read -r -d '' strTipLogMsgValidateCodeRange << 'EOF' || true
The code MUST be greater than or equal to 0, and less than or equal to 255, but %s was provided.
EOF
    read -r -d '' strTipLogMsgValidatePrmNumber << 'EOF' || true
The number of input parameters MUST be %d, but %d were provided.
EOF

    [[ ${intIptFunPrmCount} -eq ${INT_FUN_PRM_COUNT_EXPECTED} ]] || {
      arrPssLogMsgPrm=("${INT_FUN_PRM_COUNT_EXPECTED}" "${intIptFunPrmCount}")
      fun_log_handler "${INT_ERR_SYS_FALSE:-1}" "${strTipLogMsgValidatePrmNumber}" arrPssLogMsgPrm strNrfLog

      printf '%s\n' "${strNrfLog}"

      return "${INT_ERR_SYS_FALSE:-1}"
    }

    [[ "${intIptLogCode}" =~ ${REG_NUM_LNR_0_255} ]] || {
      arrPssLogMsgPrm=("${intIptLogCode}")
      fun_log_handler "${INT_ERR_SYS_FALSE:-1}" "${strTipLogMsgValidateCodeRange}" arrPssLogMsgPrm strNrfLog

      printf '%s\n' "${strNrfLog}"

      return "${INT_ERR_SYS_FALSE:-1}"
    }

    arrPssLogMsgPrm=("${strIptLogMsg}")
    fun_log_handler "${intIptLogCode}" '%s' arrPssLogMsgPrm strNrfLog

    printf '%s\n' "${strNrfLog}"
  }

  fun_log_format_field() {
    declare strIptLogField="${3}"
    declare -i intIptLogColor="${2}"
    declare -i intIptLogFieldTotal="${1}"

    declare strLogColorPre=''
    declare strLogColorSuf=''
    declare strLogField=''
    declare strLogFieldPadding=''
    declare -i intLogFieldLen=''
    declare -i intLogFieldPaddingLen=''

    strLogField="[${strIptLogField}]"
    intLogFieldLen="${#strLogField}"
    intLogFieldPaddingLen=$((intIptLogFieldTotal - intLogFieldLen))
    intLogFieldPaddingLen=$((intLogFieldPaddingLen > 0 ? intLogFieldPaddingLen : 0))

    printf -v strLogFieldPadding '%*s' "${intLogFieldPaddingLen}" ''

    if [[ -t 1 ]] && [[ -t 2 ]]; then
      strLogColorPre=$'\033[;'"${intIptLogColor}m"
      strLogColorSuf=$'\033[0m'
    else
      strLogColorPre=''
      strLogColorSuf=''
    fi

    printf -v "${4}" '%s%s%s%s' "${strLogColorPre}" "${strLogField}" "${strLogColorSuf}" "${strLogFieldPadding}"
  }

  fun_log_get_level_and_color_by_code() {
    declare -i intIptLogCode="${1}"

    declare strLogLevel=''
    declare -i intLogColor=''

    case "${intIptLogCode}" in
    0)
      strLogLevel='INFO'
      intLogColor=42
      ;;
    1)
      strLogLevel='ERROR'
      intLogColor=41
      ;;
    15[0-9] | 16[0-9])
      strLogLevel='INFO'
      intLogColor=32
      ;;
    17[0-9])
      strLogLevel='WARN'
      intLogColor=33
      ;;
    18[0-9] | 19[0-9])
      strLogLevel='ERROR'
      intLogColor=31
      ;;
    *)
      strLogLevel='TBD'
      intLogColor=7
      ;;
    esac

    printf -v "${2}" '%s' "${strLogLevel}"
    printf -v "${3}" '%s' "${intLogColor}"
  }

  fun_log_get_time() {
    TZ=UTC printf -v "${1}" '%(%Y-%m-%dT%H:%M:%SZ)T' -1
  }

  fun_log_handler() {
    declare -ir INT_LOG_CODE_TOTAL=5
    declare -ir INT_LOG_LEVEL_TOTAL=7
    declare -r STR_LOG_TPL='[%s] %s %s %s'

    declare strIptLogMsgTpl="${2}"
    declare -i intIptLogCode="${1}"
    declare -n arrIptLogMsgTplReplace="${3}"

    local strNrfLogCodeFmt
    local strNrfLogColor
    local strNrfLogLevel
    local strNrfLogLevelFmt
    local strNrfLogMsg
    local strNrfLogRender
    local strNrfLogTime
    local -a arrPssLogPrm=()

    fun_log_get_time strNrfLogTime
    fun_log_get_level_and_color_by_code "${intIptLogCode}" strNrfLogLevel strNrfLogColor
    fun_log_format_field "${INT_LOG_LEVEL_TOTAL}" "${strNrfLogColor}" "${strNrfLogLevel}" strNrfLogLevelFmt
    fun_log_format_field "${INT_LOG_CODE_TOTAL}" "${strNrfLogColor}" "${intIptLogCode}" strNrfLogCodeFmt
    fun_log_replace_tpl "${strIptLogMsgTpl}" "${!arrIptLogMsgTplReplace}" strNrfLogMsg

    arrPssLogPrm=("${strNrfLogTime}" "${strNrfLogLevelFmt}" "${strNrfLogCodeFmt}" "${strNrfLogMsg}")
    fun_log_replace_tpl "${STR_LOG_TPL}" arrPssLogPrm strNrfLogRender

    printf -v "${4}" '%s' "${strNrfLogRender}"
  }

  fun_log_replace_tpl() {
    declare -n arrIptLogReplace="${2}"

    printf -v "${3}" "${1}" "${arrIptLogReplace[@]}"
  }

  # ########## ######### ######### ######### ######### ######### ######### #####
  # 入口 main
  # ########## ######### ######### ######### ######### ######### ######### #####

  main "${@}"
)
