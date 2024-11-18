#!/bin/bash

# Dynamically capture all the available volumes in the account.
# This script deletes volumes with 'available' status. You can adjust the filters if necessary.
# Running in AWS CloudShell, no need to input AWS account ID.

# Capture all available volumes for deletion
avail_volumes=$(aws ec2 describe-volumes --filters Name=status,Values=available --query 'Volumes[*].VolumeId' --output text)

# Reading from file list for volumes to delete (vols_to_del.txt should contain volume IDs)
avail_volumes=()
for line in $(cat vols_to_del.txt); do
    avail_volumes+=("$line")
done

sleep 3;

# PHASE 1: Show all the volumes to delete prior to deleting them
printf "The following volumes will be deleted:\n"

echo -e '======================='
for vol in ${avail_volumes[@]}; do
    echo $vol
done
echo -e '======================='

# PHASE 2: User input to confirm or cancel deletion
read -rep "Proceed with deleting ${#avail_volumes[@]} volumes? [yes,no] `echo $'\n> '`" continue_input 
case $continue_input in  
  yes) sleep 3; \
    for vol in ${avail_volumes[@]}; do
        echo "Deleting the following volume: $vol"
        command_output=$(aws ec2 delete-volume --volume-id $vol --output text 2>&1)
        if [[ "${command_output}" =~ "An error occurred (InvalidVolume.NotFound)" ]]; then
            echo "Volume not found. Skipping..."
            echo "$vol - SKIPPED"
            echo "####"
        else
            echo "Volume $vol deleted."
            echo "####"
        fi
    done;
    echo "Process completed.";
    exit 1 ;; 
  no) sleep 3; echo "Operation canceled. No volumes were deleted."; exit 1;;
  *) echo "Invalid input. Please rerun the script."; exit 1 ;; 
esac