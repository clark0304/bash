#!/usr/bin/env bash

# shellcheck disable=SC2034
# shellcheck disable=SC2059

set -euE -o pipefail

IFS=$'\n\t'

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
