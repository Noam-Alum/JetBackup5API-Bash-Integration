# JetBackup5API-Bash-Integration - Internal functions

>[!NOTE]
> Some functions might use [internal variables](/docs/internal_variables.md).

## jb5api::jbjq

`jb5api::jbjq` wraps `jq` so when it exists it would be handled by the main script.

### Usage:
```
jb5api::jbjq [OPTION]...
```

### Options:
- **-r "REQUEST"**  
  [jq expressions](https://jqlang.org/manual/) seperated by `,`.

- **-e**  
  This option enables the IS_EVAL flag.
  When this option is specified, the function will use [eval](https://www.geeksforgeeks.org/using-the-eval-command-in-linux-to-run-variables-as-commands/) when returning responses for requests, this is good when you want return dynamic values directly.

- **-d "DATA"**  
  [JSON](https://www.json.org/json-en.html) data.

### Example Usage:

```bash
jb5api::jbjq -r ".data.accounts[-1]._id" -e -d "${ACCOUNTS_DATA}"
```

## jb5api::array_contains

`jb5api::array_contains` Checks if array contains an item.

### Usage:
```
jb5api::array_contains [ITEM] [ARRAY_ITEMS]...
```

If there is an item in the given array, the function returns 0, else it returns 3.

### Example Usage:

```bash
FRUITS=("apple" "banana" "peach")
FRUIT="apple"
if jb5api::array_contains "$FRUIT" "${FRUITS[*]}"; then
  echo "Found $FRUIT in $FRUITS[*]!"
else
  echo "Could not find $FRUIT in $FRUITS[*] :("
fi
```

Would return:
```
Found apple in apple banana peach
```

## jb5api::gen_random

`jb5api::gen_random` generate random data.

### Usage:
```
jb5api::gen_random [OPTION] [LENGHT]
```

### Options:

- int | Only use numbers.
- str | Only use alphabetic characters.
- all | Use anything.

### Example Usage:

```bash
gen_random int 14
```

Would return:
```
36261766974132
```

## jb5api::execute_function

`jb5api::execute_function` executes JetBackup5 API calls and returns data based on json path/s.

### Usage:
```
jb5api::execute_function [API-CALL] [API-CALL-OPTIONS]... [REQUESTS]...
```

### Options:

- **API-CALL:** [JetBackup5API](https://docs.jetbackup.com/v5.3/api/) call name.
- **API-CALL-OPTIONS:** [JetBackup5API](https://docs.jetbackup.com/v5.3/api/) call options in the format `jetbackup5api` expects.
- **REQUESTS:** [jq expressions](https://jqlang.org/manual/) seperated by `,`.

### Example Usage:

```bash
jb5api::execute_function "listAccounts" "orphan=0&find[username]=noam" ".data.accounts[-1]._id"
```

## jb5api::find_args

`jb5api::find_args` assigns command-line argument values to variables based on JETBACKUP_CUSTOM_KEYS and JETBACKUP_KEYS.

### Usage:
```
jb5api::find_args [OPTIONS]...
```

### Options:

Keys are based on `$JETBACKUP_CUSTOM_KEYS` and `$JETBACKUP_KEYS` in `jb5_integration.bash`.

Any key but keys from `$JETBACKUP_CUSTOM_KEYS` can be an array, dictionary and 2D array using `,`.

### Example Usage:

```bash
echo "Using variables:"
jb5api::find_args --approve "1" --account_username "noam"

echo -e "\nUsing arrays:"
jb5api::find_args --tags "0,$FIRST_TAG_ID" --tags "1,$SECOND_TAG_ID"


echo -e "\nUsing dictionaries:"
jb5api::find_args --options "name,noam" --options "last name,alum"

echo -e "\nUsing 2D arrays:"
jb5api::find_args --workspace_path "0,0,/home/noam/" --workspace_path "0,1,/home/alum/"
```

Would return:
```
Using variables:
local approve="approve=1"
local account_username="account_username=noam"

Using arrays:
local tags="tags[0]=23f23f23dfewd3"
local tags="tags[0]=23f23f23dfewd3&tags[1]=qw123f31f31f3f"

Using dictionaries:
local options="options[name]=noam"
local options="options[name]=noam&options[last name]=alum"

Using 2D arrays:
local workspace_path="workspace_path[0][0]=/home/noam/"
local workspace_path="workspace_path[0][0]=/home/noam/&workspace_path[0][1]=/home/alum/"
```

## jb5api::set_options

`jb5api::set_options` appends options value for JB5 API calls.

### Usage:
```
jb5api::set_options [OPTIONS]...
```

### Options:
- **-r**  
  A boolean that tells if the option is required.

- **-n "NAME"**  
  The JB5 option name.

- **-v "VALUE"**  
  The value for the given JB5 option.

- **-d "DEFAULT"**  
  If needed, the default value for the given JB5 option. If empty, the option won't be used.

- **-o "OPTIONS"**  
  The current OPTIONS value.

- **-m "MESSAGE"**  
  For required options, supply the error message that will be shown when the option is not provided.

### Example Usage:

```bash
OPTIONS=""

type="type=1"
name="name=noam"
condition="condition=2"

OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "type" -v "$type")"
OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "name" -v "$name")"
OPTIONS+="$(jb5api::set_options -o "$OPTIONS" -n "condition" -v "$condition")"
OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No account ID provided and is a requirement!")"

id="admwqeimoidm23oi"

OPTIONS+="$(jb5api::set_options -r -o "$OPTIONS" -n "id" -v "$id" -m "No account ID provided and is a requirement!")"

echo "$OPTIONS"
```

Would return:
```
[main]: No account ID provided and is a requirement!
type=1&name=noam&condition=2&admwqeimoidm23oi
```