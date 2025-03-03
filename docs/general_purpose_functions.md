# General purpose functions

Some tasks are hard to make via a bash script, like checking if a queue group has finished.

The _general purpose functions_ are meant so these tasks can be easily integrated into your scripts!

## jb5api::check_queue_group

`jb5api::check_queue_group` checks the status of a queue group.

### Usage:
```
jb5api::check_queue_group [OPTIONS]...
```

### Options:
- **--c_type**  
  [Queue group type](https://docs.jetbackup.com/v5.3/api/Queues/listQueueGroups.html).
  - 1 Backup Queue
  - 2 Restore
  - 4 Download
  - 8 Reindex

- **--c_id** - Depends on the type:
    - 1) Backup Job ID.
    - 2/4) Queue group ID.
    - 8) Destination ID.

### Example Usage:

```bash
jb5api::check_queue_group --c_type 8 --c_id "$DESTINATION_ID"
```

## jb5api::get_account_by_name

`jb5api::get_account_by_name` returns account ID by username.

### Usage:
```
jb5api::get_account_by_name [OPTIONS]...
```

### Options:
- **--c_username**  
  Account username.

### Example Usage:

```bash
jb5api::get_account_by_name --c_username "noam"
```

Response:
```
665c29194aafd3c2060764b0
```