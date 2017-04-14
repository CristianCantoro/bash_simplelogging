#!/usr/bin/env bash
SOURCED=false && [ "$0" = "$BASH_SOURCE" ] || SOURCED=true

# Bash strict mode
# See:
# https://balist.es/blog/2017/03/21/
#     enhancing-the-unofficial-bash-strict-mode/ 
if ! $SOURCED; then
  set -euo pipefail
  IFS=$'\n\t'
fi

echo "Logging demo, today is $(date)"

# shellcheck disable=SC1091
source "lib/simplelogging.sh"
echo "Sourcing bash_logging.sh"

get_logger 'demologger1' 'WARNING'
get_logger 'demologger2' 'INFO'
get_logger 'demologger3' 'DEBUG'

example_function(){
    demologger1.entry
    demologger1.info "called example_function"
    demologger1.debug "first: $1, second: $2"
    demologger1.warning "warning!"
    demologger1.return
}

demologger1.attach_handler 'CONSOLE' 'DEBUG'
demologger2.attach_handler 'CONSOLE' 'WARNING'
demologger2.attach_handler '/tmp/logger.txt' 'DEBUG'
demologger2.attach_handler '/tmp/logger2.txt' 'WARNING'
demologger3.attach_handler 'CONSOLE' 'DEBUG'

avar='this a var'
demologger1.error "avar: $avar"

echo "--- 1 ---"
demologger1.debug 'debug message - 1'
demologger1.info 'info message - 1'
demologger1.warning 'warning message - 1'
demologger1.error 'error message - 1'
demologger1.critical 'critical message - 1'

demologger1.attach_handler 'CONSOLE' 'ERROR'

demologger1.debug 'debug message - 2'
demologger1.info 'info message - 2'
demologger1.warning 'warning message - 2'
demologger1.error 'error message - 2'
demologger1.critical 'critical message - 2'

demologger1.attach_handler 'CONSOLE' 'NOTSET'

demologger1.debug 'debug message - 3'
demologger1.info 'info message - 3'
demologger1.warning 'warning message - 3'
demologger1.error 'error message - 3'
demologger1.critical 'critical message - 3'

echo "--- 2 ---"
demologger2.debug 'debug message'
demologger2.info 'info message'
demologger2.warning 'warning message'
demologger2.error 'error message'
demologger2.critical 'critical message'

echo "--- 3 ---"
demologger3.debug 'debug message'
demologger3.info 'info message'

echo "--- function ---"
demologger1.attach_handler 'CONSOLE' 'DEBUG'
example_function 'aaa' 'bbb'

echo "--- 1 ---"
get_logger 'demologger1' 'NOTSET'
demologger1.attach_handler 'CONSOLE' 'INFO'
demologger1.debug 'debug message - 1'
demologger1.info 'info message - 1'
demologger1.warning 'warning message - 1'
demologger1.error 'error message - 1'
demologger1.critical 'critical message - 1'

exit 0
