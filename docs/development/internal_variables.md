# JetBackup5API-Bash-Integration - Internal variables

## JETBACKUP_KEYS and JETBACKUP_CUSTOM_KEYS

The `JETBACKUP_KEYS` and `JETBACKUP_CUSTOM_KEYS` variables hold all keys that can be used by the `jb5api::find_args` function and subsequently any API call wrapper function.

Keys in `JETBACKUP_CUSTOM_KEYS` are not treated the same as `JETBACKUP_KEYS`, they get set with the value directly.

For example JETBACKUP_CUSTOM_KEYS:
```bash
jb5api::find_args --foo "bar"
```
Would declare `foo` with the value of `bar`.

But if `foo` was in JETBACKUP_KEYS:
```bash
jb5api::find_args --foo "bar"
```
`foo` would be declared with the value of `foo=bar`.

## JETBACKUP_API

The `JETBACKUP_API` variable holds the full path to `jetbackup5api` with static options like `-O json`.

## EXECUTE_FUNCTION_DELAY

This variable sets the delay before executing an API call to JetBackup.

## MAX_REINDEX_TIMEOUT

This variable holds the maximum amount of seconds `jb5api::check_queue_group` would wait until a reindex finishes.

## POST_REINDEX_DELAY

This variable holds the time in seconds `jb5api::check_queue_group` would wait after a reindex.

## ERROR_PREFIX

Hold the error response prefix.