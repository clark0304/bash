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

  declare -ir INT_ARG_MAX_CNT=10
  declare -ir INT_ENV_BASH_VERSINFO_MAJOR=5
  declare -ir INT_ERR_SYS_FAULT=170
  declare -ir INT_ERR_SYS_OK=0
  declare -r REG_STR_BLANK='^[[:space:]]*$'
  declare -r STR_BIZ_SCRIPT_VERSION='1.1.0'
  declare -r STR_ENV_ROUTER_HELP='ROUTER_HELP'
  declare -r STR_ENV_ROUTER_RUN='ROUTER_RUN'
  declare -r STR_ENV_ROUTER_VERSION='ROUTER_VERSION'
  declare -r STR_TIP_ENV_VALIDATE_ARG_NON_EMPTY='最多可输入 %d 个名字, 且每一个都 MUST NOT 纯空白字符串.'
  declare -r STR_TIP_ENV_VALIDATE_BASH_COMMAND='当前环境非 Bash, MUST 以该解释器运行.'
  declare -r STR_TIP_ENV_VALIDATE_BASH_VERSION='当前环境 Bash 版本号 MUST >= %d.'
  declare -r STR_TIP_ENV_VALIDATE_COMMAND='当前脚本 MUST 依赖的命令缺失: %s.'
  declare -r STR_TIP_ENV_VALIDATE_ROUTER='选项和参数解析失败.'

  # ########## ######### ######### ######### ######### ######### ######### #####
  # 定义 变量
  # ########## ######### ######### ######### ######### ######### ######### #####

  declare strTipEnvValidateArgNonEmpty=''
  declare strTipEnvValidateBashCommand=''
  declare strTipEnvValidateBashVersion=''
  declare -i intRtnBizHelloValidateArg=0
  declare -i intRtnEnvValidateBashCommand=0
  declare -i intRtnEnvValidateBashVersion=0
  declare -i intRtnEnvValidateCommand=0

  # ########## ######### ######### ######### ######### ######### ######### #####
  # 定义 被引用的变量
  # ########## ######### ######### ######### ######### ######### ######### #####

  declare -g strNrfTipEnvValidateCommand=''

  # ########## ######### ######### ######### ######### ######### ######### #####
  # 整理 变量
  # ########## ######### ######### ######### ######### ######### ######### #####

  printf -v strTipEnvValidateArgNonEmpty "${STR_TIP_ENV_VALIDATE_ARG_NON_EMPTY}" "${INT_ARG_MAX_CNT}"
  printf -v strTipEnvValidateBashCommand "${STR_TIP_ENV_VALIDATE_BASH_COMMAND}" ''
  printf -v strTipEnvValidateBashVersion "${STR_TIP_ENV_VALIDATE_BASH_VERSION}" "${INT_ENV_BASH_VERSINFO_MAJOR}"

  # ########## ######### ######### ######### ######### ######### ######### #####
  # 定义 方法
  # ########## ######### ######### ######### ######### ######### ######### #####

  fun_biz_hello() {
    declare -n arrIptCmdArgFmd="${1}"

    declare item=''
    declare -a arrTmpCmdArgFmd=()

    local strNrfItemCase=''
    local strNrfItemTrim=''

    if [[ ${#arrIptCmdArgFmd[@]} -ne 0 ]]; then
      arrTmpCmdArgFmd=("${arrIptCmdArgFmd[@]}")
    else
      arrTmpCmdArgFmd=('world')
    fi

    for item in "${arrTmpCmdArgFmd[@]}"; do
      fun_atm_str_trim "${item}" strNrfItemTrim
      fun_atm_str_case "${strNrfItemTrim}" strNrfItemCase

      printf 'Hello %s!\n' "${strNrfItemCase}"
    done
  }

  fun_biz_hello_validate_arg() {
    declare -n arrIptCmdArg="${1}"

    declare item=''

    [[ "${#arrIptCmdArg[@]}" -le "${INT_ARG_MAX_CNT}" ]] || {
      return "${INT_ERR_SYS_FAULT}"
    }

    for item in "${arrIptCmdArg[@]}"; do
      ! [[ "${item}" =~ ${REG_STR_BLANK} ]] || {
        return "${INT_ERR_SYS_FAULT}"
      }
    done

    return "${INT_ERR_SYS_OK}"
  }

  fun_biz_hello_parse_option() {
    declare -n arrIptCmdArg="${1}"

    declare item=''
    declare -a arrTmpCmdArgFmd=()
    declare -A arrTmpCmdOptionFmd=()

    arrTmpCmdOptionFmd['router']="${STR_ENV_ROUTER_RUN}"

    for item in "${arrIptCmdArg[@]}"; do
      case "${item}" in
      -h | --help)
        arrTmpCmdOptionFmd['router']="${STR_ENV_ROUTER_HELP}"

        break
        ;;
      -v | -V | --version)
        arrTmpCmdOptionFmd['router']="${STR_ENV_ROUTER_VERSION}"

        break
        ;;
      --)
        :
        ;;
      -*)
        arrTmpCmdOptionFmd['router']=''
        ;;
      *)
        arrTmpCmdArgFmd+=("${item}")
        ;;
      esac
    done

    fun_atm_var_copy arrTmpCmdArgFmd "${2}"
    fun_atm_var_copy arrTmpCmdOptionFmd "${3}"
  }

  fun_biz_hello_show_help() {
    declare strEnvBashSource="${BASH_SOURCE[0]}"
    declare strTxtHelp=''

    read -r -d '' strTxtHelp <<'EOF' || true
Usage:
  ____STR_SYS_BASH_SOURCE____ [OPTION] [ARGUMENT]...

Description:
  Print "Hello [NAME]!" for each [NAME] provided, capitalizing the first letter.

Options:
  -h, --help            Display this help document and exit.
  -v, -V, --version     Display version information and exit.

Arguments:
  NAME                  Iterate name(s) to greet (up to ____INT_ARG_MAX_CNT____).
                        If omitted, defaults to "World".
                        Empty strings are not allowed.

Examples:
  $ ____STR_SYS_BASH_SOURCE____
  Hello World!

  $ ____STR_SYS_BASH_SOURCE____ alpha
  Hello Alpha!

  $ ____STR_SYS_BASH_SOURCE____ Alpha "bravo charlie" '  delta  '
  Hello Alpha!
  Hello Bravo charlie!
  Hello Delta!
EOF

    strTxtHelp="${strTxtHelp//____STR_SYS_BASH_SOURCE____/${strEnvBashSource}}"
    strTxtHelp="${strTxtHelp//____INT_ARG_MAX_CNT____/${INT_ARG_MAX_CNT}}"

    printf '%s\n' "${strTxtHelp}"
  }

  fun_biz_hello_show_version() {
    declare strTxtVersion=''

    read -r -d '' strTxtVersion <<'EOF' || true
____STR_BIZ_SCRIPT_VERSION____
EOF

    strTxtVersion="${strTxtVersion//____STR_BIZ_SCRIPT_VERSION____/${STR_BIZ_SCRIPT_VERSION}}"

    printf '%s\n' "${strTxtVersion}"
  }

  main() {
    local -a arrNrfCmdArgFmd=()
    local -a arrPssCmdArg=()
    local -a arrPssCmdArgFmd=()
    local -A arrNrfCmdOptionFmd=()
    local -A arrPssCmdOptionFmd=()

    arrNrfCmdArgFmd=()
    arrPssCmdArg=("${@}")
    arrPssCmdArgFmd=()
    arrPssCmdOptionFmd=()

    # 检测参数
    fun_biz_hello_validate_arg arrPssCmdArg || intRtnBizHelloValidateArg=$?

    [[ "${intRtnBizHelloValidateArg}" -eq 0 ]] || {
      fun_log "${intRtnBizHelloValidateArg}" "${strTipEnvValidateArgNonEmpty}"

      return "${intRtnBizHelloValidateArg}"
    }

    # 解析选项 整理参数
    fun_biz_hello_parse_option arrPssCmdArg arrNrfCmdArgFmd arrNrfCmdOptionFmd

    # 路由
    case "${arrNrfCmdOptionFmd['router']:-}" in
    "${STR_ENV_ROUTER_HELP}")
      fun_biz_hello_show_help
      ;;
    "${STR_ENV_ROUTER_VERSION}")
      fun_biz_hello_show_version
      ;;
    "${STR_ENV_ROUTER_RUN}")
      fun_atm_var_copy arrNrfCmdArgFmd arrPssCmdArgFmd
      fun_atm_var_copy arrNrfCmdOptionFmd arrPssCmdOptionFmd

      fun_biz_hello arrPssCmdArgFmd
      ;;
    *)
      fun_log "${INT_ERR_SYS_FAULT}" "${STR_TIP_ENV_VALIDATE_ROUTER}"

      return "${INT_ERR_SYS_FAULT}"
      ;;
    esac
  }

  fun_atm_str_case() {
    printf -v "${2}" '%s' "${1^}"
  }

  fun_atm_str_trim() {
    declare strIptVarSource="${1}"

    declare strTmpTrim="${strIptVarSource}"

    strTmpTrim="${strTmpTrim#"${strTmpTrim%%[![:space:]]*}"}"
    strTmpTrim="${strTmpTrim%"${strTmpTrim##*[![:space:]]}"}"

    printf -v "${2}" '%s' "${strTmpTrim}"
  }

  fun_atm_var_copy() {
    declare -n mxdIptVarSource="${1}"
    declare -n mxdIptVarTarget="${2}"

    declare key=''
    declare strVarAttr=''

    strVarAttr="$(declare -p "${!mxdIptVarSource}" 2>/dev/null)"

    if [[ "${strVarAttr}" == "declare -A"* ]]; then
      mxdIptVarTarget=()
      for key in "${!mxdIptVarSource[@]}"; do
        mxdIptVarTarget["${key}"]="${mxdIptVarSource[${key}]}"
      done
    else
      mxdIptVarTarget=("${mxdIptVarSource[@]}")
    fi
  }

  fun_log() {
    declare -ir INT_FUN_PRM_COUNT_EXPECTED=2
    declare -r REG_NUM_LNR_0_255='^(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])$'
    declare -r STR_TIP_LOG_MSG_VALIDATE_CODE_RANGE='The code MUST be greater than or equal to 0, and less than or equal to 255, but %s was provided.'
    declare -r STR_TIP_LOG_MSG_VALIDATE_PRM_NUMBER='The number of input parameters MUST be %d, but %d were provided.'

    declare strIptLogMsg="${2}"
    declare -i intIptFunPrmCount="${#}"
    declare -i intIptLogCode="${1}"

    local strNrfLog=''
    local -a arrPssLogMsgPrm=()

    [[ ${intIptFunPrmCount} -eq ${INT_FUN_PRM_COUNT_EXPECTED} ]] || {
      arrPssLogMsgPrm=("${INT_FUN_PRM_COUNT_EXPECTED}" "${intIptFunPrmCount}")
      fun_log_handler "${INT_ERR_SYS_FAULT:-1}" "${STR_TIP_LOG_MSG_VALIDATE_PRM_NUMBER}" arrPssLogMsgPrm strNrfLog

      printf '%s\n' "${strNrfLog}"

      return "${INT_ERR_SYS_FAULT:-1}"
    }

    [[ "${intIptLogCode}" =~ ${REG_NUM_LNR_0_255} ]] || {
      arrPssLogMsgPrm=("${intIptLogCode}")
      fun_log_handler "${INT_ERR_SYS_FAULT:-1}" "${STR_TIP_LOG_MSG_VALIDATE_CODE_RANGE}" arrPssLogMsgPrm strNrfLog

      printf '%s\n' "${strNrfLog}"

      return "${INT_ERR_SYS_FAULT:-1}"
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

  fun_log_get_time() {
    TZ=UTC printf -v "${1}" '%(%Y-%m-%dT%H:%M:%SZ)T' -1
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
    17[0-9] | 18[0-9] | 19[0-9])
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

  fun_env_validate_bash_command() {
    [[ -n "${BASH_VERSION:-}" ]] || {
      return "${INT_ERR_SYS_FAULT}"
    }

    return "${INT_ERR_SYS_OK}"
  }

  fun_env_validate_bash_version() {
    [[ "${BASH_VERSINFO[0]:-}" -ge "${INT_ENV_BASH_VERSINFO_MAJOR}" ]] || {
      return "${INT_ERR_SYS_FAULT}"
    }

    return "${INT_ERR_SYS_OK}"
  }

  fun_env_validate_command() {
    declare strEnvCommand=''
    declare strEnvCommandMissed=''
    declare strTmpCommand=''
    declare -a arrEnvCommandDependent=()
    declare -a arrEnvCommandMissed=()

    arrEnvCommandDependent=(
      'command'
      'printf'
    )

    for strEnvCommand in "${arrEnvCommandDependent[@]}"; do
      command -v "${strEnvCommand}" >/dev/null 2>&1 || arrEnvCommandMissed+=("${strEnvCommand}")
    done

    [[ ${#arrEnvCommandMissed[@]} -eq 0 ]] || {
      strEnvCommandMissed=$(
        IFS=','
        declare strTmpCommand="${arrEnvCommandMissed[*]}"
        printf '%s' "${strTmpCommand//,/$', '}"
      )

      printf -v "${2}" "${1}" "${strEnvCommandMissed}"

      return "${INT_ERR_SYS_FAULT}"
    }

    return "${INT_ERR_SYS_OK}"
  }

  # ########## ######### ######### ######### ######### ######### ######### #####
  # 校验 环境流水线
  # ########## ######### ######### ######### ######### ######### ######### #####

  fun_env_validate_bash_command || intRtnEnvValidateBashCommand=$?

  [[ "${intRtnEnvValidateBashCommand}" -eq 0 ]] || {
    fun_log "${intRtnEnvValidateBashCommand}" "${strTipEnvValidateBashCommand}"

    exit "${intRtnEnvValidateBashCommand}"
  }

  fun_env_validate_bash_version || intRtnEnvValidateBashVersion=$?

  [[ "${intRtnEnvValidateBashVersion}" -eq 0 ]] || {
    fun_log "${intRtnEnvValidateBashVersion}" "${strTipEnvValidateBashVersion}"

    exit "${intRtnEnvValidateBashVersion}"
  }

  fun_env_validate_command "${STR_TIP_ENV_VALIDATE_COMMAND}" strNrfTipEnvValidateCommand || intRtnEnvValidateCommand=$?

  [[ "${intRtnEnvValidateCommand}" -eq 0 ]] || {
    fun_log "${intRtnEnvValidateCommand}" "${strNrfTipEnvValidateCommand}"

    exit "${intRtnEnvValidateCommand}"
  }

  # ########## ######### ######### ######### ######### ######### ######### #####
  # 入口 main
  # ########## ######### ######### ######### ######### ######### ######### #####

  main "${@}"
)
