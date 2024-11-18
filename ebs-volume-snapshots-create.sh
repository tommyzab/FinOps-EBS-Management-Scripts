#!/bin/bash

# Dynamically capture all the available volumes in the account.
# This script creates snapshots of available volumes. If you need to filter volumes by another status or criteria, adjust the filters.
# Running in AWS CloudShell, no need to input AWS account ID.

# Capture all available volumes for snapshot creation
avail_volumes=$(aws ec2 describe-volumes --filters Name=status,Values=available --query 'Volumes[*].VolumeId' --output text)

# Reading from file list for volumes to create snapshots for (vols_to_del.txt should contain volume IDs)
avail_volumes=()
for line in $(cat vols_to_del.txt); do
    avail_volumes+=("$line")
done

sleep 3;

# PHASE 1: Show all the volumes to create snapshots for prior to creation
printf "Snapshots will be created for the following volumes:\n"

echo -e '======================='
for vol in ${avail_volumes[@]}; do
    echo $vol
done
echo -e '======================='

# PHASE 2: User input to confirm or cancel snapshot creation
read -rep "Proceed with creating ${#avail_volumes[@]} snapshots? [yes,no] `echo $'\n> '`" continue_input 
case $continue_input in  
    yes) sleep 3; \
    for vol in ${avail_volumes[@]}; do
        echo "Creating snapshot for volume $vol"
        sleep 2;
        snapshot_id=$(aws ec2 create-snapshot --volume-id $vol --query 'SnapshotId' --output text 2>&1)
        if [[ "${snapshot_id}" =~ "An error occurred (InvalidVolume.NotFound)" ]]; then
            echo "Volume not found. Skipping snapshot creation."
            echo "$vol - SKIPPED"
            echo -ne "$vol - NON-SNAPSHOT-CREATED\n" >> snapshots_created_for_deleted_vols_id_list.csv
            echo "####"
        else
            snapshot_to_delete_date=$(aws ec2 describe-snapshots --snapshot-ids $snapshot_id --query 'Snapshots[*].StartTime' --output text)
            sleep 2;
            echo "Snapshot ID $snapshot_id created successfully"
            echo -ne "$snapshot_id,$snapshot_to_delete_date\n" >> snapshots_created_for_deleted_vols_id_list.csv
            echo "####"
        fi
    done;
    echo "Process completed.";
    exit 1 ;;
    no) sleep 3; echo "Operation canceled. No snapshots were created."; exit 1;;
    *) echo "Invalid input. Please rerun the script."; exit 1 ;; 
esac