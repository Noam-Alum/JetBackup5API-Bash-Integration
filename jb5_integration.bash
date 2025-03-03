#!/bin/bash
#
# **Bash library for jetbackup5api**
#
# | Author: Noam Alum
# | Description: JetBackup5API-Bash-Library is a Bash library that provides full access to the JetBackup 5 API.
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
#



##########################
# | Internal variables | #
##########################

export JETBACKUP_KEYS JETBACKUP_CUSTOM_KEYS JETBACKUP_API EXECUTE_FUNCTION_DELAY MAX_REINDEX_TIMEOUT POST_REINDEX_DELAY ERROR_PREFIX

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
  "message" "success" "request" "requirement" "c_type" "c_username" "c_id" "file" "data"
)

if ! which jq &> /dev/null; then echo -e "[jb5_integration]: jq not found, please install and try again." >&2; exit 3;fi
if ! JETBACKUP_API_PATH="$(which jetbackup5api 2> /dev/null)"; then echo -e "[jb5_integration]: jetbackup5api not found, is JetBackup5 installed?" >&2; exit 3; fi
JETBACKUP_API="$JETBACKUP_API_PATH -O json"

## General
EXECUTE_FUNCTION_DELAY="0.3"

## Reindex settings
MAX_REINDEX_TIMEOUT="60"
POST_REINDEX_DELAY="2"



##########################
# | Internal functions | #
##########################

# **jb5api::jbjq**
# | Wraps jq so when it exists it would be handled by the script
#

function jb5api::jbjq {
  local IS_EVAL DATA REQUEST JQ_RESPONSE
  IS_EVAL=false
  ERROR_PREFIX="[${FUNCNAME[0]}]: Error while using ${FUNCNAME[0]} function,"

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
        echo -e "${ERROR_PREFIX} option -${OPTARG} requires an argument." >&2
        return 3
        ;;
      ?)
        echo -e "${ERROR_PREFIX} invalid option: -${OPTARG}." >&2
        return 3
        ;;
    esac
  done

  if [ -z "$REQUEST" ]; then echo -e "${ERROR_PREFIX} No request provided! (-r)" >&2;return 3;fi
  if [ -z "$DATA" ]; then echo -e "${ERROR_PREFIX} No data provided! (-d)" >&2;return 3;fi

  if ! JQ_RESPONSE="$(jq -r "$REQUEST" <<< "$DATA" 2>&1)"; then
    echo -e "${ERROR_PREFIX} jq failed, error:\n$JQ_RESPONSE\n" >&2
    return 3
  elif [ "$JQ_RESPONSE" == "null" ]; then
    echo -e "${ERROR_PREFIX} jq failed fetching \"$REQUEST\" from:\n\n$DATA\n" >&2
    return 3
  else
    if $IS_EVAL; then
      eval echo "$JQ_RESPONSE"
    else
      echo "$JQ_RESPONSE"
    fi
  fi
}

# **jb5api::array_contains**
# | Check if array contains an item
#

function jb5api::array_contains {
  local ITEM ARRAY_ITEMS
  ITEM="$1"
  shift 1
  ARRAY_ITEMS=("$@")

  for ARRAY_ITEM in "${ARRAY_ITEMS[@]}"
  do
    [[ "$ARRAY_ITEM" = "$ITEM" ]] && return 0
  done

  # Could not find item in array
  return 3
}

# **jb5api::gen_random**
# | Generate random data. (Function was taken from utils.sh, refer: https://docs.alum.sh/utils.sh/Introduction.html)
# | Documentation: https://docs.alum.sh/utils.sh/functions/jb5api::gen_random.html
#

function jb5api::gen_random {
  local GR_OPT GR_LEN CHARSET RES
  ERROR_PREFIX="[${FUNCNAME[0]}]: Error while using ${FUNCNAME[0]} function,"

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
      echo -e "${ERROR_PREFIX} Error while using \"${FUNCNAME[0]}\" function, not a valid option ($GR_OPT), refer to \"https://docs.alum.sh/utils.sh/functions/gen_random.html\" for more information." >&2
      return 3
      ;;
  esac
  readonly CHARSET

  if [ -z "${GR_LEN//[0-9]}" ]; then
    RES="$(tr -dc "$CHARSET" < /dev/urandom | head -c "$GR_LEN")"
  else
    echo -e "${ERROR_PREFIX} Error while using \"${FUNCNAME[0]}\" function, length not an int ($GR_LEN), refer to \"https://docs.alum.sh/utils.sh/functions/jb5api::gen_random.html\" for more information." >&2
    return 3
  fi

  if [ -n "$RES" ]; then
	  echo "$RES"
	  return 0
  else
    echo -e "${ERROR_PREFIX} Unknown error while using \"${FUNCNAME[0]}\" function, refer to \"https://docs.alum.sh/utils.sh/functions/jb5api::gen_random.html\" for more information." >&2
    return 3
  fi
}

# **jb5api::execute_function**
# | Executes JetBackup5 API calls and returns data based on json path/s.
#

function jb5api::execute_function {
  local FUNCTION_NAME FUNC_OPT FUNC_REQ FUNC_RES FUNC_SUC FUNC_MSG RES_MSG RES JB5_LOG_RESPONSE

  FUNCTION_NAME="${1/jb5api::/}"
  FUNC_OPT="$2"
  shift 2
  FUNC_REQ=()
  while IFS=',' read -r line; do FUNC_REQ+=("$line"); done <<< "$*"

	# Wait function execution delay
	sleep "${EXECUTE_FUNCTION_DELAY:-0.5}"

	FUNC_RES="$(jb5api::jbjq -r "." -d "$($JETBACKUP_API -F "$FUNCTION_NAME" -D "$FUNC_OPT")")"
	FUNC_SUC="$(jb5api::jbjq -r ".success" -d "$FUNC_RES")"
	FUNC_MSG="$(jb5api::jbjq -r ".message" -d "$FUNC_RES")"

	if [ "$FUNC_SUC" == "1" ]; then
		if [ ${#FUNC_REQ[@]} -ne 0 ] && [ -n "${FUNC_REQ[*]}" ]; then
      for R in "${FUNC_REQ[@]}"
      do
			  RES="$(jb5api::jbjq -r "$R" -d "$FUNC_RES")"
			  echo "$RES"
      done
    else
      echo "$FUNC_RES"
    fi
	else
		echo -e "Error while executing ${FUNCNAME[1]}:\n\nMessage: $FUNC_MSG\n\nWrapper EXEC:\n$JETBACKUP_API '$FUNCTION_NAME' -D '$FUNC_OPT'\n\nResponse:\n$FUNC_RES\n" >&2
		return 2
	fi
}

# **jb5api::find_args**
# | Assigns command-line argument values to variables based on JETBACKUP_CUSTOM_KEYS and JETBACKUP_KEYS.
#

function jb5api::find_args {
  local find_args_TTL KEY VALUE ITEM_DATA ITEM_VALUE ITEM_INDEX ITEM_NAME

  find_args_TTL=${#JETBACKUP_KEYS[@]}
  while [[ $# -gt 0 ]] && [[ $find_args_TTL -gt 0 ]]; do
      KEY="$1"
      VALUE="$2"
      KEY="${KEY//--/}"
      if jb5api::array_contains "${KEY}" "${JETBACKUP_CUSTOM_KEYS[@]}"; then
        echo "local $KEY=\"$VALUE\""
      elif jb5api::array_contains "${KEY}" "${JETBACKUP_KEYS[@]}"; then
        ITEM_DATA=()
        IFS=',' read -r -a ITEM_DATA <<< "$VALUE"
        case ${#ITEM_DATA[@]} in
          3) # Two dimensional arrays
            ITEM_VALUE="${ITEM_DATA[2]}"
            ITEM_INDEX="[${ITEM_DATA[1]}]"
            ITEM_NAME="${ITEM_DATA[0]}"
            if [ -z "${!KEY}" ]; then
              # shellcheck disable=SC1087
              # | Not expanding an array, this looks like Im expanding an array, Im actually constructing the DATA sent to JetBackupAPI.
              local "$KEY"="$KEY[$ITEM_NAME]$ITEM_INDEX=$ITEM_VALUE"
            else
              # shellcheck disable=SC1087
              # | Not expanding an array, this looks like Im expanding an array, Im actually constructing the DATA sent to JetBackupAPI.
              local "$KEY"="${!KEY}&$KEY[$ITEM_NAME]$ITEM_INDEX=$ITEM_VALUE"
            fi
            VALUE="${!KEY}"
            ;;
          2) # Arrays
            ITEM_VALUE="${ITEM_DATA[1]}"
            ITEM_NAME="${ITEM_DATA[0]}"
            if [ -z "${!KEY}" ]; then
              # shellcheck disable=SC1087
              # | Not expanding an array, this looks like Im expanding an array, Im actually constructing the DATA sent to JetBackupAPI.
              local "$KEY"="$KEY[$ITEM_NAME]$ITEM_INDEX=$ITEM_VALUE"
            else
              # shellcheck disable=SC1087
              # | Not expanding an array, this looks like Im expanding an array, Im actually constructing the DATA sent to JetBackupAPI.
              local "$KEY"="${!KEY}&${KEY}[$ITEM_NAME]$ITEM_INDEX=$ITEM_VALUE"
            fi
            VALUE="${!KEY}"
            ;;
          1|0)
            if [ "$KEY" == "id" ]; then
              VALUE="_id=$VALUE"
            else
              VALUE="$KEY=$VALUE"
            fi
            ;;
          *) # Too many arguments
            echo -e "[${FUNCNAME[1]}]: Too many arguments: ${ITEM_DATA[*]}" >&2
            return 3
            ;;
        esac
        echo "local $KEY=\"$VALUE\""
        unset ITEM_INDEX
      else
        echo -e "[${FUNCNAME[1]}]: Invalid key: $KEY." >&2
        return 3
      fi
      shift 2
      (( find_args_TTL-- ))
  done

  if [ "$find_args_TTL" -le 0 ]; then
        echo -e "[${FUNCNAME[1]} -> ${FUNCNAME[0]}]: Unknown issue, have you forgotten something? (\"${FUNCNAME[1]} $*\")" >&2
        return 3
  fi
}

# **jb5api::set_options**
# | Appends options value for JB5 API calls.
#

function jb5api::set_options {
  local REQUIRED OPT_NAME VAR_VALUE DEFAULT_VALUE CURRENT_OPTIONS FAILED_MSG
  ERROR_PREFIX="[${FUNCNAME[0]}]: Error while using ${FUNCNAME[0]} function,"

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
        echo -e "${ERROR_PREFIX} option -${OPTARG} requires an argument." >&2
        return 3
        ;;
      ?)
        echo -e "${ERROR_PREFIX} invalid option: -${OPTARG}." >&2
        return 3
        ;;
    esac
  done

  if [ -z "$VAR_VALUE" ] && [ -n "$DEFAULT_VALUE" ]; then
    VAR_VALUE="$OPT_NAME=$DEFAULT_VALUE"
  fi

  if [ -z "$OPT_NAME" ]; then
    echo -e "${ERROR_PREFIX} no variable name supplied. (-o)" >&2
    return 3
  else
    if $REQUIRED; then
      if [ -z "$VAR_VALUE" ]; then
        echo -e "[${FUNCNAME[1]}]: $FAILED_MSG" >&2
        return 3
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
# | Reference: https://docs.jetbackup.com/v5.3/api/AccountFilters/accountfilters.html
#

function jb5api::manageAccountFilter {
	local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


	OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "action" -v "$action" -m "No action provided and is a requirement!")" || return 3

	if [ "$action" == "action=modify" ]; then
		OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No Account Filter ID provided and is a requirement!")" || return 3
		OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "type" -v "$type")" || return 3
		OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "name" -v "$name")" || return 3
    OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "condition" -v "$condition")" || return 3
    OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "list" -v "$list")" || return 3
    OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "owner" -v "$owner")" || return 3
    OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "range_start" -v "$range_start")" || return 3
    OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "range_end" -v "$range_end")" || return 3
    OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "regex" -v "$regex")" || return 3
    OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "usage" -v "$usage")" || return 3
	else
		OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "type" -v "$type")" || return 3
		OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "name" -v "$name")" || return 3
    OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "condition" -v "$condition")" || return 3
    OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "owner" -v "$owner")" || return 3
    case $type in
      type=2|type=4|type=64|type=512)
        OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "list" -v "$list" -m "No list provided!")" || return 3
        ;;
      type=16|type=32)
        OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "usage" -v "$usage" -m "No usage provided!")" || return 3
        ;;
      type=128)
        OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "range_start" -v "$range_start" -m "No range_start provided!")" || return 3
        OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "range_end" -v "$range_end" -m "No range_end provided!")" || return 3
        ;;
      type=256)
        OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "regex" -v "$regex" -m "No regex provided!")" || return 3
        ;;
    esac
  fi

	jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::listAccountFilters {
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


	jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::getAccountFilter {
	local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


	OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No Account Filter ID provided and is a requirement!")" || return 3

	jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::deleteAccountFilter {
	local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


	OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No Account Filter ID provided and is a requirement!")" || return 3

	jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::listAccountFilterGroups {
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


	jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::getAccountFilterGroup {
	local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


	OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No filter group id provided and is a requirement!")" || return 3

	jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}


#
# | **Accounts**
# | Reference: https://docs.jetbackup.com/v5.3/api/Accounts/accounts.html
#

function jb5api::manageAccount {
	local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


	OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No account ID provided and is a requirement!")" || return 3
  OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "email" -v "$email" -d "test@gmail.com")" || return 3
	OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "backup_quota" -v "$backup_quota")" || return 3
	OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "max_snapshots" -v "$max_snapshots" -d "5")" || return 3
	OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "queue_priority" -v "$queue_priority")" || return 3
	OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "tags" -v "$tags")" || return 3

	jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::manageMyAccount {
	local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


  OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "encryption_key_type" -v "$encryption_key_type")" || return 3
  if [ "$encryption_key_type" == "encryption_key_type=1" ]; then
    OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "encryption_key" -v "$encryption_key" -m "No encryption_key provided and is a requirement when using encryption_key_type!")" || return 3
  fi
  OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "email" -v "$email" -d "test@gmail.com")" || return 3
	OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "backup_type" -v "$backup_type")" || return 3
	OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "privacy" -v "$privacy")" || return 3
	OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "terms" -v "$terms")" || return 3

	jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::getAccount {
	local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


	OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No account ID provided and is a requirement!")" || return 3

	jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::listAccounts {
	local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


	OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "orphan" -v "$orphan" -d "0")" || return 3
	OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "find" -v "$find")" || return 3

	jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::listTags {
  local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


  jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::getMyAccount {
  local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


  jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::listAccountEmails {
  local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


  OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "account" -v "$account" -m "No account name provided and is a requirement!")" || return 3
  OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "find" -v "$find")" || return 3
  OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "sort" -v "$sort")" || return 3
  OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "limit" -v "$limit")" || return 3
  OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "skip" -v "$skip")" || return 3

  jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::reassignAccount {
	local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


	OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No account ID provided and is a requirement!")" || return 3

	jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::listAssignableAccounts {
	local JB5_API_FIND_ARGS OPTIONS=""
   JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


	OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "account" -v "$account" -m "No account Username provided and is a requirement!")" || return 3

	jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::createBackupOnDemand {
	local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


	OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "account_id" -v "$account_id" -m "No account_id provided and is a requirement!")" || return 3

	jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::manageAccountExcludeList {
	local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


	OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No _id provided and is a requirement!")" || return 3
	OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "excludes" -v "$excludes" -m "No excludes provided and is a requirement!")" || return 3

	jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::getAccountExcludeList {
	local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


	OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No Account ID provided and is a requirement!")" || return 3

	jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::listAccountPackages {
	local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


	OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "type" -v "$type")" || return 3
	OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "all" -v "$all")" || return 3

	jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::deleteAccountSnapshots {
	local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


	OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "approve" -v "$approve")" || return 3
	OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "user" -v "$user" -m "No user id provided and is a requirement!")" || return 3
	OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "range_start" -v "$range_start")" || return 3
	OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "range_end" -v "$range_end")" || return 3
	OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "job" -v "$job")" || return 3
	OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "destination" -v "$destination")" || return 3

	jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::manageTag {
	local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


	OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "action" -v "$action" -m "No action provided and is a requirement!")" || return 3

	if [ "$action" == "action=modify" ]; then
	  OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No tag id provided and is a requirement!")" || return 3
  else
    OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "name" -v "$name" -m "No tag id provided and is a requirement!")" || return 3
	fi

	OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "color" -v "$color" -d "#57c785")" || return 3
	OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "type" -v "$type" -d "1")" || return 3

	jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::getTag {
	local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


  OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No tag id provided and is a requirement!")" || return 3

	jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::deleteTag {
	local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


  OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No tag id provided and is a requirement!")" || return 3

	jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}


#
# | **Alerts**
# | Reference: https://docs.jetbackup.com/v5.3/api/Alerts/alerts.html
#

function jb5api::listAlerts {
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


	jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::getAlert {
	local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


	OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No Alert ID provided and is a requirement!")" || return 3

	jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::clearAlerts {
    JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


	jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}


#
# | **Backup jobs**
# | Reference: https://docs.jetbackup.com/v5.3/api/BackupJobs/backupjobs.html
#

function jb5api::manageBackupJob {
	local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


	OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "action" -v "$action" -m "No action provided and is a requirement!")" || return 3

	if [ "$action" == "action=modify" ]; then
		OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No backup job id provided and is a requirement!")" || return 3
		OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "type" -v "$type")" || return 3
		OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "name" -v "$name")" || return 3
		OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "destination" -v "$destination")" || return 3
		if [ "$type" == "type=1" ];then OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "contains" -v "$contains" -d "511")" || return 3;fi
		OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "structure" -v "$structure")" || return 3
	else
		OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "type" -v "$type" -m "No job type provided and is a requirement!")" || return 3
		OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "name" -v "$name" -d "$(jb5api::gen_random str 12)")" || return 3
		OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "destination" -v "$destination" -m "No destination id provided and is a requirement!")" || return 3
		OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "contains" -v "$contains" -m "No backup contains provided FULL is 511 for Accounts and 3 for Directories.")" || return 3
		if [ "$type" == "type=1" ];then OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "include_list" -v "$include_list" -d "0,/home")" || return 3;fi
		OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "structure" -v "$structure" -d "1")" || return 3
	fi

	OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "options" -v "$options")" || return 3
	OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "retry_failed" -v "$retry_failed")" || return 3
	if [ "$type" == "type=1" ];then OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "include_list" -v "$include_list")" || return 3;fi
	OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "exclude_list" -v "$exclude_list")" || return 3
	OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "filters" -v "$filters")" || return 3
	OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "schedules" -v "$schedules")" || return 3
	OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "time" -v "$time")" || return 3
	OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "monitor" -v "$monitor")" || return 3
	OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "owner" -v "$owner")" || return 3
	OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "disabled" -v "$disabled")" || return 3

	jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::getBackupJob {
	local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


	OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No backup job id provided and is a requirement!")" || return 3

	jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::listBackupJobs {
  local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


	jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::duplicateBackupJob {
	local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


	OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No backup job _id provided and is a requirement!")" || return 3

	jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::runBackupJobManually {
	local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


	OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No backup job _id provided and is a requirement!")" || return 3

	jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::deleteBackupJob {
	local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


	OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No backup job _id provided and is a requirement!")" || return 3

	jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}


#
# | **Backups**
# | Reference: https://docs.jetbackup.com/v5.3/api/Backups/backups.html
#

function jb5api::listBackups {
	local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


	OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "type" -v "$type" -m "No type provided and is a requirement!")" || return 3
	OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "contains" -v "$contains" -d "511")" || return 3
	OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "account_id" -v "$account_id" -m "No account_id provided and is a requirement!")" || return 3

	jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::listBackupForAccounts {
	local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


	OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "type" -v "$type" -m "No type provided and is a requirement!")" || return 3
	OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "contains" -v "$contains" -d "511")" || return 3

	jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::listBackupForType {
	local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


	OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "type" -v "$type" -m "No type provided and is a requirement!")" || return 3
	OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "contains" -v "$contains" -d "511")" || return 3
	OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "account_id" -v "$account_id" -m "No account_id provided and is a requirement!")" || return 3

	jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::listBackupForTypeName {
	local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


	OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "type" -v "$type" -m "No type provided and is a requirement!")" || return 3
	OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "contains" -v "$contains" -d "511")" || return 3
	OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "account_id" -v "$account_id" -m "No account_id provided and is a requirement!")" || return 3
	OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "name" -v "$name" -m "No name provided and is a requirement!")" || return 3

	jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::listAccountsByFilters {
	local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


	OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "filters" -v "$filters" -m "No filters provided and is a requirement!")" || return 3

	jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::getBackupItems {
	local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


	OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No backup parent_id provided and is a requirement!")" || return 3

	jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::getBackupItem {
	local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


	OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No backup item id provided and is a requirement!")" || return 3

	jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::manageBackupLock {
	local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


	OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No backup parent_id provided and is a requirement!")" || return 3
	OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "locked" -v "$locked" -d"")" || return 3
	OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "lock_ttl" -v "$lock_ttl" -d"")" || return 3

	jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::deleteSnapshot {
	local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


  OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No snapshot id provided and is a requirement!")" || return 3

	jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}


#
# | **Clone jobs**
# | Reference: https://docs.jetbackup.com/v5.3/api/CloneJobs/clonejobs.html
#

function jb5api::manageCloneJob {
	local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


	OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "action" -v "$action" -m "No action provided and is a requirement!")" || return 3

	if [ "$action" == "action=modify" ]; then
		OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No clone job _id provided and is a requirement!")" || return 3
		OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "type" -v "$type")" || return 3
		OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "name" -v "$name")" || return 3
		OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "destination" -v "$destination")" || return 3
		OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "contains" -v "$contains")" || return 3
	else
		OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "type" -v "$type" -m "No job type provided and is a requirement!")" || return 3
		OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "name" -v "$name" -d "$(jb5api::gen_random str 12)")" || return 3
		OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "destination" -v "$destination" -m "No destination _id provided and is a requirement!")" || return 3
		OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "contains" -v "$contains" -d "511")" || return 3
	fi

	OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "default_owner" -v "$default_owner")" || return 3
	OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "default_package" -v "$default_package")" || return 3
	OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "Owner" -v "$Owner")" || return 3
	OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "monitor" -v "$monitor")" || return 3
	OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "Disabled" -v "$Disabled")" || return 3

	jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::getCloneJob {
	local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


	OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No clone job _id provided and is a requirement!")" || return 3

	jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::listCloneJobs {
  local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


	jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::duplicateCloneJob {
	local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


	OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No clone job _id provided and is a requirement!")" || return 3

	jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::runCloneJobManually {
	local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


	OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No clone job _id provided and is a requirement!")" || return 3

	jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::deleteCloneJob {
	local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


	OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No clone job _id provided and is a requirement!")" || return 3

	jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}


#
# | **Dashboard**
# | Reference: https://docs.jetbackup.com/v5.3/api/Dashboard/dashboard.html
#

function jb5api::getDashboardDetails {
    local JB5_API_FIND_ARGS OPTIONS=""
    JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


    jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::getStatistics {
    local JB5_API_FIND_ARGS OPTIONS=""
    JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


    jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::getInfo {
    local JB5_API_FIND_ARGS OPTIONS=""
    JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


    jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::listShowcase {
    local JB5_API_FIND_ARGS OPTIONS=""
    JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


    jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}


#
# | **Destinations**
# | Reference: https://docs.jetbackup.com/v5.3/api/Destinations/destinations.html
#

function jb5api::manageDestination {
	local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


	OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "action" -v "$action" -m "No action provided and is a requirement!")" || return 3

	if [ "$action" == "action=modify" ]; then
		OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No destination id provided and is a requirement!")" || return 3
		OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "type" -v "$type")" || return 3
		OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "options" -v "$options")" || return 3
		OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "name" -v "$name")" || return 3
	else
		OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "type" -v "$type" -m "No destination type provided and is a requirement!")" || return 3
		OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "options" -v "$options" -m "No options provided and is a requirement!")" || return 3
		OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "name" -v "$name" -d "$(jb5api::gen_random str 12)")" || return 3
	fi

	OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "owner" -v "$owner")" || return 3
	OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "disabled" -v "$disabled")" || return 3
	OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "readonly" -v "$readonly")" || return 3
	OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "dr" -v "$dr")" || return 3
	OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "disk_limit" -v "$disk_limit")" || return 3
	OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "hidden" -v "$hidden")" || return 3

	jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::getDestination {
	local JB5_API_FIND_ARGS OPTIONS=""
    JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


	OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No destination id provided and is a requirement!")" || return 3

	jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::listDestinations {
    JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


	jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::listDestinationTypes {
	JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


	jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::validateDestination {
	local JB5_API_FIND_ARGS OPTIONS=""
    JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


	OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No destination id provided and is a requirement!")" || return 3

	jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::deleteDestination {
	local JB5_API_FIND_ARGS OPTIONS=""
    JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


	OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No destination id provided and is a requirement!")" || return 3

	jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::reindexDestination {
	local JB5_API_FIND_ARGS OPTIONS=""
    JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


	OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No destination id provided and is a requirement!")" || return 3
	OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "account_id" -v "$account_id")" || return 3
	OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "account_username" -v "$account_username")" || return 3
	OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "by_snap" -v "$by_snap")" || return 3

	jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}


#
# | **Downloads**
# | Reference: https://docs.jetbackup.com/v5.3/api/Downloads/downloads.html
#

function jb5api::getDownload {
	local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


	OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No Download Object ID provided and is a requirement!")" || return 3

	jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::listDownloads {
	local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


	jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::manageDownloadNotes {
	local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


	OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No Download Object ID provided and is a requirement!")" || return 3
	OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "notes" -v "$notes")" || return 3

	jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}


#
# | **FilePermissions**
# | Reference: https://docs.jetbackup.com/v5.3/api/FilePermissions/filepermissions.html
#

function jb5api::manageFilePermissions {
  local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


  OPTIONS+="$(jb5api::set_options -r -m "No action provided and is a requirement!" -o "$OPTIONS" -n "action" -v "$action")" || return 3

  if [ "$action" == "action=modify" ]; then
    OPTIONS+="$(jb5api::set_options -r -m "No File permissions ID provided and is a requirement!" -o "$OPTIONS" -n "id" -v "$id")" || return 3
    OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "regex" -v "$regex")" || return 3
    OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "category" -v "$category")" || return 3
  else
    OPTIONS+="$(jb5api::set_options -r -m "No regex for the File/Folder name and is a requirement!" -o "$OPTIONS" -n "regex" -v "$regex")" || return 3
    OPTIONS+="$(jb5api::set_options -r -m "No category provided and is a requirement!" -o "$OPTIONS" -n "category" -v "$category")" || return 3
  fi

  OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "owner" -v "$owner")" || return 3
  OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "group" -v "$group")" || return 3
  OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "recursive" -v "$recursive")" || return 3
  OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "dirs_permissions" -v "$dirs_permissions")" || return 3
  OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "files_permissions" -v "$files_permissions")" || return 3

  jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::getFilePermissions {
  local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


  OPTIONS+="$(jb5api::set_options -r -m "No File permissions ID provided and is a requirement!" -o "$OPTIONS" -n "id" -v "$id")" || return 3

  jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::listFilePermissions {
  local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


  OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "find" -v "$find")" || return 3
  OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "sort" -v "$sort")" || return 3
  OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "limit" -v "$limit")" || return 3
  OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "skip" -v "$skip")" || return 3

  jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::deleteFilePermissions {
  local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


  OPTIONS+="$(jb5api::set_options -r -m "No File permissions ID provided and is a requirement!" -o "$OPTIONS" -n "id" -v "$id")" || return 3

  jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}


#
# | **Hooks**
# | Reference: https://docs.jetbackup.com/v5.3/api/Hooks/hooks.html
#

function jb5api::manageHook {
    local JB5_API_FIND_ARGS OPTIONS=""
    JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


    OPTIONS+="$(jb5api::set_options -r -m "No Action provided!" -o "$OPTIONS" -n "action" -v "$action")" || return 3

    if [ "$action" == "action=modify" ]; then
      OPTIONS+="$(jb5api::set_options -r -m "No id provided!" -o "$OPTIONS" -n "id" -v "$id")" || return 3
      OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "name" -v "$name")" || return 3
      OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "position" -v "$position")" || return 3
      OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "position_type" -v "$position_type")" || return 3
      OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "script" -v "$script")" || return 3
    else
      OPTIONS+="$(jb5api::set_options -r -d "$(jb5api::gen_random str 16)" -o "$OPTIONS" -n "name" -v "$name")" || return 3
      OPTIONS+="$(jb5api::set_options -r -m "No position provided!" -o "$OPTIONS" -n "position" -v "$position")" || return 3
      OPTIONS+="$(jb5api::set_options -r -m "No position type provided!" -o "$OPTIONS" -n "position_type" -v "$position_type")" || return 3
      OPTIONS+="$(jb5api::set_options -r -m "No script provided!" -o "$OPTIONS" -n "script" -v "$script")" || return 3
    fi
    OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "data_list" -v "$data_list")" || return 3
    OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "disabled" -v "$disabled")" || return 3

    jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::listHooks {
    local JB5_API_FIND_ARGS OPTIONS=""
    JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


    OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "find" -v "$find")" || return 3
    OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "sort" -v "$sort")" || return 3
    OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "limit" -v "$limit")" || return 3
    OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "skip" -v "$skip")" || return 3

    jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::getHook {
    local JB5_API_FIND_ARGS OPTIONS=""
    JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


    OPTIONS+="$(jb5api::set_options -r -m "No id provided!" -o "$OPTIONS" -n "id" -v "$id")" || return 3

    jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::deleteHook {
    local JB5_API_FIND_ARGS OPTIONS=""
    JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


    OPTIONS+="$(jb5api::set_options -r -m "No id provided!" -o "$OPTIONS" -n "id" -v "$id")" || return 3

    jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}


#
# **Logs**
# | Reference: https://docs.jetbackup.com/v5.3/api/Logs/logs.html
#

function jb5api::listLogs {
	local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


	jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::getLog {
	local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


  OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No Log ID provided and is a requirement!")" || return 3

	jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::deleteLog {
	local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


	OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No Log ID provided and is a requirement!")" || return 3

	jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::listLogItems {
	local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


  OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "log_id" -v "$log_id" -m "No Log ID provided and is a requirement!")" || return 3

	jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::getLogItem {
	local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


  OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "_id" -v "$id" -m "No Log Item ID provided and is a requirement!")" || return 3
  OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "log_id" -v "$log_id" -m "No Log ID provided and is a requirement!")" || return 3

	jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}


#
# **PanelAPI**
# | Reference: https://docs.jetbackup.com/v5.3/api/PanelAPI/panelapi.html
#

function jb5api::Panel_ListTokens {
  local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


  OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "find" -v "$find")" || return 3
  OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "sort" -v "$sort")" || return 3
  OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "limit" -v "$limit")" || return 3
  OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "skip" -v "$skip")" || return 3

  jb5api::execute_function "${FUNCNAME//_//}" "$OPTIONS" "$request"
}

function jb5api::Panel_GetToken {
  local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


  OPTIONS+="$(jb5api::set_options -r -m "No Token ID provided and is required for the getToken call!" -o "$OPTIONS" -n "id" -v "$id")" || return 3

  jb5api::execute_function "${FUNCNAME//_//}" "$OPTIONS" "$request"
}

function jb5api::Panel_ManageToken {
  local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


  OPTIONS+="$(jb5api::set_options -r -m "No action provided and is required for the manageToken call!" -o "$OPTIONS" -n "action" -v "$action")" || return 3
  if [ "$action" == "action=modify" ]; then
    OPTIONS+="$(jb5api::set_options -r -m "No Token ID provided and is required for the manageToken call!" -o "$OPTIONS" -n "id" -v "$id")" || return 3
    OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "description" -v "$description")" || return 3
  else
    OPTIONS+="$(jb5api::set_options -r -d "$(jb5api::gen_random str 16)" -o "$OPTIONS" -n "description" -v "$description")" || return 3
  fi

  OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "ip" -v "$ip")" || return 3
  OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "username" -v "$username")" || return 3
  OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "expiry" -v "$expiry")" || return 3

  jb5api::execute_function "${FUNCNAME//_//}" "$OPTIONS" "$request"
}

function jb5api::Panel_DeleteToken {
  local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


  OPTIONS+="$(jb5api::set_options -r -m "No Token ID provided and is required for the deleteToken call!" -o "$OPTIONS" -n "id" -v "$id")" || return 3

  jb5api::execute_function "${FUNCNAME//_//}" "$OPTIONS" "$request"
}

function jb5api::Panel_CreateUserSession {
  local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


  OPTIONS+="$(jb5api::set_options -r -m "No username to generate a login URL for provided and is required for the createUserSession call!" -o "$OPTIONS" -n "user" -v "$user")" || return 3

  jb5api::execute_function "${FUNCNAME//_//}" "$OPTIONS" "$request"
}

function jb5api::Panel_CreateAccount {
  local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


  OPTIONS+="$(jb5api::set_options -r -m "No account name and is required for the CreateAccount call!" -o "$OPTIONS" -n "account" -v "$account")" || return 3

  jb5api::execute_function "${FUNCNAME//_//}" "$OPTIONS" "$request"
}


#
# | **Permissions**
# | Reference: https://docs.jetbackup.com/v5.3/api/Permissions/permissions.html
#

function jb5api::managePermissions {
    local JB5_API_FIND_ARGS OPTIONS=""
    JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


    OPTIONS+="$(jb5api::set_options -r -m "Username is required!" -o "$OPTIONS" -n "username" -v "$username")" || return 3
    OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "permissions" -v "$permissions")" || return 3

    jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::getPermissions {
    local JB5_API_FIND_ARGS OPTIONS=""
    JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


    OPTIONS+="$(jb5api::set_options -r -m "Username is required!" -o "$OPTIONS" -n "username" -v "$username")" || return 3

    jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::resetPermissions {
    local JB5_API_FIND_ARGS OPTIONS=""
    JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


    OPTIONS+="$(jb5api::set_options -r -m "Username is required!" -o "$OPTIONS" -n "username" -v "$username")" || return 3

    jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::listPermissions {
    local JB5_API_FIND_ARGS OPTIONS=""
    JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


    jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}


#
# | **Plugins**
# | Reference: https://docs.jetbackup.com/v5.3/api/Plugins/plugins.html
#

function jb5api::listPlugins {
	local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


	OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "filter" -v "$filter")" || return 3

	jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::listPackages {
	local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


	OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "filter" -v "$filter")" || return 3
	OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "find" -v "$find")" || return 3

	jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::listRepositories {
	local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


	OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "filter" -v "$filter")" || return 3

	jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::manageRepository {
	local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


  OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "action" -v "$action" -m "No action provided and is a requirement!")" || return 3

  if [ "$action" == "action=modify" ]; then
	  OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No Repository ID provided and is a requirement!")" || return 3
	fi

	OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "url" -v "$url")" || return 3
	OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "name" -v "$name")" || return 3

	jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::deleteRepository {
	local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


	OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No Repository ID provided and is a requirement!")" || return 3

	jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::getPlugin {
	local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


	OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No Repository ID provided and is a requirement!")" || return 3

	jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::managePlugin {
	local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


	OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No Repository ID provided and is a requirement!")" || return 3
	OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "disabled" -v "$disabled")" || return 3
	OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "repo" -v "$repo")" || return 3
	OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "visible" -v "$visible")" || return 3
	OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "permissions" -v "$permissions")" || return 3

	jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::installPlugin {
	local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


	OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "package_id" -v "$package_id" -m "No Plugin ID provided and is a requirement!")" || return 3
	OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "package_name" -v "$package_name")" || return 3
	OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "disabled" -v "$disabled")" || return 3

	jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::uninstallPlugin {
	local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


	OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No Plugin ID provided and is a requirement!")" || return 3

	jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::updatePlugin {
	local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


	OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No Plugin ID provided and is a requirement!")" || return 3

	jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::listAvailablePlugins {
	local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


	OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "filter" -v "$filter")" || return 3

	jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::manageSecurityPlugin {
	local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


	OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "plugin" -v "$plugin" -m "No Security Plugin ID provided and is a requirement!")" || return 3
	OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "lock" -v "$lock")" || return 3
	OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "restore" -v "$restore")" || return 3

	jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}


#
# | **Queues**
# | Reference: https://docs.jetbackup.com/v5.3/api/Queues/queues.html
#

function jb5api::addQueueItems {
	local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


	OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "type" -v "$type" -m "No type provided and is a requirement!")" || return 3
	OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "snapshot_id" -v "$snapshot_id")" || return 3

	if [ -z "$snapshot_id" ]; then
    OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "items" -v "$items" -m "REQUIRED When not using the snapshot_id.")" || return 3
  else
    OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "snapshot_id" -v "$snapshot_id" -m "No snapshot_id provided and is a requirement!")" || return 3
  fi

  OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "options" -v "$options")" || return 3

	jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::getQueueGroup {
	local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


	OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No ID of the queue group object provided and is a requirement!")" || return 3

	jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::getQueueItem {
	local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


	OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No ID of the queue item object provided and is a requirement!")" || return 3

	jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::listQueueGroups {
	local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


	OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "type" -v "$type" -m "No Queue Group Type provided and is a requirement!")" || return 3

	jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::listQueueItems {
	local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


	OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "group_id" -v "$group_id" -m "No Queue Group ID provided and is a requirement!")" || return 3

	jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::clearQueue {
  local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


	jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::stopQueueGroup {
	local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


	OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No Queue Group ID provided and is a requirement!")" || return 3

	jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::stopAllQueueGroup {
  local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


	jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::manageQueuePriority {
	local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


	OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "action" -v "$action" -m "No action provided and is a requirement!")" || return 3

	if [ "$action" == "action=modify" ]; then
		OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No ID of the queue priority group provided and is a requirement!")" || return 3
		OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "download_priority" -v "$download_priority")" || return 3
		OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "restore_priority" -v "$restore_priority")" || return 3
		OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "backup_priority" -v "$backup_priority")" || return 3
		OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "clone_priority" -v "$clone_priority")" || return 3
		OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "name" -v "$name")" || return 3
	else
		OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "download_priority" -v "$download_priority" -m "No download_priority provided and is a requirement!")" || return 3
		OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "restore_priority" -v "$restore_priority" -m "No restore_priority provided and is a requirement!")" || return 3
		OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "backup_priority" -v "$backup_priority" -m "No backup_priority provided and is a requirement!")" || return 3
		OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "clone_priority" -v "$clone_priority")" || return 3
		OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "name" -v "$name" -d "$(jb5api::gen_random str 12)")" || return 3
	fi

	OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "tags" -v "$tags")" || return 3
	OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "default" -v "$default")" || return 3

	jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::getQueuePriority {
	local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


	OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No ID of the queue priority group provided and is a requirement!")" || return 3

	jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::listQueuePriorities {
	local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


	OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "priorities" -v "$priorities")" || return 3
	OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "total" -v "$total")" || return 3

	jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::deleteQueuePriority {
	local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


	OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No ID of the queue priority group provided and is a requirement!")" || return 3

	jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::rerunFailedQueueGroup {
	local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


	OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No ID of the queue priority group provided and is a requirement!")" || return 3

	jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::addMultiAccountQueueItems {
	local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


	OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "type" -v "$type" -m "No type provided and is a requirement!")" || return 3
	OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "backup_contains" -v "$backup_contains" -m "No backup_contains provided and is a requirement!")" || return 3
	OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "filters" -v "$filters" -m "No filters provided and is a requirement!")" || return 3
	OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "excluded" -v "$excluded" -m "No excluded provided and is a requirement!")" || return 3
	test "$type" == "type=2" && OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "options" -v "$options" -m "No options provided and is a requirement!")" || return 3

	jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}


#
# | **RestoreConditions**
# | Reference: https://docs.jetbackup.com/v5.3/api/RestoreConditions/restoreconditions.html
#

function jb5api::manageRestoreCondition {
    local JB5_API_FIND_ARGS OPTIONS=""
    JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


    OPTIONS+="$(jb5api::set_options -r -m "No action provided!" -o "$OPTIONS" -n "action" -v "$action")" || return 3

    if [ "$action" == "action=modify" ]; then
      OPTIONS+="$(jb5api::set_options -r -m "No ID provided!" -o "$OPTIONS" -n "id" -v "$id")" || return 3
    fi

    OPTIONS+="$(jb5api::set_options -r -m "Missing the string of text for the user to agree!" -o "$OPTIONS" -n "condition" -v "$condition")" || return 3
    OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "disabled" -v "$disabled")" || return 3

    jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::listRestoreConditions {
    local JB5_API_FIND_ARGS OPTIONS=""
    JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


    OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "find" -v "$find")" || return 3
    OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "sort" -v "$sort")" || return 3
    OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "limit" -v "$limit")" || return 3
    OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "skip" -v "$skip")" || return 3

    jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::getRestoreCondition {
    local JB5_API_FIND_ARGS OPTIONS=""
    JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


    OPTIONS+="$(jb5api::set_options -r -m "No ID provided!" -o "$OPTIONS" -n "id" -v "$id")" || return 3

    jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::deleteRestoreCondition {
    local JB5_API_FIND_ARGS OPTIONS=""
    JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


    OPTIONS+="$(jb5api::set_options -r -m "No ID provided!" -o "$OPTIONS" -n "id" -v "$id")" || return 3

    jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}


#
# | **Schedules**
# | Reference: https://docs.jetbackup.com/v5.3/api/Schedules/schedules.html
#

function jb5api::manageSchedule {
	local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


	OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "action" -v "$action" -m "No action provided and is a requirement!")" || return 3

	if [ "$action" == "action=modify" ]; then
		OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No schedule _id provided and is a requirement!")" || return 3
		OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "type" -v "$type")" || return 3
		OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "type_data" -v "$type_data")" || return 3
		OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "name" -v "$name")" || return 3
	else
	  OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "name" -v "$name" -m "No Schedule name provided and is a requirement!")" || return 3
		OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "type" -v "$type" -m "No Schedule type provided and is a requirement!")" || return 3
		OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "type_data" -v "$type_data" -m "No type_data provided and is a requirement!")" || return 3
	fi

	OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "delay_amount" -v "$delay_amount")" || return 3
	OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "delay_type" -v "$delay_type")" || return 3

	jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::listSchedules {
  local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


	jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::getSchedule {
	local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


	OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No schedule job _id provided and is a requirement!")" || return 3

	jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::deleteSchedule {
	local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


	OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No schedule job _id provided and is a requirement!")" || return 3

	jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}


#
# | **Settings**
# | Reference: https://docs.jetbackup.com/v5.3/api/Settings/settings.html
#

function jb5api::getSettingsGeneral {
  local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


  jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::manageSettingsGeneral {
  local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


  OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "error_reporting" -v "$error_reporting")" || return 3
  OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "debug" -v "$debug")" || return 3
  OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "workspace_path" -v "$workspace_path")" || return 3
  OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "downloads_path" -v "$downloads_path")" || return 3
  OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "orphan_backup_ttl" -v "$orphan_backup_ttl")" || return 3
  OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "manually_backup_ttl" -v "$manually_backup_ttl")" || return 3
  OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "manually_backup_retain" -v "$manually_backup_retain")" || return 3
  OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "logs_ttl" -v "$logs_ttl")" || return 3
  OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "alerts_ttl" -v "$alerts_ttl")" || return 3
  OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "downloads_ttl" -v "$downloads_ttl")" || return 3
  OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "email_integration" -v "$email_integration")" || return 3
  OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "time_format" -v "$time_format")" || return 3
  OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "use_community_languages" -v "$use_community_languages")" || return 3
  OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "show_damaged_backups" -v "$show_damaged_backups")" || return 3

  jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::getSettingsPerformance {
  local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


  jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::manageSettingsPerformance {
  local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


  OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "queueable_forks" -v "$queueable_forks")" || return 3
  OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "backup_forks" -v "$backup_forks")" || return 3
  OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "system_forks" -v "$system_forks")" || return 3
  OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "backup_fork_ttl" -v "$backup_fork_ttl")" || return 3
  OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "mysqldump_skip_lock" -v "$mysqldump_skip_lock")" || return 3
  OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "mysqldump_opt" -v "$mysqldump_opt")" || return 3
  OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "mysqldump_max_packet" -v "$mysqldump_max_packet")" || return 3
  OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "mysqldump_force" -v "$mysqldump_force")" || return 3
  OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "mysqldump_multibyte" -v "$mysqldump_multibyte")" || return 3
  OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "mysqldump_gtid_purged" -v "$mysqldump_gtid_purged")" || return 3
  OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "directories_queue_priority" -v "$directories_queue_priority")" || return 3
  OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "limit_account_downloads" -v "$limit_account_downloads")" || return 3
  OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "backup_integrity_check_schedule" -v "$backup_integrity_check_schedule")" || return 3

  jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::getSettingsResource {
    local JB5_API_FIND_ARGS OPTIONS=""
    JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


    jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::manageSettingsResource {
  local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


  OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "cpu_limit" -v "$cpu_limit")" || return 3
  OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "memory_limit" -v "$memory_limit")" || return 3
  OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "io_read_limit" -v "$io_read_limit")" || return 3
  OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "io_write_limit" -v "$io_write_limit")" || return 3

  jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::getSettingsRestore {
  local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


  jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::manageSettingsRestore {
  local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


  OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "limit_times" -v "$limit_times")" || return 3
  OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "limit_hours" -v "$limit_hours")" || return 3
  OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "package_selection" -v "$package_selection")" || return 3
  OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "lock_homedir" -v "$lock_homedir")" || return 3

  jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::getSettingsSecurity {
  local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


  jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::manageSettingsSecurity {
  local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


  OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "plugin" -v "$plugin")" || return 3
  OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "restore" -v "$restore")" || return 3
  OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "lock" -v "$lock")" || return 3

  jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::getSettingsPrivacy {
  local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


  jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::manageSettingsPrivacy {
  local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


  OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "user_agreement" -v "$user_agreement")" || return 3
  OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "privacy_policy" -v "$privacy_policy")" || return 3
  OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "encryption_selection" -v "$encryption_selection")" || return 3
  OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "forgotten_ttl" -v "$forgotten_ttl")" || return 3

  jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::getSettingsPanel {
  local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


  jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::manageSettingsPanel {
  local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


  OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "options" -v "$options")" || return 3

  jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::getSettingsSnapshots {
  local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


  jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::manageSettingsSnapshots {
  local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


  OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "ttl" -v "$ttl")" || return 3
  OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "retain" -v "$retain")" || return 3
  OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "backup" -v "$backup")" || return 3
  OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "rule_size" -v "$rule_size")" || return 3
  OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "rule_inodes" -v "$rule_inodes")" || return 3

  jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::manageNotificationIntegration {
  local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


  OPTIONS+="$(jb5api::set_options -r -m "No action provided!" -o "$OPTIONS" -n "action" -v "$action")" || return 3

	if [ "$action" == "action=modify" ]; then
    OPTIONS+="$(jb5api::set_options -r -m "No notification id provided!" -o "$OPTIONS" -n "id" -v "$id")" || return 3
    OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "name" -v "$name")" || return 3
    OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "type" -v "$type")" || return 3
  else
    OPTIONS+="$(jb5api::set_options -r -m "No notification name provided!" -o "$OPTIONS" -n "name" -v "$name")" || return 3
    OPTIONS+="$(jb5api::set_options -r -m "No notification type provided!" -o "$OPTIONS" -n "type" -v "$type")" || return 3
  fi

  OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "owner" -v "$owner")" || return 3
  OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "frequency" -v "$frequency")" || return 3
  OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "disabled" -v "$disabled")" || return 3
  OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "options" -v "$options")" || return 3

  jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::listNotificationIntegrationTypes {
  local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


  jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::listNotificationIntegrations {
  local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


  OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "find" -v "$find")" || return 3
  OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "sort" -v "$sort")" || return 3
  OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "limit" -v "$limit")" || return 3
  OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "skip" -v "$skip")" || return 3

  jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::getNotificationIntegration {
  local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


  OPTIONS+="$(jb5api::set_options -r -m "No Notification Integration Object ID provided!" -o "$OPTIONS" -n "id" -v "$id")" || return 3

  jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::deleteNotificationIntegration {
  local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


  OPTIONS+="$(jb5api::set_options -r -m "No Notification Integration Object ID provided!" -o "$OPTIONS" -n "id" -v "$id")" || return 3

  jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::sendNotificationIntegrationTest {
  local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


  OPTIONS+="$(jb5api::set_options -r -m "No Notification Integration Object ID provided!" -o "$OPTIONS" -n "id" -v "$id")" || return 3

  jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::getSettingsBinary {
  local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


  jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::manageSettingsBinary {
  local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


  OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "rsync" -v "$rsync")" || return 3
  OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "psql" -v "$psql")" || return 3
  OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "pgrestore" -v "$pgrestore")" || return 3
  OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "pgdump" -v "$pgdump")" || return 3
  OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "mysql" -v "$mysql")" || return 3
  OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "mysqldump" -v "$mysqldump")" || return 3
  OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "gzip" -v "$gzip")" || return 3
  OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "gunzip" -v "$gunzip")" || return 3
  OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "mongodump" -v "$mongodump")" || return 3
  OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "mongorestore" -v "$mongorestore")" || return 3

  jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}


#
# **System**
# | Reference: https://docs.jetbackup.com/v5.3/api/System/dr.html
#

function jb5api::getMasterEncryptionKey {
  local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


  jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::factoryReset {
  local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


  OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "drmode" -v "$drmode")" || return 3

  jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::exitDisasterRecovery {
  local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


  jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::approveAgreement {
  local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


  jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::approveShowcase {
  local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


  OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No Showcase ID provided and is a requirement!")" || return 3

  jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::listShowcase {
  local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


  jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}

function jb5api::GetProcessStatus {
  local JB5_API_FIND_ARGS OPTIONS=""
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


  jb5api::execute_function "${FUNCNAME[0]}" "$OPTIONS" "$request" || return 2
}



#################################
# | General purpose functions | #
#################################

# **jb5api::check_queue_group**
# | Checks the status of a queue group:
#

function jb5api::check_queue_group::check_queue_item_status {
  local QUEUE_GROUP_STATUS QUEUE_GROUP_LOG
  ERROR_PREFIX="[${FUNCNAME[0]}]: Error while using ${FUNCNAME[0]} function,"

  if [[ -n "$1" ]]; then
    QUEUE_GROUP_STATUS="$1"
  else
    echo -e "${ERROR_PREFIX} (${FUNCNAME[1]}) No queue group status provided!" >&2
    return 3
  fi

  if [[ -n "$2" ]]; then
    QUEUE_GROUP_LOG="$2"
  else
    echo -e "${ERROR_PREFIX} (${FUNCNAME[1]}) No queue group log provided!" >&2
    return
  fi

  if [[ -z "$QUEUE_GROUP_STATUS" || ! "$QUEUE_GROUP_STATUS" =~ ^[0-9]+$ ]]; then
    echo -e "${ERROR_PREFIX} (${FUNCNAME[1]}) No usable queue group status provided. ($QUEUE_GROUP_STATUS)" >&2
    return 3
  elif [[ "$QUEUE_GROUP_STATUS" =~ (104|101|102) ]]; then
    echo -e "${ERROR_PREFIX} (${FUNCNAME[1]}) Backup failed, log file:\n\n$(echo -e "$(sed 's#^#      \\e[0;100m\\e[1;97m#; s#$#\\e[0m\n\\e[0m#' < "$QUEUE_GROUP_LOG")")" >&2
    return 2
  elif [ "$QUEUE_GROUP_STATUS" -eq 103 ]; then
    echo -e "${ERROR_PREFIX} (${FUNCNAME[1]}) Backup aborted, log file:\n\n$(echo -e "$(sed 's#^#      \\e[0;100m\\e[1;97m#; s#$#\\e[0m\n\\e[0m#' < "$QUEUE_GROUP_LOG")")" >&2
    return 2
  else
    return 0
  fi
}

function jb5api::check_queue_group {
  local QUEUE_TOTAL\
        QUEUE_COUNT\
        LOADING_PARTICLES\
        PARTICLE_INDEX\
        LOADING\
        QUEUE_GROUP_DATA\
        FOUND_QUEUE_ITEM\
        QUEUE_GROUP_STATUS\
        QUEUE_BACKUP_ID\
        QUEUE_GROUP_LOG\
        RES\
        JB5_API_FIND_ARGS

  ERROR_PREFIX="[${FUNCNAME[0]}]: Error while using ${FUNCNAME[0]} function,"

  # Find args
  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"


  if [ -z "$c_type" ]; then
    echo -e "${ERROR_PREFIX} Error while using ${FUNCNAME[0]} function, no queue type supplied. (--c_type)" >&2
    return 3
  fi
  if [ -z "$c_id" ]; then
    echo -e "${ERROR_PREFIX} Error while using ${FUNCNAME[0]} function, no queue type supplied. (--c_id)" >&2
    return 3
  fi


  QUEUE_TOTAL=$(jb5api::listQueueGroups --type "$c_type" --request ".data.total")
  if [[ "$QUEUE_TOTAL" -ne 0 || ! "$QUEUE_GROUP_STATUS" =~ ^[0-9]+$ ]]; then
    QUEUE_COUNT=$(( QUEUE_TOTAL - 1 ))
  else
    echo -e "${ERROR_PREFIX} No group items in queue." >&2
    return 3
  fi

  # Loading
  LOADING_PARTICLES=('○' '◔' '◑' '●')
  readonly LOADING_PARTICLES
  PARTICLE_INDEX=0
  LOADING="\e[1m[\e[33m${LOADING_PARTICLES[$PARTICLE_INDEX]}\e[0m\e[1m]\e[0m"
  FOUND_QUEUE_ITEM=false
  QUEUE_GROUP_STATUS=0

  sleep 2

  echo -ne "$LOADING Searching queue.           \r"

  case $c_type in
    1) # Backup
      QUEUE_GROUP_DATA="$(jb5api::listQueueGroups --type 1 --request ".")"
      while [ "$QUEUE_COUNT" -ge 0 ]
      do
          LOADING="\e[1m[\e[33m${LOADING_PARTICLES[$PARTICLE_INDEX]}\e[0m\e[1m]\e[0m"

          QUEUE_BACKUP_ID="$(jb5api::jbjq -d "$QUEUE_GROUP_DATA" -r ".data.groups[$QUEUE_COUNT].data._id")"
          QUEUE_GROUP_LOG="$(jb5api::jbjq -d "$QUEUE_GROUP_DATA" -r ".data.groups[$QUEUE_COUNT].log_file")"

          if [ "$c_id" == "$QUEUE_BACKUP_ID" ]; then
              FOUND_QUEUE_ITEM=true
              echo -ne "$LOADING Backing up.           \r"
              while [ "$QUEUE_GROUP_STATUS" -ne 100 ]
              do
                  LOADING="\e[1m[\e[33m${LOADING_PARTICLES[$PARTICLE_INDEX]}\e[0m\e[1m]\e[0m"
                  PARTICLE_INDEX=$(( (PARTICLE_INDEX + 1) % 4 ))
                  if jb5api::check_queue_group::check_queue_item_status "$QUEUE_GROUP_STATUS" "$QUEUE_GROUP_LOG"; then
                    echo -ne "$LOADING\r" >&2
                    QUEUE_GROUP_STATUS="$(jb5api::listQueueGroups --type 1 --request ".data.groups[$QUEUE_COUNT].status")"
                  fi
              done
              echo -ne "Backup finished.           \n"
              break
          fi
          (( QUEUE_COUNT-- ))
          PARTICLE_INDEX=$(( (PARTICLE_INDEX + 1) % 4 ))
          echo -ne "$LOADING\r"
      done
    ;;
    2|4) # Restore & Download
      FOUND_QUEUE_ITEM=tru
      test "$c_type" -eq 4 && TYPE_NAME="Download" || TYPE_NAME="Restore"
      QUEUE_GROUP_LOG="$(jb5api::getQueueGroup --id "$c_id" --request ".data.log_file")"
      LOADING="\e[1m[\e[33m${LOADING_PARTICLES[$PARTICLE_INDEX]}\e[0m\e[1m]\e[0m"
      echo -ne "$LOADING ${TYPE_NAME}-ing.           \r"
      QUEUE_GROUP_STATUS=0
      while [ "$QUEUE_GROUP_STATUS" -ne 100 ]
      do
          LOADING="\e[1m[\e[33m${LOADING_PARTICLES[$PARTICLE_INDEX]}\e[0m\e[1m]\e[0m"
          QUEUE_GROUP_STATUS="$(jb5api::getQueueGroup --id "$c_id" --request ".data.status")"
          if jb5api::check_queue_group::check_queue_item_status "$QUEUE_GROUP_STATUS" "$QUEUE_GROUP_LOG"; then
            PARTICLE_INDEX=$(( (PARTICLE_INDEX + 1) % 4 ))
            echo -ne "$LOADING$MODE" >&2
          fi
      done
      echo -ne "$TYPE_NAME finished.           \n"
      return 0
    ;;
    8)
      LOADING="\e[1m[\e[33m${LOADING_PARTICLES[$PARTICLE_INDEX]}\e[0m\e[1m]\e[0m"
      QUEUE_GROUP_DATA="$(jb5api::listQueueGroups --type 8 --request ".")"
      FOUND_QUEUE_ITEM=false
      REINDEX_FINISHED=false
      ITERATION_COUNT=0

      echo -ne "$LOADING Searching queue.           \r"
      while [ "$QUEUE_COUNT" -ge 0 ]
      do
          LOADING="\e[1m[\e[33m${LOADING_PARTICLES[$PARTICLE_INDEX]}\e[0m\e[1m]\e[0m"
          QUEUE_GROUP_STATUS=0

          QUEUE_REINDEX_ID="$(jb5api::jbjq -d "$QUEUE_GROUP_DATA" -r ".data.groups[$QUEUE_COUNT].data.id")"
          QUEUE_GROUP_LOG="$(jb5api::jbjq -d "$QUEUE_GROUP_DATA" -r ".data.groups[$QUEUE_COUNT].log_file")"
          if [ "$c_id" == "$QUEUE_REINDEX_ID" ]; then
              FOUND_QUEUE_ITEM=true
              echo -ne "$LOADING               Reindexing.               \r"

              while [ "$ITERATION_COUNT" -le "$MAX_REINDEX_TIMEOUT" ]
              do
                  LOADING="\e[1m[\e[33m${LOADING_PARTICLES[$PARTICLE_INDEX]}\e[0m\e[1m]\e[0m (Seconds: $ITERATION_COUNT)"

                  if [ "$QUEUE_GROUP_STATUS" -eq 100 ]; then
                    REINDEX_FINISHED=true
                    break
                  fi

                  if jb5api::check_queue_group::check_queue_item_status "$QUEUE_GROUP_STATUS" "$QUEUE_GROUP_LOG"; then
                    PARTICLE_INDEX=$(( (PARTICLE_INDEX + 1) % 4 ))
                    echo -ne "$LOADING\r" >&2
                  fi

                  QUEUE_GROUP_STATUS="$(jb5api::listQueueGroups --type 8 --request ".data.groups[$QUEUE_COUNT].status")"
                  (( ITERATION_COUNT++ ))
                  sleep 1
              done

              if $REINDEX_FINISHED; then
                echo -ne "Reindex finished.                                 \n"
                break
              else
                echo -ne "${ERROR_PREFIX} Max reindex timout reached. ($MAX_REINDEX_TIMEOUT)           \n"
                return 3
              fi
          fi
          (( QUEUE_COUNT-- ))
          PARTICLE_INDEX=$(( (PARTICLE_INDEX + 1) % 4 ))
          echo -ne "$LOADING\r"
      done

      sleep "${POST_REINDEX_DELAY:-2}"
    ;;
  esac

  if ! $FOUND_QUEUE_ITEM; then
    echo -ne "${ERROR_PREFIX} Could not find matching queue item id in queue.\n"
    return 3
  fi

  # Return request
  if [ -n "$request" ];then
    RES="$(jb5api::jbjq -d "$QUEUE_GROUP_DATA" -r ".data.groups[$QUEUE_COUNT]$request")"
    echo "${RES}"
  fi
}

# **jb5api::get_account_by_name**
# | Returns account ID by username
# |

function jb5api::get_account_by_name {
  local ACCOUNT_ID TOTAL_ACCOUNTS ACCOUNTS_DATA JB5_API_FIND_ARGS
  ERROR_PREFIX="[${FUNCNAME[0]}]: Error while using ${FUNCNAME[0]} function,"

  JB5_API_FIND_ARGS="$(jb5api::find_args "$@")" || return 3
  eval "$(jb5api::find_args "$@")"

  if [[ -z "$c_username" ]]; then
    echo -e "${ERROR_PREFIX} No username provided!" >&2
    return 3
  fi

  ACCOUNTS_DATA="$(jb5api::listAccounts --find "username,$c_username")"
  TOTAL_ACCOUNTS="$(jb5api::jbjq -r ".data.total" -d "$ACCOUNTS_DATA")"

  if [[ -z "$TOTAL_ACCOUNTS" || ! "$TOTAL_ACCOUNTS" =~ ^[0-9]+$ ]]; then
    echo -e "${ERROR_PREFIX} Could not fetch total number of accounts." >&2
    return 3
  elif [ "$TOTAL_ACCOUNTS" -gt 1 ]; then
    echo -e "${ERROR_PREFIX} More than one account found." >&2
    return 3
  elif [ "$TOTAL_ACCOUNTS" -lt 1 ]; then
    echo -e "${ERROR_PREFIX} No accounts found." >&2
    return 3
  else
    ACCOUNT_ID="$(jb5api::jbjq -r ".data.accounts[-1]._id" -d "$ACCOUNTS_DATA")"
    echo "$ACCOUNT_ID"
    return 0
  fi
}