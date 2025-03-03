# JetBackup5API-Bash-Integration - Internal functions


## jb5api::jbjq

`jb5api::jbjq` wraps `jq` so when it exists it would be handled by the main script.

### Options:
- **-r "<REQUEST>"**  
  [jq expressions](https://jqlang.org/manual/) seperated by `,`.

- **-e**  
  This option enables the IS_EVAL flag.
  When this option is specified, the function will use [eval](https://www.geeksforgeeks.org/using-the-eval-command-in-linux-to-run-variables-as-commands/) when returning responses for requests, this is good when you want return dynamic values directly.

- **-d "<DATA>"**  
  [JSON](https://www.json.org/json-en.html) data.

### Example Usage:

```bash
jb5api::jbjq -r ".data.accounts[-1]._id" -e -d "${ACCOUNTS_DATA}"
```