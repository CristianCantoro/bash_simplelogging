#!/usr/bin/env bash
##############################################################################
#
# Bash simple logging library.
#
# Code inspired from:
# http://www.cubicrace.com/2016/03/efficient-logging-mechnism-in-shell.html
##############################################################################
# shellcheck disable=SC2128
SOURCED=false && [ "$0" = "$BASH_SOURCE" ] || SOURCED=true

# Bash strict mode
# See:
# https://balist.es/blog/2017/03/21/
#     enhancing-the-unofficial-bash-strict-mode/ 
if ! $SOURCED; then
  set -euo pipefail
  IFS=$'\n\t'
fi

declare -A _BASH_LOGGING_LOGLEVELS
_BASH_LOGGING_LOGLEVELS=(\
  ['NOTSET']=0 \
  ['DEBUG']=10 \
  ['INFO']=20 \
  ['WARNING']=30 \
  ['ERROR']=40 \
  ['CRITICAL']=50 \
  )

function get_logger() {

  local loggername="$1"
  local logger_loglevel="$2"
  local logger_loglevelnum
  logger_loglevelnum="${_BASH_LOGGING_LOGLEVELS[$logger_loglevel]}"

  local logllnum
  local loglllow

  case $logger_loglevel in
  'NOTSET') 
    loglevel='NOTSET'
    ;;
  'DEBUG') 
    loglevel='DEBUG'
    ;;
  'INFO')
    loglevel='INFO'
    ;;
  'WARNING')
    loglevel='WARNING'
    ;;
  'ERROR')
    loglevel='ERROR'
    ;;
  "CRITICAL")
    loglevel='CRITICAL'
    ;;
  *) 
    (>&2 echo "ERROR: logging level $logger_loglevel unrecognized")
    (>&2 echo "exiting")
    exit 1
  esac


  eval "function ${loggername}.debug() { true; }"
  eval "function ${loggername}.info() { true; }"
  eval "function ${loggername}.warning() { true; }"
  eval "function ${loggername}.error() { true; }"
  eval "function ${loggername}.critical() { true; }"

  eval "_BASH_LOGGING_${loggername}_cfn=''"
  eval "$(cat <<EOF
  function ${loggername}.entry() {
    _BASH_LOGGING_${loggername}_cfn="\${FUNCNAME[1]}"
    ${loggername}.debug "> \$_BASH_LOGGING_${loggername}_cfn \$FUNCNAME"
  }
EOF
  )"
  eval "$(cat <<EOF
  function ${loggername}.return() {
    ${loggername}.debug "< \$_BASH_LOGGING_${loggername}_cfn \$FUNCNAME"
    _BASH_LOGGING_${loggername}_cfn=''
  }
EOF
  )"

  eval "$(cat <<EOF
  function ${loggername}.attach_handler() {
    _BASH_LOGGING_attach_handler "${loggername}" "\$1" "\$2"
    ${loggername}.debug "attach handler: \$1 (\$2)"
  }
EOF
  )"

  # http://stackoverflow.com/questions/17529220
  eval "declare -gA _BASH_LOGGING_${loggername}_handlers"

  for logll in "${!_BASH_LOGGING_LOGLEVELS[@]}"; do
    logllnum="${_BASH_LOGGING_LOGLEVELS[$logll]}"
    loglllow=$(echo "$logll" | tr '[:upper:]' '[:lower:]')
    if [[ "$logger_loglevelnum" -eq 0 ]]; then
        eval "function ${loggername}.${loglllow}() { true; }"
    elif [[ ! "$logger_loglevelnum" > "$logllnum" ]]; then
      eval "$(cat <<EOF
      _BASH_LOGGING_${loggername}_${loglllow}_skip_header=false

      function ${loggername}.${loglllow}() {

        declare -a handlers
        local numhandlers
        OLDIFS="\$IFS"
        IFS=' '
        read -r -a handlers <<< "\$(_BASH_LOGGING_get_handlers ${loggername} ${logll})"
        numhandlers="\${#handlers[@]}"
        if [[ "\$numhandlers" > 0 ]]; then
          for handler in "\${handlers[@]}"; do
            _BASH_LOGGING_write_log "${loggername}" "${loglllow}" "\${@-}" "\$handler"
          done
        fi
        IFS="\$OLDIFS"
      }
EOF
    )"
    fi
  done
}

function _BASH_LOGGING_write_log() {
  local loggername="$1"
  local loglevel="$2"
  local msg="$3"
  local handler="$4"
  local tstamp
  local numargs="$#"
  local skip_header_var
  local logger_cfn
  local print_loglevel

  skip_header_var="_BASH_LOGGING_${loggername}_${loglevel}_skip_header"
  tstamp=$(date '+%F %k:%M:%S')
  print_loglevel=$(printf "%-8s" "$loglevel" | tr '[:lower:]' '[:upper:]')
  logger_cfn="_BASH_LOGGING_${loggername}_cfn"

  local funcname=''
  if [[ ! -z "${!logger_cfn}" ]]; then
    funcname="${!logger_cfn}"
  else
    funcname='main'
  fi

  if [[ "$handler" == 'CONSOLE' ]]; then
    if ! ${!skip_header_var}; then
      (>&2 echo -en "[$tstamp][$print_loglevel]($loggername.$funcname)\t" )
    else
      eval "${skip_header_var}=false"
    fi

    if [ "$numargs" -gt 1 ] && [[ "$msg" =~ ^'-n'* ]]; then
      eval "${skip_header_var}=false"
    fi
    (>&2 echo "$msg")

  else
    if ! ${!skip_header_var}; then
      echo -en "[$tstamp][$print_loglevel]($loggername.$funcname)\t" >> "$handler"
    else
      eval "${skip_header_var}=false"
    fi

    if [ "$numargs" -gt 1 ] && [[ "$msg" =~ ^'-n'* ]]; then
      eval "${skip_header_var}=false"
    fi

    echo "$msg" >> "$handler"
  fi
}

function _BASH_LOGGING_attach_handler() {
  local loggername="$1"
  local handlername="$2"
  local handlerlevel="$3"

  # echo "add handler '$handlername' ($handlerlevel) to logger $loggername"
  handlerlevel="${_BASH_LOGGING_LOGLEVELS[$handlerlevel]}"
  eval "_BASH_LOGGING_${loggername}_handlers[$handlername]=$handlerlevel"
}

# http://stackoverflow.com/questions/27456950
# http://stackoverflow.com/questions/14839199
function _BASH_LOGGING_get_handlers() {
  local loggername="$1"
  local loggerlevel="$2"
  # local handler_loglevel
  local logger_handlers
  local -a active_handlers=()
  
  indir_keys() {
      eval "echo \${!$1[@]}"
  }

  indir_val() {
      eval "echo \${$1[$2]}"
  }

  logger_handlers="_BASH_LOGGING_${loggername}_handlers"
  loggerlevel="${_BASH_LOGGING_LOGLEVELS[$loggerlevel]}"
  
  OLDIFS="$IFS"
  IFS=' '

  if [[ "$loggerlevel" -ne 0 ]]; then
    for handler_idx in $(indir_keys "$logger_handlers"); do
      handler_loglevel=$(indir_val "$logger_handlers" "$handler_idx")
      # (>&2 echo -n "(${loggername}) handler: $handler_idx, $handler ")
      # (>&2 echo "- loggerlevel: $loggerlevel")
      if [[ "$handler_loglevel" -ne 0 ]] && \
          [[ ! "$handler_loglevel" > "$loggerlevel" ]]; then
        active_handlers+=( "$handler_idx" )
      fi
    done  
    IFS="$OLDIFS"

    if [[ "${#active_handlers[@]}" -gt 0 ]]; then
      echo "${active_handlers[@]}"
    fi
  fi
}
