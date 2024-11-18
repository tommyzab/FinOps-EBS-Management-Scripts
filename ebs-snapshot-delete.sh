#!/bin/bash

# Change the AWS account ID and start time dates for your use case
# Replace 'your-account-id' with your AWS account ID
# Modify the dates (2024-01-21 and 2024-01-23) for the snapshot range you want to delete
snapshots_to_delete=$(aws ec2 describe-snapshots --owner-ids 'your-account-id' --query 'Snapshots[?StartTime>`2024-01-21` && StartTime<=`2024-01-23`].SnapshotId' --output text)

# AWS error handling

# Reading from file list for snapshots to delete
# snapshots_to_delete=()
# for line in $(cat snapshot_to_del.txt); do
#     snapshots_to_delete+=("$line")
# done

sleep 3;

# PHASE 1: Show all the snapshots to delete prior to deleting them
printf "The following snapshots will be deleted:\n"

COUNTER=0
echo -e '======================='
for snap in $snapshots_to_delete; do
    echo $snap
    let COUNTER=COUNTER+1
done
echo -e '======================='

# PHASE 2: User input to accept or not to deleting the snapshots
read -rep "Proceed with deletion of $COUNTER snapshots? [yes,no] `echo $'\n> '`" continue_input 
case $continue_input in  
  yes) sleep 3; \
    for snap in $snapshots_to_delete; do
        echo "Deleting the following snapshot: $snap"
        snapshot_to_delete_date=$(aws ec2 describe-snapshots --owner-ids 'your-account-id' --snapshot-ids $snap --query 'Snapshots[*].StartTime' --output text)
        command_output=$(aws ec2 delete-snapshot --snapshot-id $snap --output text 2>&1)
        if [[ "${command_output}" =~ "An error occurred (InvalidSnapshot.NotFound)" ]]; then
            echo "Snapshot not found. Logging as NON-DELETED."
            echo "$snap NON-DELETED"
            echo -ne "$snap - NON-DELETED\n" >> snapshots_deleted_id_list.csv
            echo "####"
        elif [[ "${command_output}" =~ "An error occurred" ]]; then
            echo "Snapshot encountered an error. Logging as ERR-NON-DELETED."
            echo "$snap ERR-NON-DELETED"
            echo -ne "$snap - ERR-NON-DELETED\n" >> snapshots_deleted_id_list.csv
            echo "####"
        else
            echo "$snap Deleted"
            echo -ne "$snap,$snapshot_to_delete_date\n" >> snapshots_deleted_id_list.csv
            echo "####"
        fi
    done;
    echo "Process completed.";
    exit 1 ;; 
  no) sleep 3; echo "Operation canceled. No snapshots were deleted."; exit 1;;
  *) echo "Invalid input. Please rerun the script."; exit 1 ;; 
esac