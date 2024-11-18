#!/bin/bash

# Change the AWS account ID and volume types as necessary
# This script upgrades gp2 volumes to gp3. Ensure the volumes are using the correct volume type filters.
# No need to input account number, as it’s running in AWS CloudShell

# Capture all gp2 volumes to upgrade
vols_to_upgrade=$(aws ec2 describe-volumes --filters Name=volume-type,Values=gp2 --query 'Volumes[*].VolumeId' --output text)

# Reading from file list for volumes to upgrade to gp3
vols_to_upgrade=()
for line in $(cat vols_to_upgrade.txt); do
    vols_to_upgrade+=("$line")
done

sleep 3;

# PHASE 1: Show all the volumes to upgrade prior to upgrading them
printf "The following volumes will be upgraded to gp3:\n"

echo -e '======================='
for vol in ${vols_to_upgrade[@]}; do
    echo $vol
done
echo -e '======================='

# PHASE 2: User input to accept or not to upgrading the volumes
read -rep "Proceed with upgrading ${#vols_to_upgrade[@]} volumes? [yes,no] `echo $'\n> '`" continue_input 
case $continue_input in  
  yes)  sleep 3; \
    for vol in ${vols_to_upgrade[@]}; do
        echo "Upgrading the following volume: $vol"
        command_output=$(aws ec2 describe-volumes --volume-ids $vol --query 'Volumes[*].VolumeType' --output text 2>&1)
        if [[ "${command_output}" =~ "An error occurred (InvalidVolume.NotFound)" ]]; then
            echo "Volume not found. Logging as NON-UPGRADE-INITIATED."
            echo "$vol - SKIPPED"
            echo -ne "$vol - NON-UPGRADE-INITIATED\n" >> volumes_upgraded_list.txt
            echo "####"
        elif [[ "${command_output}" =~ "gp3" ]]; then
            echo "Volume is already gp3, skipping."
            echo "$vol - ALREADY-GP3"
            echo -ne "$vol - ALREADY-GP3\n" >> volumes_upgraded_list.txt
            echo "####"
        else
            echo "Initiating upgrade for volume $vol"
            aws ec2 modify-volume --volume-type gp3 --volume-id $vol --output text > /dev/null 2>&1
            echo "Upgrade initiated for volume $vol"
            echo -ne "$vol\n" >> volumes_upgraded_list.txt
            echo "####"
        fi
    done;
    echo "Process completed.";
    exit 1 ;; 
  no) sleep 3; echo "Operation canceled. No volumes were upgraded."; exit 1;;
  *) echo "Invalid input. Please rerun the script."; exit 1 ;; 
esac