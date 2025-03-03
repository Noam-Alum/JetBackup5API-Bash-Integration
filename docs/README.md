# **JetBackup5API-Bash-Integration**

This library provides Bash wrappers to interact with the [JetBackup 5 API](https://docs.jetbackup.com/v5.3/api/), enabling you to perform various JetBackup 5 operations directly from the command line.

**You can either source via `curl`:**
```bash
#!/bin/bash
source <(curl -LS "https://raw.githubusercontent.com/Noam-Alum/JetBackup5API-Bash-Integration/refs/heads/main/jb5_integration.bash")

jb5api::listAccounts --request '.data.accounts[-1].username'
```

**Or download it and source directly:**
```bash
#!/bin/bash
source jb5_integration.bash

jb5api::listAccounts --request '.data.accounts[-1].username'
```

## **Using API call wrappers**

> Any [JetBackup 5 API call](https://docs.jetbackup.com/v5.3/api/) can be invoked using this library.

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

> If a function requires a specific option, the wrapper will notify you accordingly, prompting you to provide the necessary arguments.

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

## **Exit Codes**

The following exit codes are used by this library:

| **Exit Code** | **Description**                                                                                                                                           |
|---------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------|
| **0**         | **Success** - The script/operation executed successfully without any issues.                                                                              |
| **1**         | **Bash Error** - A general Bash error occurred, such as command not found or syntax issues.                                                               |
| **2**         | **JetBackup 5 Failure** - The JetBackup 5 function did not succeed, indicated by a success status of `0` in the response.                                 |
| **3**         | **Script Error** - An error specific to the script's logic or functionality occurred, such as missing files or incorrect parameters passed to the script. |