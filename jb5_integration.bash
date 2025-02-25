#!/bin/bash
#
# **BASH CORE library for jetbackup5api**
#
# | Author: Noam Alum
# | Description: This file contains the core BASH functions for jetbackup CI/CD.
# | Documentation: https://git.jetapps.com/jetapps/n8n/-/blob/run-functions-via-bash/scripts/docs/jb5_scripts/core.md
#

# **Exit codes**
#
# | Exit Code 0: Success
# | The script/operation executed successfully without any issues.
# |
# | Exit Code 1: Bash error
# | A general Bash error occurred, such as command not found or syntax issues.
# |
# | Exit Code 2: JetBackup 5 success is 0
# | JetBackup5 function did not succeed.
# |
# | Exit Code 3: Script error
# | An error specific to the script's logic or functionality occurred, such as missing files or incorrect parameters passed to the script.
# |
# | Exit Code 4: Unknown error
# | An unknown error occurred that couldn't be classified or identified.
# |
# | Exit Code 137: Script was killed via pkill
# | When subshells are used, the `exit` command can only terminate the subshell, not the entire script. As a result, `pkill` must be used to stop the script's execution.
#



##########################
# | Internal variables | #
##########################

## Keys
JETBACKUP_KEYS=(
  "account" "account_id" "accounts" "account_status" "account_suspended" "account_username" "action" "alerts_ttl"
  "all" "approve" "backup" "backup_contains" "backup_forks" "backup_fork_ttl" "backup_integrity_check_schedule"
  "backup_priority" "backup_quota" "backup_structure" "by_snap" "Category" "condition" "contains" "content" "cpu_limit"
  "date_start" "date_end" "debug" "usage" "default" "default_owner" "default_package" "description" "destination"
  "directories_queue_priority" "dirs_permissions" "disabled" "disk_limit" "download_priority" "downloads" "downloads_path"
  "downloads_ttl" "dr" "drmode" "email" "encrypted" "encryption_selection" "error_reporting" "exclude_list" "excludes"
  "files" "files_permissions" "filter" "filters" "find" "forgotten_ttl" "frequency" "group" "group_id" "clone_priority"
  "gunzip" "gzip" "hidden" "id" "include_list" "io_read_limit" "io_write_limit" "ip" "items" "job" "limit_account_downloads"
  "limit_hours" "limit_times" "list" "lock" "locked" "lock_homedir" "lock_ttl" "log_id" "logs_ttl" "manually_backup_retain"
  "manually_backup_ttl" "max_snapshots" "mongodump" "mongorestore" "monitor" "mysql" "mysqldump" "mysqldump_force"
  "mysqldump_max_packet" "mysqldump_opt" "mysqldump_skip_lock" "name" "notes" "options" "orphan" "orphan_backup_ttl"
  "owned_by" "owner" "package_id" "package_name" "package_selection" "permissions" "pgdump" "pgrestore" "plugin" "position"
  "position_type" "data_list" "privacy_policy" "psql" "queueable_forks" "queue_priority" "range_end" "range_start" "readonly"
  "recursive" "regex" "reindex" "repo" "restore" "restore_priority" "retain" "retry_failed" "Returns" "rsync" "schedules"
  "script" "show_oldest" "snapshot_id" "structure" "tags" "tar" "sort" "limit" "skip" "threads" "time" "total" "ttl"
  "type" "type_data" "url" "user" "user_agreement" "user_id" "user_name" "username" "visible" "workspace_path" "excluded"
  "delay_amount" "delay_type" "email_integration" "time_format" "use_community_languages" "show_damaged_backups" "system_forks"
  "mysqldump_multibyte" "mysqldump_gtid_purged" "memory_limit" "rule_size" "rule_inodes" "expiry" "category" "backup_type" "privacy"
  "terms" "encryption_key_type" "encryption_key"
)

JETBACKUP_CUSTOM_KEYS=(
  "message" "success" "request" "requirement" "b_type" "b_username" "b_id" "file" "data"
)

## General
JETBACKUP_API="/usr/local/jetapps/usr/bin/jetbackup5/jetbackupapi -O json -F"
EXECUTE_FUNCTION_DELAY="0.3"

## Reindex settings
MAX_REINDEX_TIMEOUT="60"
POST_REINDEX_DELAY="2"


#############
# | Style | #
#############

## ANSI codes
ANSI_BLACK="\e[30m"
ANSI_BLACK_BACKGROUND="\e[40m"
ANSI_RED="\e[31m"
ANSI_RED_BACKGROUND="\e[41m"
ANSI_GREEN="\e[32m"
ANSI_GREEN_BACKGROUND="\e[42m"
ANSI_BROWN="\e[33m"
ANSI_BROWN_BACKGROUND="\e[43m"
ANSI_BLUE="\e[34m"
ANSI_BLUE_BACKGROUND="\e[44m"
ANSI_PURPLE="\e[35m"
ANSI_PURPLE_BACKGROUND="\e[45m"
ANSI_CYAN="\e[36m"
ANSI_CYAN_BACKGROUND="\e[46m"
ANSI_GREY="\e[37m"
ANSI_GREY_BACKGROUND="\e[47m"
ANSI_BOLD="\e[1m"
ANSI_ITALIAN="\e[3m"
ANSI_UNDERLINE="\e[4m"
ANSI_BLINK="\e[5m"
ANSI_REVERSED_VIDEO="\e[7m"
ANSI_STRIKETHROUGH="\e[9m"
ANSI_END="\e[0m"



##########################
# | Internal functions | #
##########################

# **fail**
# | Exits with a specific code and sends error to stderr
#

function fail {
  local ERR_CODE ERR_MSG
	ERR_CODE="${1:-4}"
	ERR_MSG="${2:-"No error specified."}"

	echo -e "${ANSI_BOLD}${ANSI_RED} • (${FUNC_NAME:=-}) ERROR:${ANSI_END} ${ANSI_BOLD} $ERR_MSG${ANSI_END}" >&2

  # Handle subprocesses
  if [ $BASH_SUBSHELL -gt 0 ]; then
    echo "Exit code should be: $ERR_CODE" >&2
    pkill --signal 9 -f "$(basename "$0")"
  fi

  exit "$ERR_CODE"
}

which jq &> /dev/null || fail 3 "jq not found, please install and try again."

# **jbjq**
# | Wraps jq so when it exists it would be handled by the script
#

function jbjq {
  local IS_EVAL DATA REQUEST JQ_RESPONSE
  IS_EVAL=false

  # Expecting type, file, data and request
  while getopts ":er:d:f:" opt; do
    case ${opt} in
      r)
        REQUEST="${OPTARG}"
        ;;
      e)
        IS_EVAL=true
        ;;
      d)
        DATA="${OPTARG}"
        ;;
      :)
        FUNC_NAME="${BASH_SOURCE[-1]##*/} -> jb5_integration.bash - ${FUNCNAME[0]}"
        fail 3 "Error while using ${FUNCNAME[0]} function, option -${OPTARG} requires an argument."
        ;;
      ?)
        FUNC_NAME="${BASH_SOURCE[-1]##*/} -> jb5_integration.bash - ${FUNCNAME[0]}"
        fail 3 "Error while using ${FUNCNAME[0]} function, invalid option: -${OPTARG}."
        ;;
    esac
  done

  test -z "$REQUEST" && fail 3 "No request provided!"
  test -z "$DATA" && fail 3 "No request provided!"

  if ! JQ_RESPONSE="$(jq -r "$REQUEST" <<< "$DATA" 2>&1)"; then
    FUNC_NAME="${BASH_SOURCE[-1]##*/} -> jb5_integration.bash - ${FUNCNAME[0]}"
    fail 3 "jq failed, error:\n$JQ_RESPONSE\n"
  elif [ "$JQ_RESPONSE" == "null" ]; then
    FUNC_NAME="${BASH_SOURCE[-1]##*/} -> jb5_integration.bash - ${FUNCNAME[0]}"
    fail 3 "jq failed fetching \"$REQUEST\" from:\n\n$DATA\n"
  else
    if $IS_EVAL; then
      eval echo "$JQ_RESPONSE"
    else
      echo "$JQ_RESPONSE"
    fi
  fi
}

# **array_contains**
# | Check if array contains an item
#

function array_contains {
  local ITEM ARRAY_ITEMS
  ITEM="$1"
  shift 1
  ARRAY_ITEMS=("$@")

  for ARRAY_ITEM in "${ARRAY_ITEMS[@]}"
  do
    [[ "$ARRAY_ITEM" = "$ITEM" ]] && return 0
  done

  # Could not find item in array
  return 1
}

# **gen_random**
# | Generate random data. (Function was taken from utils.sh, refer: https://docs.alum.sh/utils.sh/Introduction.html)
# | Documentation: https://docs.alum.sh/utils.sh/functions/gen_random.html
#

function gen_random {
  local GR_OPT GR_LEN CHARSET RES
  if [ -z "$1" ]; then GR_OPT="all"; else GR_OPT="$1"; fi
  if [ -z "$2" ]; then GR_LEN="12"; else GR_LEN="$2"; fi

  case $GR_OPT in
    all)
      CHARSET="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz,'\"!@#$%^&*()-_=+|[]{};:/?.>"
      ;;
    str)
      CHARSET="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
      ;;
    int)
      CHARSET="0123456789"
      ;;
    *)
      FUNC_NAME="${BASH_SOURCE[-1]##*/} -> jb5_integration.bash - ${FUNCNAME[0]}"
      fail 3 "Error while using \"${FUNCNAME[0]}\" function, not a valid option ($GR_OPT), refer to \"https://docs.alum.sh/utils.sh/functions/gen_random.html\" for more information."
      ;;
  esac
  readonly CHARSET

  if [ -z "${GR_LEN//[0-9]}" ]; then
    RES="$(tr -dc "$CHARSET" < /dev/urandom | head -c "$GR_LEN")"
  else
    FUNC_NAME="${BASH_SOURCE[-1]##*/} -> jb5_integration.bash - ${FUNCNAME[0]}"
    fail 3 "Error while using \"${FUNCNAME[0]}\" function, length not an int ($GR_LEN), refer to \"https://docs.alum.sh/utils.sh/functions/gen_random.html\" for more information."
  fi

  if [ -n "$RES" ]; then
	  echo "$RES"
	  return 0
  else
    FUNC_NAME="${BASH_SOURCE[-1]##*/} -> jb5_integration.bash - ${FUNCNAME[0]}"
	  fail 4 "Unknown error while using \"${FUNCNAME[0]}\" function, refer to \"https://docs.alum.sh/utils.sh/functions/gen_random.html\" for more information."
  fi
}

# **execute_function**
# | Executes JetBackup5 API calls and returns data based on json path/s.
#

function execute_function {
  local FUNC_NAME FUNC_OPT FUNC_REQ FUNC_RES FUNC_SUC FUNC_MSG RES_MSG RES JB5_LOG_RESPONSE

  FUNC_NAME="$1"
  FUNC_OPT="$2"
  shift 2
  FUNC_REQ=()
  while IFS=',' read -r line; do FUNC_REQ+=("$line"); done <<< "$*"

	# Wait function execution delay
	sleep "${EXECUTE_FUNCTION_DELAY:-0.5}"

	FUNC_RES="$($JETBACKUP_API -F "$FUNC_NAME" -D "$FUNC_OPT")"
	FUNC_SUC="$(jbjq -r ".success" -d "$FUNC_RES")"
	FUNC_MSG="$(jbjq -r ".message" -d "$FUNC_RES")"

	if [ "$FUNC_SUC" == "1" ]; then
		if [ ${#FUNC_REQ[@]} -ne 0 ] && [ -n "${FUNC_REQ[*]}" ]; then
      for R in "${FUNC_REQ[@]}"
      do
			  RES="$(jbjq -r "$R" -d "$FUNC_RES")"
			  echo "$RES"
      done
    else
      echo "$FUNC_RES"
    fi
	else
		fail 2 "While executing $FUNC_NAME:\nMessage: $FUNC_MSG\n\n EXEC:\n $JETBACKUP_API '$FUNC_NAME' -D '$FUNC_OPT'\n\n Output:\n$FUNC_RES\n"
	fi
}

# **find_args**
# | Assigns command-line argument values to variables based on JETBACKUP_KEYS.
#

function find_args {
  local find_args_TTL KEY VALUE ITEM_DATA ITEM_VALUE ITEM_INDEX ITEM_NAME
  find_args_TTL=${#JETBACKUP_KEYS[@]}
  while [[ $# -gt 0 ]] && [[ $find_args_TTL -gt 0 ]]; do
      KEY="$1"
      VALUE="$2"
      KEY="${KEY//--/}"
      if array_contains "${KEY}" "${JETBACKUP_CUSTOM_KEYS[@]}"; then
        echo "local $KEY=\"$VALUE\""
      elif array_contains "${KEY}" "${JETBACKUP_KEYS[@]}"; then
        ITEM_DATA=()
        IFS=',' read -r -a ITEM_DATA <<< "$VALUE"
        case ${#ITEM_DATA[@]} in
          3) # Two dimensional arrays
            ITEM_VALUE="${ITEM_DATA[2]}"
            ITEM_INDEX="[${ITEM_DATA[1]}]"
            ITEM_NAME="${ITEM_DATA[0]}"
            if [ -z "$(eval "echo \$$KEY")" ]; then
              # shellcheck disable=SC1087
              # | Not expanding an array, this looks like Im expanding an array, Im actually constructing the DATA sent to JetBackupAPI.
              local "$KEY"="$KEY[$ITEM_NAME]$ITEM_INDEX=$ITEM_VALUE"
            else
              # shellcheck disable=SC1087
              # | Not expanding an array, this looks like Im expanding an array, Im actually constructing the DATA sent to JetBackupAPI.
              local "$KEY"="$(eval echo "\$$KEY\&$KEY[$ITEM_NAME]$ITEM_INDEX=$ITEM_VALUE")"
            fi
            VALUE=$(eval "echo \$$KEY")
            ;;
          2) # Arrays
            ITEM_VALUE="${ITEM_DATA[1]}"
            ITEM_NAME="${ITEM_DATA[0]}"
            if [ -z "$(eval "echo \$$KEY")" ]; then
              # shellcheck disable=SC1087
              # | Not expanding an array, this looks like Im expanding an array, Im actually constructing the DATA sent to JetBackupAPI.
              eval "$KEY=\"$KEY[$ITEM_NAME]$ITEM_INDEX=$ITEM_VALUE\""
            else
              # shellcheck disable=SC1087
              # | Not expanding an array, this looks like Im expanding an array, Im actually constructing the DATA sent to JetBackupAPI.
              eval "$KEY=\"\${$KEY}&${KEY}[$ITEM_NAME]$ITEM_INDEX=$ITEM_VALUE\""
            fi
            VALUE=$(eval "echo \$$KEY")
            ;;
          1|0)
            if [ "$KEY" == "id" ]; then
              VALUE="_id=$VALUE"
            else
              VALUE="$KEY=$VALUE"
            fi
            ;;
          *) # Too many arguments
            FUNC_NAME="${BASH_SOURCE[-1]##*/} -> jb5_integration.bash - ${FUNCNAME[0]}"
            fail 3 "Too many arguments: ${ITEM_DATA[*]}"
            ;;
        esac
        echo "local $KEY=\"$VALUE\""
        unset ITEM_INDEX
      else
        FUNC_NAME="${BASH_SOURCE[-1]##*/} -> jb5_integration.bash - ${FUNCNAME[0]}"
        fail 3 "Error while using \"${FUNCNAME[0]}\" function, Invalid key: $KEY."
      fi
      shift 2
      (( find_args_TTL-- ))
  done

  if [ "$find_args_TTL" -le 0 ]; then
    FUNC_NAME="${BASH_SOURCE[-1]##*/} -> jb5_integration.bash - ${FUNCNAME[0]}"
    fail 3 "Error while using \"${FUNCNAME[0]}\" function, max TTL for while loop reached! (Probably a loop)"
  fi
}

# **set_options**
# | Create the options value for JB5 functions.
# |
# | -r                    A boolean that tells if the option is required.
# | -n                    The JB5 option name.
# | -v                    The value for the given JB5 option.
# | -d                    If needed, the default value for the given JB5 option. (if empty the option wont be used.)
# | -o                    The current OPTIONS value.
# | -m                    For required options, supply the error message.
# |
#

function set_options {
  local REQUIRED OPT_NAME VAR_VALUE DEFAULT_VALUE CURRENT_OPTIONS FAILED_MSG
  REQUIRED=false

  while getopts ":rn:v:d:o:m:af:" opt; do
    case ${opt} in
      r)
        REQUIRED=true
        ;;
      n)
        OPT_NAME="${OPTARG}"
        if [ "$OPT_NAME" == "id" ]; then
          OPT_NAME="_id"
        fi
        ;;
      v)
        VAR_VALUE="${OPTARG}"
        ;;
      d)
        DEFAULT_VALUE="${OPTARG}"
        ;;
      o)
        CURRENT_OPTIONS="${OPTARG}"
        ;;
      m)
        FAILED_MSG="${OPTARG}"
        ;;
      :)
        FUNC_NAME="${BASH_SOURCE[-1]##*/} -> jb5_integration.bash - ${FUNCNAME[0]}"
        fail 3 "Error while using ${FUNCNAME[0]} function, option -${OPTARG} requires an argument."
        ;;
      ?)
        FUNC_NAME="${BASH_SOURCE[-1]##*/} -> jb5_integration.bash - ${FUNCNAME[0]}"
        fail 3 "Error while using ${FUNCNAME[0]} function, invalid option: -${OPTARG}."
        ;;
    esac
  done

  if [ -z "$VAR_VALUE" ] && [ -n "$DEFAULT_VALUE" ]; then
    VAR_VALUE="$OPT_NAME=$DEFAULT_VALUE"
  fi

  if [ -z "$OPT_NAME" ]; then
    FUNC_NAME="${BASH_SOURCE[-1]##*/} -> jb5_integration.bash - ${FUNCNAME[0]}"
    fail 3 "Error while using ${FUNCNAME[0]} function, no variable name supplied."
  else
    if $REQUIRED; then
      if [ -z "$VAR_VALUE" ]; then
        FUNC_NAME="${BASH_SOURCE[-1]##*/} -> jb5_integration.bash - ${FUNCNAME[0]}"
        fail 3 "$FAILED_MSG"
      else
        echo "$(if [ -n "$CURRENT_OPTIONS" ] && [ -n "$VAR_VALUE" ]; then echo "&"; fi)$VAR_VALUE"
      fi
    else
      echo "$(if [ -n "$CURRENT_OPTIONS" ] && [ -n "$VAR_VALUE" ]; then echo "&"; fi)$VAR_VALUE"
    fi

    return 0
  fi
}



####################################
# | **JetBackup5 bash wrappers** | #
####################################

#
# | **Account filters**
#

function manageAccountFilter {
	local OPTIONS=""
  eval "$(find_args "$@")"

	OPTIONS+="$(set_options -r -o "$OPTIONS" -n "action" -v "$action" -m "No action provided and is a requirement!")"

	if [ "$action" == "action=modify" ]; then
		OPTIONS+="$(set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No Account Filter ID provided and is a requirement!")"
		OPTIONS+="$(set_options -o "$OPTIONS" -n "type" -v "$type")"
		OPTIONS+="$(set_options -o "$OPTIONS" -n "name" -v "$name")"
    OPTIONS+="$(set_options -o "$OPTIONS" -n "condition" -v "$condition")"
    OPTIONS+="$(set_options -o "$OPTIONS" -n "list" -v "$list")"
    OPTIONS+="$(set_options -o "$OPTIONS" -n "owner" -v "$owner")"
    OPTIONS+="$(set_options -o "$OPTIONS" -n "range_start" -v "$range_start")"
    OPTIONS+="$(set_options -o "$OPTIONS" -n "range_end" -v "$range_end")"
    OPTIONS+="$(set_options -o "$OPTIONS" -n "regex" -v "$regex")"
    OPTIONS+="$(set_options -o "$OPTIONS" -n "usage" -v "$usage")"
	else
		OPTIONS+="$(set_options -r -o "$OPTIONS" -n "type" -v "$type")"
		OPTIONS+="$(set_options -r -o "$OPTIONS" -n "name" -v "$name")"
    OPTIONS+="$(set_options -r -o "$OPTIONS" -n "condition" -v "$condition")"
    OPTIONS+="$(set_options -o "$OPTIONS" -n "owner" -v "$owner")"
    case $type in
      type=2|type=4|type=64|type=512)
        OPTIONS+="$(set_options -r -o "$OPTIONS" -n "list" -v "$list" -m "No list provided!")"
        ;;
      type=16|type=32)
        OPTIONS+="$(set_options -o "$OPTIONS" -n "usage" -v "$usage" -m "No usage provided!")"
        ;;
      type=128)
        OPTIONS+="$(set_options -o "$OPTIONS" -n "range_start" -v "$range_start" -m "No range_start provided!")"
        OPTIONS+="$(set_options -o "$OPTIONS" -n "range_end" -v "$range_end" -m "No range_end provided!")"
        ;;
      type=256)
        OPTIONS+="$(set_options -o "$OPTIONS" -n "regex" -v "$regex" -m "No regex provided!")"
        ;;
    esac
  fi

	execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function listAccountFilters {
  eval "$(find_args "$@")"

	execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function getAccountFilter {
	local OPTIONS=""
  eval "$(find_args "$@")"

	OPTIONS+="$(set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No Account Filter ID provided and is a requirement!")"

	execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function deleteAccountFilter {
	local OPTIONS=""
  eval "$(find_args "$@")"

	OPTIONS+="$(set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No Account Filter ID provided and is a requirement!")"

	execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function listAccountFilterGroups {
  eval "$(find_args "$@")"

	execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function getAccountFilterGroup {
	local OPTIONS=""
  eval "$(find_args "$@")"

	OPTIONS+="$(set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No filter group id provided and is a requirement!")"

	execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}


#
# | **Accounts**
#

function manageAccount {
	local OPTIONS=""
  eval "$(find_args "$@")"

	OPTIONS+="$(set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No account ID provided and is a requirement!")"
  OPTIONS+="$(set_options -o "$OPTIONS" -n "email" -v "$email" -d "test@gmail.com")"
	OPTIONS+="$(set_options -o "$OPTIONS" -n "backup_quota" -v "$backup_quota")"
	OPTIONS+="$(set_options -o "$OPTIONS" -n "max_snapshots" -v "$max_snapshots" -d "5")"
	OPTIONS+="$(set_options -o "$OPTIONS" -n "queue_priority" -v "$queue_priority")"
	OPTIONS+="$(set_options -o "$OPTIONS" -n "tags" -v "$tags")"

	execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function manageMyAccount {
	local OPTIONS=""
  eval "$(find_args "$@")"

  OPTIONS+="$(set_options -o "$OPTIONS" -n "encryption_key_type" -v "$encryption_key_type")"
  if [ "$encryption_key_type" == "encryption_key_type=1" ]; then
    OPTIONS+="$(set_options -r -o "$OPTIONS" -n "encryption_key" -v "$encryption_key" -m "No encryption_key provided and is a requirement when using encryption_key_type!")"
  fi
  OPTIONS+="$(set_options -o "$OPTIONS" -n "email" -v "$email" -d "test@gmail.com")"
	OPTIONS+="$(set_options -o "$OPTIONS" -n "backup_type" -v "$backup_type")"
	OPTIONS+="$(set_options -o "$OPTIONS" -n "privacy" -v "$privacy")"
	OPTIONS+="$(set_options -o "$OPTIONS" -n "terms" -v "$terms")"

	execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function getAccount {
	local OPTIONS=""
  eval "$(find_args "$@")"

	OPTIONS+="$(set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No account ID provided and is a requirement!")"

	execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function listAccounts {
	local OPTIONS=""
  eval "$(find_args "$@")"

	OPTIONS+="$(set_options -o "$OPTIONS" -n "orphan" -v "$orphan" -d "0")"

	execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function listTags {
  local OPTIONS=""
  eval "$(find_args "$@")"

  execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function getMyAccount {
  local OPTIONS=""
  eval "$(find_args "$@")"

  execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function listAccountEmails {
  local OPTIONS=""
  eval "$(find_args "$@")"

  OPTIONS+="$(set_options -r -o "$OPTIONS" -n "account" -v "$account" -m "No account name provided and is a requirement!")"
  OPTIONS+="$(set_options -o "$OPTIONS" -n "find" -v "$find")"
  OPTIONS+="$(set_options -o "$OPTIONS" -n "sort" -v "$sort")"
  OPTIONS+="$(set_options -o "$OPTIONS" -n "limit" -v "$limit")"
  OPTIONS+="$(set_options -o "$OPTIONS" -n "skip" -v "$skip")"

  execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function reassignAccount {
	local OPTIONS=""
  eval "$(find_args "$@")"

	OPTIONS+="$(set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No account ID provided and is a requirement!")"

	execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function listAssignableAccounts {
	local OPTIONS=""
   eval "$(find_args "$@")"

	OPTIONS+="$(set_options -r -o "$OPTIONS" -n "account" -v "$account" -m "No account Username provided and is a requirement!")"

	execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function createBackupOnDemand {
	local OPTIONS=""
  eval "$(find_args "$@")"

	OPTIONS+="$(set_options -r -o "$OPTIONS" -n "account_id" -v "$account_id" -m "No account_id provided and is a requirement!")"

	execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function manageAccountExcludeList {
	local OPTIONS=""
  eval "$(find_args "$@")"

	OPTIONS+="$(set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No _id provided and is a requirement!")"
	OPTIONS+="$(set_options -r -o "$OPTIONS" -n "excludes" -v "$excludes" -m "No excludes provided and is a requirement!")"

	execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function getAccountExcludeList {
	local OPTIONS=""
  eval "$(find_args "$@")"

	OPTIONS+="$(set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No Account ID provided and is a requirement!")"

	execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function listAccountPackages {
	local OPTIONS=""
  eval "$(find_args "$@")"

	OPTIONS+="$(set_options -o "$OPTIONS" -n "type" -v "$type")"
	OPTIONS+="$(set_options -o "$OPTIONS" -n "all" -v "$all")"

	execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function deleteAccountSnapshots {
	local OPTIONS=""
  eval "$(find_args "$@")"

	OPTIONS+="$(set_options -o "$OPTIONS" -n "approve" -v "$approve")"
	OPTIONS+="$(set_options -r -o "$OPTIONS" -n "user" -v "$user" -m "No user id provided and is a requirement!")"
	OPTIONS+="$(set_options -o "$OPTIONS" -n "range_start" -v "$range_start")"
	OPTIONS+="$(set_options -o "$OPTIONS" -n "range_end" -v "$range_end")"
	OPTIONS+="$(set_options -o "$OPTIONS" -n "job" -v "$job")"
	OPTIONS+="$(set_options -o "$OPTIONS" -n "destination" -v "$destination")"

	execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function manageTag {
	local OPTIONS=""
  eval "$(find_args "$@")"

	OPTIONS+="$(set_options -r -o "$OPTIONS" -n "action" -v "$action" -m "No action provided and is a requirement!")"

	if [ "$action" == "action=modify" ]; then
	  OPTIONS+="$(set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No tag id provided and is a requirement!")"
  else
    OPTIONS+="$(set_options -r -o "$OPTIONS" -n "name" -v "$name" -m "No tag id provided and is a requirement!")"
	fi

	OPTIONS+="$(set_options -o "$OPTIONS" -n "color" -v "$color" -d "#57c785")"
	OPTIONS+="$(set_options -o "$OPTIONS" -n "type" -v "$type" -d "1")"

	execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function getTag {
	local OPTIONS=""
  eval "$(find_args "$@")"

  OPTIONS+="$(set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No tag id provided and is a requirement!")"

	execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function deleteTag {
	local OPTIONS=""
  eval "$(find_args "$@")"

  OPTIONS+="$(set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No tag id provided and is a requirement!")"

	execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}


#
# | **Alerts**
#

function listAlerts {
  eval "$(find_args "$@")"

	execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function getAlert {
	local OPTIONS=""
  eval "$(find_args "$@")"

	OPTIONS+="$(set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No Alert ID provided and is a requirement!")"

	execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function clearAlerts {
    eval "$(find_args "$@")"

	execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}


#
# | **Backup jobs**
#

function manageBackupJob {
	local OPTIONS=""
  eval "$(find_args "$@")"

	OPTIONS+="$(set_options -r -o "$OPTIONS" -n "action" -v "$action" -m "No action provided and is a requirement!")"

	if [ "$action" == "action=modify" ]; then
		OPTIONS+="$(set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No backup job id provided and is a requirement!")"
		OPTIONS+="$(set_options -o "$OPTIONS" -n "type" -v "$type")"
		OPTIONS+="$(set_options -o "$OPTIONS" -n "name" -v "$name")"
		OPTIONS+="$(set_options -o "$OPTIONS" -n "destination" -v "$destination")"
		test "$type" == "1" && OPTIONS+="$(set_options -o "$OPTIONS" -n "contains" -v "$contains" -d "511")"
		OPTIONS+="$(set_options -o "$OPTIONS" -n "structure" -v "$structure")"
	else
		OPTIONS+="$(set_options -r -o "$OPTIONS" -n "type" -v "$type" -m "No job type provided and is a requirement!")"
		OPTIONS+="$(set_options -o "$OPTIONS" -n "name" -v "$name" -d "$(gen_random str 12)")"
		OPTIONS+="$(set_options -r -o "$OPTIONS" -n "destination" -v "$destination" -m "No destination id provided and is a requirement!")"
		OPTIONS+="$(set_options -o "$OPTIONS" -n "contains" -v "$contains" -m "No backup contains provided FULL is 511 for Accounts and 3 for Directories.")"
		test "$type" == "1" || OPTIONS+="$(set_options -r -o "$OPTIONS" -n "include_list" -v "$include_list" -d "0,/home")"
		OPTIONS+="$(set_options -o "$OPTIONS" -n "structure" -v "$structure" -d "1")"
	fi

	OPTIONS+="$(set_options -o "$OPTIONS" -n "options" -v "$options")"
	OPTIONS+="$(set_options -o "$OPTIONS" -n "retry_failed" -v "$retry_failed")"
	test "$type" == "1" && OPTIONS+="$(set_options -o "$OPTIONS" -n "include_list" -v "$include_list")"
	OPTIONS+="$(set_options -o "$OPTIONS" -n "exclude_list" -v "$exclude_list")"
	OPTIONS+="$(set_options -o "$OPTIONS" -n "filters" -v "$filters")"
	OPTIONS+="$(set_options -o "$OPTIONS" -n "schedules" -v "$schedules")"
	OPTIONS+="$(set_options -o "$OPTIONS" -n "time" -v "$time")"
	OPTIONS+="$(set_options -o "$OPTIONS" -n "monitor" -v "$monitor")"
	OPTIONS+="$(set_options -o "$OPTIONS" -n "owner" -v "$owner")"
	OPTIONS+="$(set_options -o "$OPTIONS" -n "disabled" -v "$disabled")"

	execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function getBackupJob {
	local OPTIONS=""
  eval "$(find_args "$@")"

	OPTIONS+="$(set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No backup job id provided and is a requirement!")"

	execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function listBackupJobs {
  local OPTIONS=""
  eval "$(find_args "$@")"

	execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function duplicateBackupJob {
	local OPTIONS=""
  eval "$(find_args "$@")"

	OPTIONS+="$(set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No backup job _id provided and is a requirement!")"

	execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function runBackupJobManually {
	local OPTIONS=""
  eval "$(find_args "$@")"

	OPTIONS+="$(set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No backup job _id provided and is a requirement!")"

	execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function deleteBackupJob {
	local OPTIONS=""
  eval "$(find_args "$@")"

	OPTIONS+="$(set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No backup job _id provided and is a requirement!")"

	execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}


#
# | **Backups**
#

function listBackups {
	local OPTIONS=""
  eval "$(find_args "$@")"

	OPTIONS+="$(set_options -r -o "$OPTIONS" -n "type" -v "$type" -m "No type provided and is a requirement!")"
	OPTIONS+="$(set_options -r -o "$OPTIONS" -n "contains" -v "$contains" -d "511")"
	OPTIONS+="$(set_options -r -o "$OPTIONS" -n "account_id" -v "$account_id" -m "No account_id provided and is a requirement!")"

	execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function listBackupForAccounts {
	local OPTIONS=""
  eval "$(find_args "$@")"

	OPTIONS+="$(set_options -r -o "$OPTIONS" -n "type" -v "$type" -m "No type provided and is a requirement!")"
	OPTIONS+="$(set_options -r -o "$OPTIONS" -n "contains" -v "$contains" -d "511")"

	execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function listBackupForType {
	local OPTIONS=""
  eval "$(find_args "$@")"

	OPTIONS+="$(set_options -r -o "$OPTIONS" -n "type" -v "$type" -m "No type provided and is a requirement!")"
	OPTIONS+="$(set_options -r -o "$OPTIONS" -n "contains" -v "$contains" -d "511")"
	OPTIONS+="$(set_options -r -o "$OPTIONS" -n "account_id" -v "$account_id" -m "No account_id provided and is a requirement!")"

	execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function listBackupForTypeName {
	local OPTIONS=""
  eval "$(find_args "$@")"

	OPTIONS+="$(set_options -r -o "$OPTIONS" -n "type" -v "$type" -m "No type provided and is a requirement!")"
	OPTIONS+="$(set_options -r -o "$OPTIONS" -n "contains" -v "$contains" -d "511")"
	OPTIONS+="$(set_options -r -o "$OPTIONS" -n "account_id" -v "$account_id" -m "No account_id provided and is a requirement!")"
	OPTIONS+="$(set_options -r -o "$OPTIONS" -n "name" -v "$name" -m "No name provided and is a requirement!")"

	execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function listAccountsByFilters {
	local OPTIONS=""
  eval "$(find_args "$@")"

	OPTIONS+="$(set_options -r -o "$OPTIONS" -n "filters" -v "$filters" -m "No filters provided and is a requirement!")"

	execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function getBackupItems {
	local OPTIONS=""
  eval "$(find_args "$@")"

	OPTIONS+="$(set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No backup parent_id provided and is a requirement!")"

	execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function getBackupItem {
	local OPTIONS=""
  eval "$(find_args "$@")"

	OPTIONS+="$(set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No backup item id provided and is a requirement!")"

	execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function manageBackupLock {
	local OPTIONS=""
  eval "$(find_args "$@")"

	OPTIONS+="$(set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No backup parent_id provided and is a requirement!")"
	OPTIONS+="$(set_options -r -o "$OPTIONS" -n "locked" -v "$locked" -d"")"
	OPTIONS+="$(set_options -r -o "$OPTIONS" -n "lock_ttl" -v "$lock_ttl" -d"")"

	execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function deleteSnapshot {
	local OPTIONS=""
  eval "$(find_args "$@")"

  OPTIONS+="$(set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No snapshot id provided and is a requirement!")"

	execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}


#
# | **Clone jobs**
#

function manageCloneJob {
	local OPTIONS=""
  eval "$(find_args "$@")"

	OPTIONS+="$(set_options -r -o "$OPTIONS" -n "action" -v "$action" -m "No action provided and is a requirement!")"

	if [ "$action" == "action=modify" ]; then
		OPTIONS+="$(set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No clone job _id provided and is a requirement!")"
		OPTIONS+="$(set_options -r -o "$OPTIONS" -n "type" -v "$type")"
		OPTIONS+="$(set_options -o "$OPTIONS" -n "name" -v "$name")"
		OPTIONS+="$(set_options -r -o "$OPTIONS" -n "destination" -v "$destination")"
		OPTIONS+="$(set_options -o "$OPTIONS" -n "contains" -v "$contains")"
	else
		OPTIONS+="$(set_options -r -o "$OPTIONS" -n "type" -v "$type" -m "No job type provided and is a requirement!")"
		OPTIONS+="$(set_options -o "$OPTIONS" -n "name" -v "$name" -d "$(gen_random str 12)")"
		OPTIONS+="$(set_options -r -o "$OPTIONS" -n "destination" -v "$destination" -m "No destination _id provided and is a requirement!")"
		OPTIONS+="$(set_options -o "$OPTIONS" -n "contains" -v "$contains" -d "511")"
	fi

	OPTIONS+="$(set_options -o "$OPTIONS" -n "default_owner" -v "$default_owner")"
	OPTIONS+="$(set_options -o "$OPTIONS" -n "default_package" -v "$default_package")"
	OPTIONS+="$(set_options -o "$OPTIONS" -n "Owner" -v "$Owner")"
	OPTIONS+="$(set_options -o "$OPTIONS" -n "monitor" -v "$monitor")"
	OPTIONS+="$(set_options -o "$OPTIONS" -n "Disabled" -v "$Disabled")"

	execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function getCloneJob {
	local OPTIONS=""
  eval "$(find_args "$@")"

	OPTIONS+="$(set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No clone job _id provided and is a requirement!")"

	execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function listCloneJobs {
  local OPTIONS=""
  eval "$(find_args "$@")"

	execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function duplicateCloneJob {
	local OPTIONS=""
  eval "$(find_args "$@")"

	OPTIONS+="$(set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No clone job _id provided and is a requirement!")"

	execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function runCloneJobManually {
	local OPTIONS=""
  eval "$(find_args "$@")"

	OPTIONS+="$(set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No clone job _id provided and is a requirement!")"

	execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function deleteCloneJob {
	local OPTIONS=""
  eval "$(find_args "$@")"

	OPTIONS+="$(set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No clone job _id provided and is a requirement!")"

	execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}


#
# | **Dashboard**
#

function getDashboardDetails {
    local OPTIONS=""
    eval "$(find_args "$@")"

    execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function getStatistics {
    local OPTIONS=""
    eval "$(find_args "$@")"

    execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function getInfo {
    local OPTIONS=""
    eval "$(find_args "$@")"

    execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function listShowcase {
    local OPTIONS=""
    eval "$(find_args "$@")"

    execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}


#
# | **Destinations**
#

function manageDestination {
	local OPTIONS=""
  eval "$(find_args "$@")"

	OPTIONS+="$(set_options -r -o "$OPTIONS" -n "action" -v "$action" -m "No action provided and is a requirement!")"

	if [ "$action" == "action=modify" ]; then
		OPTIONS+="$(set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No destination id provided and is a requirement!")"
		OPTIONS+="$(set_options -o "$OPTIONS" -n "type" -v "$type")"
		OPTIONS+="$(set_options -o "$OPTIONS" -n "options" -v "$options")"
		OPTIONS+="$(set_options -o "$OPTIONS" -n "name" -v "$name")"
	else
		OPTIONS+="$(set_options -r -o "$OPTIONS" -n "type" -v "$type" -m "No destination type provided and is a requirement!")"
		OPTIONS+="$(set_options -r -o "$OPTIONS" -n "options" -v "$options" -m "No options provided and is a requirement!")"
		OPTIONS+="$(set_options -o "$OPTIONS" -n "name" -v "$name" -d "$(gen_random str 12)")"
	fi

	OPTIONS+="$(set_options -o "$OPTIONS" -n "owner" -v "$owner")"
	OPTIONS+="$(set_options -o "$OPTIONS" -n "disabled" -v "$disabled")"
	OPTIONS+="$(set_options -o "$OPTIONS" -n "readonly" -v "$readonly")"
	OPTIONS+="$(set_options -o "$OPTIONS" -n "dr" -v "$dr")"
	OPTIONS+="$(set_options -o "$OPTIONS" -n "disk_limit" -v "$disk_limit")"
	OPTIONS+="$(set_options -o "$OPTIONS" -n "hidden" -v "$hidden")"

	execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function getDestination {
	local OPTIONS=""
    eval "$(find_args "$@")"

	OPTIONS+="$(set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No destination id provided and is a requirement!")"

	execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function listDestinations {
    eval "$(find_args "$@")"

	execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function listDestinationTypes {
	eval "$(find_args "$@")"

	execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function validateDestination {
	local OPTIONS=""
    eval "$(find_args "$@")"

	OPTIONS+="$(set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No destination id provided and is a requirement!")"

	execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function deleteDestination {
	local OPTIONS=""
    eval "$(find_args "$@")"

	OPTIONS+="$(set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No destination id provided and is a requirement!")"

	execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function reindexDestination {
	local OPTIONS=""
    eval "$(find_args "$@")"

	OPTIONS+="$(set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No destination id provided and is a requirement!")"
	OPTIONS+="$(set_options -o "$OPTIONS" -n "account_id" -v "$account_id")"
	OPTIONS+="$(set_options -o "$OPTIONS" -n "account_username" -v "$account_username")"
	OPTIONS+="$(set_options -o "$OPTIONS" -n "by_snap" -v "$by_snap")"

	execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}


#
# | **Downloads**
#

function getDownload {
	local OPTIONS=""
  eval "$(find_args "$@")"

	OPTIONS+="$(set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No Download Object ID provided and is a requirement!")"

	execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function listDownloads {
	local OPTIONS=""
  eval "$(find_args "$@")"

	execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function manageDownloadNotes {
	local OPTIONS=""
  eval "$(find_args "$@")"

	OPTIONS+="$(set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No Download Object ID provided and is a requirement!")"
	OPTIONS+="$(set_options -r -o "$OPTIONS" -n "notes" -v "$notes")"

	execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}


#
# | **FilePermissions**
#

function manageFilePermissions {
  local OPTIONS=""
  eval "$(find_args "$@")"

  OPTIONS+="$(set_options -r -m "No action provided and is a requirement!" -o "$OPTIONS" -n "action" -v "$action")"

  if [ "$action" == "action=modify" ]; then
    OPTIONS+="$(set_options -r -m "No File permissions ID provided and is a requirement!" -o "$OPTIONS" -n "id" -v "$id")"
    OPTIONS+="$(set_options -o "$OPTIONS" -n "regex" -v "$regex")"
    OPTIONS+="$(set_options -o "$OPTIONS" -n "category" -v "$category")"
  else
    OPTIONS+="$(set_options -r -m "No regex for the File/Folder name and is a requirement!" -o "$OPTIONS" -n "regex" -v "$regex")"
    OPTIONS+="$(set_options -r -m "No category provided and is a requirement!" -o "$OPTIONS" -n "category" -v "$category")"
  fi

  OPTIONS+="$(set_options -o "$OPTIONS" -n "owner" -v "$owner")"
  OPTIONS+="$(set_options -o "$OPTIONS" -n "group" -v "$group")"
  OPTIONS+="$(set_options -o "$OPTIONS" -n "recursive" -v "$recursive")"
  OPTIONS+="$(set_options -o "$OPTIONS" -n "dirs_permissions" -v "$dirs_permissions")"
  OPTIONS+="$(set_options -o "$OPTIONS" -n "files_permissions" -v "$files_permissions")"

  execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function getFilePermissions {
  local OPTIONS=""
  eval "$(find_args "$@")"

  OPTIONS+="$(set_options -r -m "No File permissions ID provided and is a requirement!" -o "$OPTIONS" -n "id" -v "$id")"

  execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function listFilePermissions {
  local OPTIONS=""
  eval "$(find_args "$@")"

  OPTIONS+="$(set_options -o "$OPTIONS" -n "find" -v "$find")"
  OPTIONS+="$(set_options -o "$OPTIONS" -n "sort" -v "$sort")"
  OPTIONS+="$(set_options -o "$OPTIONS" -n "limit" -v "$limit")"
  OPTIONS+="$(set_options -o "$OPTIONS" -n "skip" -v "$skip")"

  execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function deleteFilePermissions {
  local OPTIONS=""
  eval "$(find_args "$@")"

  OPTIONS+="$(set_options -r -m "No File permissions ID provided and is a requirement!" -o "$OPTIONS" -n "id" -v "$id")"

  execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}


#
# | **Hooks**
#

function manageHook {
    local OPTIONS=""
    eval "$(find_args "$@")"

    OPTIONS+="$(set_options -r -m "No Action provided!" -o "$OPTIONS" -n "action" -v "$action")"

    if [ "$action" == "action=modify" ]; then
      OPTIONS+="$(set_options -r -m "No id provided!" -o "$OPTIONS" -n "id" -v "$id")"
      OPTIONS+="$(set_options -o "$OPTIONS" -n "name" -v "$name")"
      OPTIONS+="$(set_options -o "$OPTIONS" -n "position" -v "$position")"
      OPTIONS+="$(set_options -o "$OPTIONS" -n "position_type" -v "$position_type")"
      OPTIONS+="$(set_options -o "$OPTIONS" -n "script" -v "$script")"
    else
      OPTIONS+="$(set_options -r -d "$(gen_random str 16)" -o "$OPTIONS" -n "name" -v "$name")"
      OPTIONS+="$(set_options -r -m "No position provided!" -o "$OPTIONS" -n "position" -v "$position")"
      OPTIONS+="$(set_options -r -m "No position type provided!" -o "$OPTIONS" -n "position_type" -v "$position_type")"
      OPTIONS+="$(set_options -r -m "No script provided!" -o "$OPTIONS" -n "script" -v "$script")"
    fi
    OPTIONS+="$(set_options -o "$OPTIONS" -n "data_list" -v "$data_list")"
    OPTIONS+="$(set_options -o "$OPTIONS" -n "disabled" -v "$disabled")"

    execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function listHooks {
    local OPTIONS=""
    eval "$(find_args "$@")"

    OPTIONS+="$(set_options -o "$OPTIONS" -n "find" -v "$find")"
    OPTIONS+="$(set_options -o "$OPTIONS" -n "sort" -v "$sort")"
    OPTIONS+="$(set_options -o "$OPTIONS" -n "limit" -v "$limit")"
    OPTIONS+="$(set_options -o "$OPTIONS" -n "skip" -v "$skip")"

    execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function getHook {
    local OPTIONS=""
    eval "$(find_args "$@")"

    OPTIONS+="$(set_options -r -m "No id provided!" -o "$OPTIONS" -n "id" -v "$id")"

    execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function deleteHook {
    local OPTIONS=""
    eval "$(find_args "$@")"

    OPTIONS+="$(set_options -r -m "No id provided!" -o "$OPTIONS" -n "id" -v "$id")"

    execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}


#
# **Logs**
#

function listLogs {
	local OPTIONS=""
  eval "$(find_args "$@")"

	execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function getLog {
	local OPTIONS=""
  eval "$(find_args "$@")"

  OPTIONS+="$(set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No Log ID provided and is a requirement!")"

	execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function deleteLog {
	local OPTIONS=""
  eval "$(find_args "$@")"

	OPTIONS+="$(set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No Log ID provided and is a requirement!")"

	execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function listLogItems {
	local OPTIONS=""
  eval "$(find_args "$@")"

  OPTIONS+="$(set_options -r -o "$OPTIONS" -n "log_id" -v "$log_id" -m "No Log ID provided and is a requirement!")"

	execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function getLogItem {
	local OPTIONS=""
  eval "$(find_args "$@")"

  OPTIONS+="$(set_options -r -o "$OPTIONS" -n "_id" -v "$id" -m "No Log Item ID provided and is a requirement!")"
  OPTIONS+="$(set_options -r -o "$OPTIONS" -n "log_id" -v "$log_id" -m "No Log ID provided and is a requirement!")"

	execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}


#
# **PanelAPI**
#

function Panel_ListTokens {
  local OPTIONS=""
  eval "$(find_args "$@")"

  OPTIONS+="$(set_options -o "$OPTIONS" -n "find" -v "$find")"
  OPTIONS+="$(set_options -o "$OPTIONS" -n "sort" -v "$sort")"
  OPTIONS+="$(set_options -o "$OPTIONS" -n "limit" -v "$limit")"
  OPTIONS+="$(set_options -o "$OPTIONS" -n "skip" -v "$skip")"

  execute_function "${FUNCNAME//_//}" "$OPTIONS" "$request"
}

function Panel_GetToken {
  local OPTIONS=""
  eval "$(find_args "$@")"

  OPTIONS+="$(set_options -r -m "No Token ID provided and is required for the getToken call!" -o "$OPTIONS" -n "id" -v "$id")"

  execute_function "${FUNCNAME//_//}" "$OPTIONS" "$request"
}

function Panel_ManageToken {
  local OPTIONS=""
  eval "$(find_args "$@")"

  OPTIONS+="$(set_options -r -m "No action provided and is required for the manageToken call!" -o "$OPTIONS" -n "action" -v "$action")"
  if [ "$action" == "action=modify" ]; then
    OPTIONS+="$(set_options -r -m "No Token ID provided and is required for the manageToken call!" -o "$OPTIONS" -n "id" -v "$id")"
    OPTIONS+="$(set_options -o "$OPTIONS" -n "description" -v "$description")"
  else
    OPTIONS+="$(set_options -r -d "$(gen_random str 16)" -o "$OPTIONS" -n "description" -v "$description")"
  fi

  OPTIONS+="$(set_options -o "$OPTIONS" -n "ip" -v "$ip")"
  OPTIONS+="$(set_options -o "$OPTIONS" -n "username" -v "$username")"
  OPTIONS+="$(set_options -o "$OPTIONS" -n "expiry" -v "$expiry")"

  execute_function "${FUNCNAME//_//}" "$OPTIONS" "$request"
}

function Panel_DeleteToken {
  local OPTIONS=""
  eval "$(find_args "$@")"

  OPTIONS+="$(set_options -r -m "No Token ID provided and is required for the deleteToken call!" -o "$OPTIONS" -n "id" -v "$id")"

  execute_function "${FUNCNAME//_//}" "$OPTIONS" "$request"
}

function Panel_CreateUserSession {
  local OPTIONS=""
  eval "$(find_args "$@")"

  OPTIONS+="$(set_options -r -m "No username to generate a login URL for provided and is required for the createUserSession call!" -o "$OPTIONS" -n "user" -v "$user")"

  execute_function "${FUNCNAME//_//}" "$OPTIONS" "$request"
}

function Panel_CreateAccount {
  local OPTIONS=""
  eval "$(find_args "$@")"

  OPTIONS+="$(set_options -r -m "No account name and is required for the CreateAccount call!" -o "$OPTIONS" -n "account" -v "$account")"

  execute_function "${FUNCNAME//_//}" "$OPTIONS" "$request"
}


#
# | **Permissions**
#

function managePermissions {
    local OPTIONS=""
    eval "$(find_args "$@")"

    OPTIONS+="$(set_options -r -m "Username is required!" -o "$OPTIONS" -n "username" -v "$username")"
    OPTIONS+="$(set_options -o "$OPTIONS" -n "permissions" -v "$permissions")"

    execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function getPermissions {
    local OPTIONS=""
    eval "$(find_args "$@")"

    OPTIONS+="$(set_options -r -m "Username is required!" -o "$OPTIONS" -n "username" -v "$username")"

    execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function resetPermissions {
    local OPTIONS=""
    eval "$(find_args "$@")"

    OPTIONS+="$(set_options -r -m "Username is required!" -o "$OPTIONS" -n "username" -v "$username")"

    execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function listPermissions {
    local OPTIONS=""
    eval "$(find_args "$@")"

    execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}


#
# | **Plugins**
#

function listPlugins {
	local OPTIONS=""
  eval "$(find_args "$@")"

	OPTIONS+="$(set_options -o "$OPTIONS" -n "filter" -v "$filter")"

	execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function listPackages {
	local OPTIONS=""
  eval "$(find_args "$@")"

	OPTIONS+="$(set_options -o "$OPTIONS" -n "filter" -v "$filter")"
	OPTIONS+="$(set_options -o "$OPTIONS" -n "find" -v "$find")"

	execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function listRepositories {
	local OPTIONS=""
  eval "$(find_args "$@")"

	OPTIONS+="$(set_options -o "$OPTIONS" -n "filter" -v "$filter")"

	execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function manageRepository {
	local OPTIONS=""
  eval "$(find_args "$@")"

  OPTIONS+="$(set_options -r -o "$OPTIONS" -n "action" -v "$action" -m "No action provided and is a requirement!")"

  if [ "$action" == "action=modify" ]; then
	  OPTIONS+="$(set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No Repository ID provided and is a requirement!")"
	fi

	OPTIONS+="$(set_options -o "$OPTIONS" -n "url" -v "$url")"
	OPTIONS+="$(set_options -o "$OPTIONS" -n "name" -v "$name")"

	execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function deleteRepository {
	local OPTIONS=""
  eval "$(find_args "$@")"

	OPTIONS+="$(set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No Repository ID provided and is a requirement!")"

	execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function getPlugin {
	local OPTIONS=""
  eval "$(find_args "$@")"

	OPTIONS+="$(set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No Repository ID provided and is a requirement!")"

	execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function managePlugin {
	local OPTIONS=""
  eval "$(find_args "$@")"

	OPTIONS+="$(set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No Repository ID provided and is a requirement!")"
	OPTIONS+="$(set_options -o "$OPTIONS" -n "disabled" -v "$disabled")"
	OPTIONS+="$(set_options -o "$OPTIONS" -n "repo" -v "$repo")"
	OPTIONS+="$(set_options -o "$OPTIONS" -n "visible" -v "$visible")"
	OPTIONS+="$(set_options -o "$OPTIONS" -n "permissions" -v "$permissions")"

	execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function installPlugin {
	local OPTIONS=""
  eval "$(find_args "$@")"

	OPTIONS+="$(set_options -r -o "$OPTIONS" -n "package_id" -v "$package_id" -m "No Plugin ID provided and is a requirement!")"
	OPTIONS+="$(set_options -o "$OPTIONS" -n "package_name" -v "$package_name")"
	OPTIONS+="$(set_options -o "$OPTIONS" -n "disabled" -v "$disabled")"

	execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function uninstallPlugin {
	local OPTIONS=""
  eval "$(find_args "$@")"

	OPTIONS+="$(set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No Plugin ID provided and is a requirement!")"

	execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function updatePlugin {
	local OPTIONS=""
  eval "$(find_args "$@")"

	OPTIONS+="$(set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No Plugin ID provided and is a requirement!")"

	execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function listAvailablePlugins {
	local OPTIONS=""
  eval "$(find_args "$@")"

	OPTIONS+="$(set_options -o "$OPTIONS" -n "filter" -v "$filter")"

	execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function manageSecurityPlugin {
	local OPTIONS=""
  eval "$(find_args "$@")"

	OPTIONS+="$(set_options -r -o "$OPTIONS" -n "plugin" -v "$plugin" -m "No Security Plugin ID provided and is a requirement!")"
	OPTIONS+="$(set_options -o "$OPTIONS" -n "lock" -v "$lock")"
	OPTIONS+="$(set_options -o "$OPTIONS" -n "restore" -v "$restore")"

	execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}


#
# | **Queues**
#

function addQueueItems {
	local OPTIONS=""
  eval "$(find_args "$@")"

	OPTIONS+="$(set_options -r -o "$OPTIONS" -n "type" -v "$type" -m "No type provided and is a requirement!")"
	OPTIONS+="$(set_options -o "$OPTIONS" -n "snapshot_id" -v "$snapshot_id")"

	if [ -z "$snapshot_id" ]; then
    OPTIONS+="$(set_options -r -o "$OPTIONS" -n "items" -v "$items" -m "REQUIRED When not using the snapshot_id.")"
  else
    OPTIONS+="$(set_options -r -o "$OPTIONS" -n "snapshot_id" -v "$snapshot_id" -m "No snapshot_id provided and is a requirement!")"
  fi

  OPTIONS+="$(set_options -o "$OPTIONS" -n "options" -v "$options")"

	execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function getQueueGroup {
	local OPTIONS=""
  eval "$(find_args "$@")"

	OPTIONS+="$(set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No ID of the queue group object provided and is a requirement!")"

	execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function getQueueItem {
	local OPTIONS=""
  eval "$(find_args "$@")"

	OPTIONS+="$(set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No ID of the queue item object provided and is a requirement!")"

	execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function listQueueGroups {
	local OPTIONS=""
  eval "$(find_args "$@")"

	OPTIONS+="$(set_options -r -o "$OPTIONS" -n "type" -v "$type" -m "No Queue Group Type provided and is a requirement!")"

	execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function listQueueItems {
	local OPTIONS=""
  eval "$(find_args "$@")"

	OPTIONS+="$(set_options -r -o "$OPTIONS" -n "group_id" -v "$group_id" -m "No Queue Group ID provided and is a requirement!")"

	execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function clearQueue {
  local OPTIONS=""
  eval "$(find_args "$@")"

	execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function stopQueueGroup {
	local OPTIONS=""
  eval "$(find_args "$@")"

	OPTIONS+="$(set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No Queue Group ID provided and is a requirement!")"

	execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function stopAllQueueGroup {
  local OPTIONS=""
  eval "$(find_args "$@")"

	execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function manageQueuePriority {
	local OPTIONS=""
  eval "$(find_args "$@")"

	OPTIONS+="$(set_options -r -o "$OPTIONS" -n "action" -v "$action" -m "No action provided and is a requirement!")"

	if [ "$action" == "action=modify" ]; then
		OPTIONS+="$(set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No ID of the queue priority group provided and is a requirement!")"
		OPTIONS+="$(set_options -o "$OPTIONS" -n "download_priority" -v "$download_priority")"
		OPTIONS+="$(set_options -o "$OPTIONS" -n "restore_priority" -v "$restore_priority")"
		OPTIONS+="$(set_options -o "$OPTIONS" -n "backup_priority" -v "$backup_priority")"
		OPTIONS+="$(set_options -o "$OPTIONS" -n "clone_priority" -v "$clone_priority")"
		OPTIONS+="$(set_options -o "$OPTIONS" -n "name" -v "$name")"
	else
		OPTIONS+="$(set_options -r -o "$OPTIONS" -n "download_priority" -v "$download_priority" -m "No download_priority provided and is a requirement!")"
		OPTIONS+="$(set_options -r -o "$OPTIONS" -n "restore_priority" -v "$restore_priority" -m "No restore_priority provided and is a requirement!")"
		OPTIONS+="$(set_options -r -o "$OPTIONS" -n "backup_priority" -v "$backup_priority" -m "No backup_priority provided and is a requirement!")"
		OPTIONS+="$(set_options -o "$OPTIONS" -n "clone_priority" -v "$clone_priority")"
		OPTIONS+="$(set_options -r -o "$OPTIONS" -n "name" -v "$name" -d "$(gen_random str 12)")"
	fi

	OPTIONS+="$(set_options -o "$OPTIONS" -n "tags" -v "$tags")"
	OPTIONS+="$(set_options -o "$OPTIONS" -n "default" -v "$default")"

	execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function getQueuePriority {
	local OPTIONS=""
  eval "$(find_args "$@")"

	OPTIONS+="$(set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No ID of the queue priority group provided and is a requirement!")"

	execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function listQueuePriorities {
	local OPTIONS=""
  eval "$(find_args "$@")"

	OPTIONS+="$(set_options -o "$OPTIONS" -n "priorities" -v "$priorities")"
	OPTIONS+="$(set_options -o "$OPTIONS" -n "total" -v "$total")"

	execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function deleteQueuePriority {
	local OPTIONS=""
  eval "$(find_args "$@")"

	OPTIONS+="$(set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No ID of the queue priority group provided and is a requirement!")"

	execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function rerunFailedQueueGroup {
	local OPTIONS=""
  eval "$(find_args "$@")"

	OPTIONS+="$(set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No ID of the queue priority group provided and is a requirement!")"

	execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function addMultiAccountQueueItems {
	local OPTIONS=""
  eval "$(find_args "$@")"

	OPTIONS+="$(set_options -r -o "$OPTIONS" -n "type" -v "$type" -m "No type provided and is a requirement!")"
	OPTIONS+="$(set_options -r -o "$OPTIONS" -n "backup_contains" -v "$backup_contains" -m "No backup_contains provided and is a requirement!")"
	OPTIONS+="$(set_options -r -o "$OPTIONS" -n "filters" -v "$filters" -m "No filters provided and is a requirement!")"
	OPTIONS+="$(set_options -r -o "$OPTIONS" -n "excluded" -v "$excluded" -m "No excluded provided and is a requirement!")"
	test "$type" == "type=2" && OPTIONS+="$(set_options -r -o "$OPTIONS" -n "options" -v "$options" -m "No options provided and is a requirement!")"

	execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}


#
# | **RestoreConditions**
#

function manageRestoreCondition {
    local OPTIONS=""
    eval "$(find_args "$@")"

    OPTIONS+="$(set_options -r -m "No action provided!" -o "$OPTIONS" -n "action" -v "$action")"

    if [ "$action" == "action=modify" ]; then
      OPTIONS+="$(set_options -r -m "No ID provided!" -o "$OPTIONS" -n "id" -v "$id")"
    fi

    OPTIONS+="$(set_options -r -m "Missing the string of text for the user to agree!" -o "$OPTIONS" -n "condition" -v "$condition")"
    OPTIONS+="$(set_options -o "$OPTIONS" -n "disabled" -v "$disabled")"

    execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function listRestoreConditions {
    local OPTIONS=""
    eval "$(find_args "$@")"

    OPTIONS+="$(set_options -o "$OPTIONS" -n "find" -v "$find")"
    OPTIONS+="$(set_options -o "$OPTIONS" -n "sort" -v "$sort")"
    OPTIONS+="$(set_options -o "$OPTIONS" -n "limit" -v "$limit")"
    OPTIONS+="$(set_options -o "$OPTIONS" -n "skip" -v "$skip")"

    execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function getRestoreCondition {
    local OPTIONS=""
    eval "$(find_args "$@")"

    OPTIONS+="$(set_options -r -m "No ID provided!" -o "$OPTIONS" -n "id" -v "$id")"

    execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function deleteRestoreCondition {
    local OPTIONS=""
    eval "$(find_args "$@")"

    OPTIONS+="$(set_options -r -m "No ID provided!" -o "$OPTIONS" -n "id" -v "$id")"

    execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}


#
# | **Schedules**
#

function manageSchedule {
	local OPTIONS=""
  eval "$(find_args "$@")"

	OPTIONS+="$(set_options -r -o "$OPTIONS" -n "action" -v "$action" -m "No action provided and is a requirement!")"

	if [ "$action" == "action=modify" ]; then
		OPTIONS+="$(set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No schedule _id provided and is a requirement!")"
		OPTIONS+="$(set_options -o "$OPTIONS" -n "type" -v "$type")"
		OPTIONS+="$(set_options -o "$OPTIONS" -n "type_data" -v "$type_data")"
		OPTIONS+="$(set_options -o "$OPTIONS" -n "name" -v "$name")"
	else
	  OPTIONS+="$(set_options -r -o "$OPTIONS" -n "name" -v "$name" -m "No Schedule name provided and is a requirement!")"
		OPTIONS+="$(set_options -r -o "$OPTIONS" -n "type" -v "$type" -m "No Schedule type provided and is a requirement!")"
		OPTIONS+="$(set_options -r -o "$OPTIONS" -n "type_data" -v "$type_data" -m "No type_data provided and is a requirement!")"
	fi

	OPTIONS+="$(set_options -o "$OPTIONS" -n "delay_amount" -v "$delay_amount")"
	OPTIONS+="$(set_options -o "$OPTIONS" -n "delay_type" -v "$delay_type")"

	execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function listSchedules {
  local OPTIONS=""
  eval "$(find_args "$@")"

	execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function getSchedule {
	local OPTIONS=""
  eval "$(find_args "$@")"

	OPTIONS+="$(set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No schedule job _id provided and is a requirement!")"

	execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function deleteSchedule {
	local OPTIONS=""
  eval "$(find_args "$@")"

	OPTIONS+="$(set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No schedule job _id provided and is a requirement!")"

	execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}


#
# | **Settings**
#

function getSettingsGeneral {
  local OPTIONS=""
  eval "$(find_args "$@")"

  execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function manageSettingsGeneral {
  local OPTIONS=""
  eval "$(find_args "$@")"

  OPTIONS+="$(set_options -o "$OPTIONS" -n "error_reporting" -v "$error_reporting")"
  OPTIONS+="$(set_options -o "$OPTIONS" -n "debug" -v "$debug")"
  OPTIONS+="$(set_options -o "$OPTIONS" -n "workspace_path" -v "$workspace_path")"
  OPTIONS+="$(set_options -o "$OPTIONS" -n "downloads_path" -v "$downloads_path")"
  OPTIONS+="$(set_options -o "$OPTIONS" -n "orphan_backup_ttl" -v "$orphan_backup_ttl")"
  OPTIONS+="$(set_options -o "$OPTIONS" -n "manually_backup_ttl" -v "$manually_backup_ttl")"
  OPTIONS+="$(set_options -o "$OPTIONS" -n "manually_backup_retain" -v "$manually_backup_retain")"
  OPTIONS+="$(set_options -o "$OPTIONS" -n "logs_ttl" -v "$logs_ttl")"
  OPTIONS+="$(set_options -o "$OPTIONS" -n "alerts_ttl" -v "$alerts_ttl")"
  OPTIONS+="$(set_options -o "$OPTIONS" -n "downloads_ttl" -v "$downloads_ttl")"
  OPTIONS+="$(set_options -o "$OPTIONS" -n "email_integration" -v "$email_integration")"
  OPTIONS+="$(set_options -o "$OPTIONS" -n "time_format" -v "$time_format")"
  OPTIONS+="$(set_options -o "$OPTIONS" -n "use_community_languages" -v "$use_community_languages")"
  OPTIONS+="$(set_options -o "$OPTIONS" -n "show_damaged_backups" -v "$show_damaged_backups")"

  execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function getSettingsPerformance {
  local OPTIONS=""
  eval "$(find_args "$@")"

  execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function manageSettingsPerformance {
  local OPTIONS=""
  eval "$(find_args "$@")"

  OPTIONS+="$(set_options -o "$OPTIONS" -n "queueable_forks" -v "$queueable_forks")"
  OPTIONS+="$(set_options -o "$OPTIONS" -n "backup_forks" -v "$backup_forks")"
  OPTIONS+="$(set_options -o "$OPTIONS" -n "system_forks" -v "$system_forks")"
  OPTIONS+="$(set_options -o "$OPTIONS" -n "backup_fork_ttl" -v "$backup_fork_ttl")"
  OPTIONS+="$(set_options -o "$OPTIONS" -n "mysqldump_skip_lock" -v "$mysqldump_skip_lock")"
  OPTIONS+="$(set_options -o "$OPTIONS" -n "mysqldump_opt" -v "$mysqldump_opt")"
  OPTIONS+="$(set_options -o "$OPTIONS" -n "mysqldump_max_packet" -v "$mysqldump_max_packet")"
  OPTIONS+="$(set_options -o "$OPTIONS" -n "mysqldump_force" -v "$mysqldump_force")"
  OPTIONS+="$(set_options -o "$OPTIONS" -n "mysqldump_multibyte" -v "$mysqldump_multibyte")"
  OPTIONS+="$(set_options -o "$OPTIONS" -n "mysqldump_gtid_purged" -v "$mysqldump_gtid_purged")"
  OPTIONS+="$(set_options -o "$OPTIONS" -n "directories_queue_priority" -v "$directories_queue_priority")"
  OPTIONS+="$(set_options -o "$OPTIONS" -n "limit_account_downloads" -v "$limit_account_downloads")"
  OPTIONS+="$(set_options -o "$OPTIONS" -n "backup_integrity_check_schedule" -v "$backup_integrity_check_schedule")"

  execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function getSettingsResource {
    local OPTIONS=""
    eval "$(find_args "$@")"

    execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function manageSettingsResource {
  local OPTIONS=""
  eval "$(find_args "$@")"

  OPTIONS+="$(set_options -o "$OPTIONS" -n "cpu_limit" -v "$cpu_limit")"
  OPTIONS+="$(set_options -o "$OPTIONS" -n "memory_limit" -v "$memory_limit")"
  OPTIONS+="$(set_options -o "$OPTIONS" -n "io_read_limit" -v "$io_read_limit")"
  OPTIONS+="$(set_options -o "$OPTIONS" -n "io_write_limit" -v "$io_write_limit")"

  execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function getSettingsRestore {
  local OPTIONS=""
  eval "$(find_args "$@")"

  execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function manageSettingsRestore {
  local OPTIONS=""
  eval "$(find_args "$@")"

  OPTIONS+="$(set_options -o "$OPTIONS" -n "limit_times" -v "$limit_times")"
  OPTIONS+="$(set_options -o "$OPTIONS" -n "limit_hours" -v "$limit_hours")"
  OPTIONS+="$(set_options -o "$OPTIONS" -n "package_selection" -v "$package_selection")"
  OPTIONS+="$(set_options -o "$OPTIONS" -n "lock_homedir" -v "$lock_homedir")"

  execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function getSettingsSecurity {
  local OPTIONS=""
  eval "$(find_args "$@")"

  execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function manageSettingsSecurity {
  local OPTIONS=""
  eval "$(find_args "$@")"

  OPTIONS+="$(set_options -o "$OPTIONS" -n "plugin" -v "$plugin")"
  OPTIONS+="$(set_options -o "$OPTIONS" -n "restore" -v "$restore")"
  OPTIONS+="$(set_options -o "$OPTIONS" -n "lock" -v "$lock")"

  execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function getSettingsPrivacy {
  local OPTIONS=""
  eval "$(find_args "$@")"

  execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function manageSettingsPrivacy {
  local OPTIONS=""
  eval "$(find_args "$@")"

  OPTIONS+="$(set_options -o "$OPTIONS" -n "user_agreement" -v "$user_agreement")"
  OPTIONS+="$(set_options -o "$OPTIONS" -n "privacy_policy" -v "$privacy_policy")"
  OPTIONS+="$(set_options -o "$OPTIONS" -n "encryption_selection" -v "$encryption_selection")"
  OPTIONS+="$(set_options -o "$OPTIONS" -n "forgotten_ttl" -v "$forgotten_ttl")"

  execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function getSettingsPanel {
  local OPTIONS=""
  eval "$(find_args "$@")"

  execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function manageSettingsPanel {
  local OPTIONS=""
  eval "$(find_args "$@")"

  OPTIONS+="$(set_options -o "$OPTIONS" -n "options" -v "$options")"

  execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function getSettingsSnapshots {
  local OPTIONS=""
  eval "$(find_args "$@")"

  execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function manageSettingsSnapshots {
  local OPTIONS=""
  eval "$(find_args "$@")"

  OPTIONS+="$(set_options -o "$OPTIONS" -n "ttl" -v "$ttl")"
  OPTIONS+="$(set_options -o "$OPTIONS" -n "retain" -v "$retain")"
  OPTIONS+="$(set_options -o "$OPTIONS" -n "backup" -v "$backup")"
  OPTIONS+="$(set_options -o "$OPTIONS" -n "rule_size" -v "$rule_size")"
  OPTIONS+="$(set_options -o "$OPTIONS" -n "rule_inodes" -v "$rule_inodes")"

  execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function manageNotificationIntegration {
  local OPTIONS=""
  eval "$(find_args "$@")"

  OPTIONS+="$(set_options -r -m "No action provided!" -o "$OPTIONS" -n "action" -v "$action")"

	if [ "$action" == "action=modify" ]; then
    OPTIONS+="$(set_options -r -m "No notification id provided!" -o "$OPTIONS" -n "id" -v "$id")"
    OPTIONS+="$(set_options -o "$OPTIONS" -n "name" -v "$name")"
    OPTIONS+="$(set_options -o "$OPTIONS" -n "type" -v "$type")"
  else
    OPTIONS+="$(set_options -r -m "No notification name provided!" -o "$OPTIONS" -n "name" -v "$name")"
    OPTIONS+="$(set_options -r -m "No notification type provided!" -o "$OPTIONS" -n "type" -v "$type")"
  fi

  OPTIONS+="$(set_options -o "$OPTIONS" -n "owner" -v "$owner")"
  OPTIONS+="$(set_options -o "$OPTIONS" -n "frequency" -v "$frequency")"
  OPTIONS+="$(set_options -o "$OPTIONS" -n "disabled" -v "$disabled")"
  OPTIONS+="$(set_options -o "$OPTIONS" -n "options" -v "$options")"

  execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function listNotificationIntegrationTypes {
  local OPTIONS=""
  eval "$(find_args "$@")"

  execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function listNotificationIntegrations {
  local OPTIONS=""
  eval "$(find_args "$@")"

  OPTIONS+="$(set_options -o "$OPTIONS" -n "find" -v "$find")"
  OPTIONS+="$(set_options -o "$OPTIONS" -n "sort" -v "$sort")"
  OPTIONS+="$(set_options -o "$OPTIONS" -n "limit" -v "$limit")"
  OPTIONS+="$(set_options -o "$OPTIONS" -n "skip" -v "$skip")"

  execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function getNotificationIntegration {
  local OPTIONS=""
  eval "$(find_args "$@")"

  OPTIONS+="$(set_options -r -m "No Notification Integration Object ID provided!" -o "$OPTIONS" -n "id" -v "$id")"

  execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function deleteNotificationIntegration {
  local OPTIONS=""
  eval "$(find_args "$@")"

  OPTIONS+="$(set_options -r -m "No Notification Integration Object ID provided!" -o "$OPTIONS" -n "id" -v "$id")"

  execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function sendNotificationIntegrationTest {
  local OPTIONS=""
  eval "$(find_args "$@")"

  OPTIONS+="$(set_options -r -m "No Notification Integration Object ID provided!" -o "$OPTIONS" -n "id" -v "$id")"

  execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function getSettingsBinary {
  local OPTIONS=""
  eval "$(find_args "$@")"

  execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function manageSettingsBinary {
  local OPTIONS=""
  eval "$(find_args "$@")"

  OPTIONS+="$(set_options -o "$OPTIONS" -n "rsync" -v "$rsync")"
  OPTIONS+="$(set_options -o "$OPTIONS" -n "psql" -v "$psql")"
  OPTIONS+="$(set_options -o "$OPTIONS" -n "pgrestore" -v "$pgrestore")"
  OPTIONS+="$(set_options -o "$OPTIONS" -n "pgdump" -v "$pgdump")"
  OPTIONS+="$(set_options -o "$OPTIONS" -n "mysql" -v "$mysql")"
  OPTIONS+="$(set_options -o "$OPTIONS" -n "mysqldump" -v "$mysqldump")"
  OPTIONS+="$(set_options -o "$OPTIONS" -n "gzip" -v "$gzip")"
  OPTIONS+="$(set_options -o "$OPTIONS" -n "gunzip" -v "$gunzip")"
  OPTIONS+="$(set_options -o "$OPTIONS" -n "mongodump" -v "$mongodump")"
  OPTIONS+="$(set_options -o "$OPTIONS" -n "mongorestore" -v "$mongorestore")"

  execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}


#
# **System**
#

function getMasterEncryptionKey {
  local OPTIONS=""
  eval "$(find_args "$@")"

  execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function factoryReset {
  local OPTIONS=""
  eval "$(find_args "$@")"

  OPTIONS+="$(set_options -o "$OPTIONS" -n "drmode" -v "$drmode")"

  execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function exitDisasterRecovery {
  local OPTIONS=""
  eval "$(find_args "$@")"

  execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function approveAgreement {
  local OPTIONS=""
  eval "$(find_args "$@")"

  execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function approveShowcase {
  local OPTIONS=""
  eval "$(find_args "$@")"

  OPTIONS+="$(set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No Showcase ID provided and is a requirement!")"

  execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function listShowcase {
  local OPTIONS=""
  eval "$(find_args "$@")"

  execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}

function GetProcessStatus {
  local OPTIONS=""
  eval "$(find_args "$@")"

  execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request"
}



#################################
# | General purpose functions | #
#################################

# **check_queue_group**
# |
# | Checks the status of a queue group:
# |   1. Backups:
# |      Checks the backup id, once found, checks the status.
# |
#

function check_queue_group {
  local MODE QUEUE_TOTAL\
        QUEUE_COUNT\
        LOADING_QUEUE\
        LOADING_BACKUP\
        LOADING_DOWNLOAD_RESTORE\
        PARTICLE_INDEX\
        LOADING\
        QUEUE_GROUP_DATA\
        FOUND_QUEUE_ITEM\
        QUEUE_GROUP_STATUS\
        QUEUE_BACKUP_ID\
        QUEUE_GROUP_LOG\
        RES

  # Set mode
  # shellcheck disable=SC2028
  # | This shellcheck is a false positive, I dont want to expand the escape sequences, I want to set the postfix.
  MODE=$(test -z "$CI_PROJECT_DIR" && echo '\r' || echo '\n')

  # Find args
  eval "$(find_args "$@")"

  test -z "$b_type" && fail 3 "Error while using ${FUNCNAME[0]} function, no queue type supplied."

  sleep 1
  QUEUE_TOTAL=$(listQueueGroups --type "$b_type" --request ".data.total")
  if [ "$QUEUE_TOTAL" -ne 0 ]; then QUEUE_COUNT=$(( QUEUE_TOTAL - 1 )); else fail 3 "No group items in queue."; fi

  # Loading
  LOADING_QUEUE=('○' '◔' '◑' '●')
  LOADING_BACKUP=('.' '⇧' '⇑' '↑')
  LOADING_DOWNLOAD_RESTORE=('⋅' '⇩' '⇓' '↓')
  readonly LOADING_DOWNLOAD_RESTORE LOADING_BACKUP LOADING_QUEUE

  PARTICLE_INDEX=0

  case $b_type in
    1) # Backup
      test -z "$b_id" && fail 3 "Error while using ${FUNCNAME[0]} function, no Backup job ID supplied."
      LOADING=" ${ANSI_BOLD}[${ANSI_BROWN}${LOADING_QUEUE[$PARTICLE_INDEX]}${ANSI_END}${ANSI_BOLD}]${ANSI_END}"
      QUEUE_GROUP_DATA="$(listQueueGroups --type 1 --request ".")"
      FOUND_QUEUE_ITEM=false

      echo -ne "$LOADING Searching queue.           $MODE"  >&2
      while [ "$QUEUE_COUNT" -ge 0 ]
      do
          LOADING=" ${ANSI_BOLD}[${ANSI_BROWN}${LOADING_QUEUE[$PARTICLE_INDEX]}${ANSI_END}${ANSI_BOLD}]${ANSI_END}"
          QUEUE_GROUP_STATUS=0
          QUEUE_BACKUP_ID="$(jbjq -d "$QUEUE_GROUP_DATA" -r ".data.groups[$QUEUE_COUNT].data._id")"
          QUEUE_GROUP_LOG="$(jbjq -d "$QUEUE_GROUP_DATA" -r ".data.groups[$QUEUE_COUNT].log_file")"
          if [ "$b_id" == "$QUEUE_BACKUP_ID" ]; then
              FOUND_QUEUE_ITEM=true
              echo -ne "$LOADING Backing up.           $MODE"  >&2
              while [ "$QUEUE_GROUP_STATUS" -ne 100 ]
              do
                  LOADING=" ${ANSI_BOLD}[${ANSI_BROWN}${LOADING_BACKUP[$PARTICLE_INDEX]}${ANSI_END}${ANSI_BOLD}]${ANSI_END}"
                  if [[ "$QUEUE_GROUP_STATUS" =~ (104|101|102) ]]; then
                    fail 2 "Backup failed, log file:\n\n$(echo -e "$("cat $QUEUE_GROUP_LOG" | sed 's#^#      \\e[0;100m\\e[1;97m#; s#$#\\e[0m\n\\e[0m#')")"
                  elif [ "$QUEUE_GROUP_STATUS" -eq 103 ]; then
                    fail 2 "Backup aborted, log file:\n\n$(echo -e "$("cat $QUEUE_GROUP_LOG" | sed 's#^#      \\e[0;100m\\e[1;97m#; s#$#\\e[0m\n\\e[0m#')")"
                  else
                    PARTICLE_INDEX=$(( (PARTICLE_INDEX + 1) % 4 ))
                    echo -ne "$LOADING$MODE" >&2
                  fi
                  QUEUE_GROUP_STATUS="$(listQueueGroups --type 1 --request ".data.groups[$QUEUE_COUNT].status")"
              done
              echo -ne "$CALL_TESTERS_DEPENDENCY_SUCCESS_PREFIX Backup finished.           \n"  >&2

              # Return request
              if [ -n "$request" ];then
                RES="$(jbjq -d "$QUEUE_GROUP_DATA" -r ".data.groups[$QUEUE_COUNT]$request")"
                echo "${RES}"
              fi
              return 0
          fi
          (( QUEUE_COUNT-- ))
          PARTICLE_INDEX=$(( (PARTICLE_INDEX + 1) % 4 ))
          echo -ne "$LOADING$MODE"  >&2
      done

      if ! $FOUND_QUEUE_ITEM; then
        echo -ne "$CALL_TESTERS_DEPENDENCY_FAIL_PREFIX Could not find matching queue item id in queue.\n"  >&2
        return 3
      fi
    ;;
    2|4) # Restore & Download
      test "$b_type" -eq 4 && TYPE_NAME="Download" || TYPE_NAME="Restore"
      test -z "$b_id" && fail 3 "Error while using ${FUNCNAME[0]} function, no Queue Group ID supplied."
      QUEUE_GROUP_LOG="$(getQueueGroup --id "$b_id" --request ".data.log_file")"
      LOADING=" ${ANSI_BOLD}[${ANSI_BROWN}${LOADING_DOWNLOAD_RESTORE[$PARTICLE_INDEX]}${ANSI_END}${ANSI_BOLD}]${ANSI_END}"
      echo -ne "$LOADING ${TYPE_NAME}-ing.           $MODE"  >&2
      QUEUE_GROUP_STATUS=0
      while [ "$QUEUE_GROUP_STATUS" -ne 100 ]
      do
          LOADING=" ${ANSI_BOLD}[${ANSI_BROWN}${LOADING_DOWNLOAD_RESTORE[$PARTICLE_INDEX]}${ANSI_END}${ANSI_BOLD}]${ANSI_END}"
          QUEUE_GROUP_STATUS="$(getQueueGroup --id "$b_id" --request ".data.status")"
          if [[ "$QUEUE_GROUP_STATUS" =~ (104|101|102) ]]; then
            fail 2 "$TYPE_NAME failed, log file:\n\n$(echo -e "$("cat $QUEUE_GROUP_LOG" | sed 's#^#      \\e[0;100m\\e[1;97m#; s#$#\\e[0m\n\\e[0m#')")"
          elif [ "$QUEUE_GROUP_STATUS" -eq 103 ]; then
            fail 2 "$TYPE_NAME aborted, log file:\n\n$(echo -e "$("cat $QUEUE_GROUP_LOG" | sed 's#^#      \\e[0;100m\\e[1;97m#; s#$#\\e[0m\n\\e[0m#')")"
          else
            PARTICLE_INDEX=$(( (PARTICLE_INDEX + 1) % 4 ))
            echo -ne "$LOADING$MODE" >&2
          fi
      done
      echo -ne "$CALL_TESTERS_DEPENDENCY_SUCCESS_PREFIX $TYPE_NAME finished.           \n"  >&2

      # Return request
      if [ -n "$request" ];then
        RES="$(jbjq -d "$QUEUE_GROUP_DATA" -r ".data.groups[$QUEUE_COUNT]$request")"
        echo "${RES}"
      fi
      return 0
    ;;
    8)
      test -z "$b_id" && fail 3 "Error while using ${FUNCNAME[0]} function, no destination ID supplied."
      LOADING=" ${ANSI_BOLD}[${ANSI_BROWN}${LOADING_QUEUE[$PARTICLE_INDEX]}${ANSI_END}${ANSI_BOLD}]${ANSI_END}"
      QUEUE_GROUP_DATA="$(listQueueGroups --type 8 --request ".")"
      FOUND_QUEUE_ITEM=false
      REINDEX_FINISHED=false
      ITERATION_COUNT=0

      echo -ne "$LOADING Searching queue.           $MODE"  >&2
      while [ "$QUEUE_COUNT" -ge 0 ]
      do
          LOADING=" ${ANSI_BOLD}[${ANSI_BROWN}${LOADING_QUEUE[$PARTICLE_INDEX]}${ANSI_END}${ANSI_BOLD}]${ANSI_END}"
          QUEUE_GROUP_STATUS=0

          QUEUE_REINDEX_ID="$(jbjq -d "$QUEUE_GROUP_DATA" -r ".data.groups[$QUEUE_COUNT].data.id")"
          QUEUE_GROUP_LOG="$(jbjq -d "$QUEUE_GROUP_DATA" -r ".data.groups[$QUEUE_COUNT].log_file")"
          if [ "$b_id" == "$QUEUE_REINDEX_ID" ]; then
              FOUND_QUEUE_ITEM=true
              echo -ne "$LOADING               Reindexing.               $MODE"  >&2

              while [ "$ITERATION_COUNT" -le "$MAX_REINDEX_TIMEOUT" ]
              do
                  LOADING=" ${ANSI_BOLD}[${ANSI_BROWN}${LOADING_QUEUE[$PARTICLE_INDEX]}${ANSI_END}${ANSI_BOLD}]${ANSI_END} (Seconds: $ITERATION_COUNT)"

                  if [[ "$QUEUE_GROUP_STATUS" =~ (104|101|102) ]]; then
                    fail 2 "Reindex failed, log file:\n\n$(echo -e "$("cat $QUEUE_GROUP_LOG" | sed 's#^#      \\e[0;100m\\e[1;97m#; s#$#\\e[0m\n\\e[0m#')")"
                  elif [ "$QUEUE_GROUP_STATUS" -eq 103 ]; then
                    fail 2 "Reindex aborted, log file:\n\n$(echo -e "$("cat $QUEUE_GROUP_LOG" | sed 's#^#      \\e[0;100m\\e[1;97m#; s#$#\\e[0m\n\\e[0m#')")"
                  elif [ "$QUEUE_GROUP_STATUS" -eq 100 ]; then
                    REINDEX_FINISHED=true
                    break
                  else
                    PARTICLE_INDEX=$(( (PARTICLE_INDEX + 1) % 4 ))
                    echo -ne "$LOADING$MODE" >&2
                  fi

                  QUEUE_GROUP_STATUS="$(listQueueGroups --type 8 --request ".data.groups[$QUEUE_COUNT].status")"
                  (( ITERATION_COUNT++ ))
                  sleep 1
              done

              if $REINDEX_FINISHED; then
                echo -ne "$CALL_TESTERS_DEPENDENCY_SUCCESS_PREFIX Reindex finished.           \n"  >&2
              else
                echo -ne "$CALL_TESTERS_DEPENDENCY_FAIL_PREFIX Max reindex timout reached. ($MAX_REINDEX_TIMEOUT)           \n"  >&2
                return 2
              fi

              # Return request
              if [ -n "$request" ];then
                RES="$(jbjq -d "$QUEUE_GROUP_DATA" -r ".data.groups[$QUEUE_COUNT]$request")"
                echo "${RES}"
              fi
              return 0
          fi
          (( QUEUE_COUNT-- ))
          PARTICLE_INDEX=$(( (PARTICLE_INDEX + 1) % 4 ))
          echo -ne "$LOADING$MODE"  >&2
      done

      if ! $FOUND_QUEUE_ITEM; then
        echo -ne "$CALL_TESTERS_DEPENDENCY_FAIL_PREFIX Could not find matching queue item id in queue.\n"  >&2
        return 3
      fi

      sleep "${POST_REINDEX_DELAY:-2}"
    ;;
  esac
}