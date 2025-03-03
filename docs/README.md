# **JetBackup5API Bash integration - Docs**

This library provides Bash wrappers to interact with the [JetBackup 5 API](https://docs.jetbackup.com/v5.3/api/), enabling you to perform various JetBackup 5 operations directly from the command line.

## **Using API call wrappers**

Any [JetBackup 5 API call](https://docs.jetbackup.com/v5.3/api/) can be invoked using this library.

### **Structure of API Call Wrappers**

The syntax to call an API function is as follows:
```bash
jbtapi::apiCallName
```

For example, to use the [listAccounts](https://docs.jetbackup.com/v5.3/api/Accounts/listAccounts.html) API call:
```bash
jbtapi::listAccounts
```

>[!IMPORTANT]
> To use any [PanelAPI api calls](https://docs.jetbackup.com/v5.3/api/PanelAPI/panelapi.html), replace the `/` with an `_` in the API function name.

### **API Call Options**

Almost all API call options are converted to the format `--OPTION`, making it easy to use.

For example:

```bash
jetbackup5api -F listAccounts -D "orphan=1"
```

Is equivalent to:

```bash
jbtapi::listAccounts --orphan 1
```

If a function requires a specific option, the wrapper will notify you accordingly, prompting you to provide the necessary arguments.

>[!IMPORTANT]  
> To use the `_id` option, use `--id` instead of `--_id`.

### **General Command Structure**

All API function wrappers follow the same general usage pattern:

```bash
apiCall [API-CALL-OPTIONS]... --request [REQUESTS]...
```

Where:
- **API-CALL-OPTIONS:** Options specific to the API call (e.g., `--orphan 1`, `--id <ID>`).
- **REQUESTS:** [jq expressions](https://jqlang.org/manual/) separated by commas. These allow you to filter or manipulate the API response.

### **Handling the `--request` Option**

If a function is run without a `--request` option, it will return the entire response from JetBackup 5.

**For example:**
```bash
jb5api::listAccounts --find "username,noam" --request ".data.accounts[-1].homedir"
```
Would return:
```
/home/noam
```

## General purpose functions

Some tasks are hard to make via a bash script, like checking if a queue group has finished.

The _general purpose functions_ are meant so these tasks can be easily integrated into your scripts!

> Check out the [general purpose functions](general_purpose_functions.md)


## Wrappers & functions in action:

```bash
read -rp "Username : " USERNAME

if ! ACCOUNT_ID="$(jb5api::get_account_by_name --c_username "$USERNAME" 2> /dev/null)"; then
	echo " - Account not found."
	exit 1
else
	echo " - Found user. => \"$USERNAME\""
fi
DESTINATION_NAME="$USERNAME - Example destination - $(jb5api::gen_random str 4)"
DESTINATION_ID="$(jb5api::manageDestination --action "create"\
                                            --type "Localv2"\
                                            --name "$DESTINATION_NAME"\
                                            --owner "$ACCOUNT_ID"\
                                            --options "path,/tmp/$(jb5api::gen_random str 4)/"\
                                            --request ".data._id" 2> /dev/null
                )"
if [ "$?" -ne 0 ]; then
	echo " - Cannot create destination."
	exit 1
else
	echo " - Created destination => \"$DESTINATION_NAME\""
	echo " - Starting reindex."
	if ! jb5api::check_queue_group --c_type 8 --c_id "$DESTINATION_ID" &> /dev/null; then
		echo " - Reindex failed."
		exit 1
	else
		echo " - Reindex finished."
	fi
fi
```

**Results:**
```
[root@server examples]# ./example.sh 
Username : NoSuchUser
 - Account not found.
[root@server examples]# ./example.sh 
Username : noam
 - Found user. => "noam"
 - Created destination => "noam - Example destination - dRoV"
 - Starting reindex.
 - Reindex finished.
[root@server examples]#
```

## **Exit Codes**

The following exit codes are used by this library:

| **Exit Code** | **Description**                                                                                                                                           |
|---------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------|
| **0**         | **Success** - The script/operation executed successfully without any issues.                                                                              |
| **1**         | **Bash Error** - A general Bash error occurred, such as command not found or syntax issues.                                                               |
| **2**         | **JetBackup 5 Failure** - The JetBackup 5 function did not succeed, indicated by a success status of `0` in the response.                                 |
| **3**         | **Script Error** - An error specific to the script's logic or functionality occurred, such as missing files or incorrect parameters passed to the script. |