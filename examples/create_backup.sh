#!/bin/bash

# Source JetBackup API integration
source ../jb5_integration.bash

# Get account by name
read -rp "For which user would you like to create a backup on demand? : " USERNAME

if ! ACCOUNT_ID="$(jb5api::get_account_by_name --c_username "$USERNAME")"; then
	jb5api::fail 3 "Cannot create backup."
else
	echo " - Found user. => \"$USERNAME\""
fi
DESTINATION_NAME="$USERNAME - Example destination - $(jb5api::gen_random str 4)"
DESTINATION_ID="$(jb5api::manageDestination --action "create"\
                                            --type "Localv2"\
                                            --name "$DESTINATION_NAME"\
                                            --owner "$ACCOUNT_ID"\
                                            --options "path,/tmp/$(jb5api::gen_random str 4)/"\
                                            --request ".data._id"
                )"
if [ "$?" -ne 0 ]; then
	jb5api::fail 2 "Cannot create destination."
else
	echo " - Created destination => \"$DESTINATION_NAME\""
	echo " - Starting reindex."
	if ! jb5api::check_queue_group --c_type 8 --c_id "$DESTINATION_ID" &> /dev/null; then
		jb5api::fail 3 "Reindex failed."
	else
		echo " - Reindex finished."
	fi
fi

BACKUP_JOB_NAME="$USERNAME - Example backup job - $(jb5api::gen_random str 4)"
BACKUP_JOB_ID="$(jb5api::manageBackupJob --action "create"\
                                         --type 1\
                                         --name "$BACKUP_JOB_NAME"\
                                         --destination "0,$DESTINATION_ID"\
                                         --contains 511\
                                         --structure 1\
                                         --retry_failed 0\
                                         --time 0350\
                                         --monitor "ranfor,1"\
                                         --monitor "notran,2"\
                                         --owner "$ACCOUNT_ID"\
                                         --disabled 0\
                                         --options 1\
                                         --request ".data._id"
                 )"
if [ "$?" -ne 0 ]; then
	jb5api::fail 2 "Cannot create backup job."
else
	echo " - Created a backup job => \"$BACKUP_JOB_NAME\""
fi

if jb5api::runBackupJobManually --id "$BACKUP_JOB_ID" &> /dev/null; then
	echo " - Sent backup job to queue."
	echo " - Checking backup status."
	if ! jb5api::check_queue_group --c_type 1 --c_id "$BACKUP_JOB_ID" &> /dev/null; then
		jb5api::fail 3 "Backup failed."
	else
		echo " - Backup finished."
	fi
else
	jb5api::fail 3 "Could not run backup job manually,"
fi

if jb5api::deleteBackupJob --id "$BACKUP_JOB_ID" &> /dev/null;then
	echo " - Removed backup job => \"$BACKUP_JOB_NAME\""
else
	jb5api::fail 3 "Could not remove backup job."
fi

if jb5api::deleteDestination --id "$DESTINATION_ID" &> /dev/null;then
        echo " - Removed destination => $DESTINATION_NAME"
else
        jb5api::fail 3 "Could not remove destination."
fi

echo " - Done."