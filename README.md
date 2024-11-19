# FinOps EBS Management Scripts

This repository offers a suite of Shell scripts designed to automate critical management tasks for AWS resources, with a focus on EBS volumes and snapshots. These scripts streamline operations such as creation, deletion, and upgrades, ensuring efficiency and safety in managing EBS resources while offering a flexible automation solution for cloud infrastructure management.

## Overview

The scripts in this repository allow you to:
* Create snapshots for EBS volumes before deletion.
* Delete EBS snapshots and volumes based on specific criteria.
* Upgrade EBS volumes from gp2 to gp3.
* Generate reports documenting each action for tracking and auditing.

## Available Scripts

1.	ebs-snapshot-delete
Deletes EBS snapshots, either by date filter or using a pre-defined list of snapshot IDs. A report (snapshots_deleted_id_list.csv) is generated after execution.
2.	ebs-volume-snapshots-create
Creates snapshots for EBS volumes before deletion, using either a dynamic approach (fetching available volumes) or reading from a predefined list. A report (snapshots_created_for_deleted_vols_id_list.csv) is generated.
3.	ebs-volume-delete
Deletes EBS volumes, either based on dynamic discovery or a provided list. No report is generated for this operation.
4.	ebs-upgrade-volumes
Upgrades gp2 EBS volumes to gp3, either by dynamically detecting eligible volumes or using a list. A report (volumes_upgraded_list.txt) is created.

### Script Execution Process

#### Phase 1: Resource Overview

Each script begins by showing the resources that will be affected. This ensures you know what will be modified or deleted before any changes are made. The resource list will include EBS volumes, snapshots, and the relevant actions (e.g., delete, upgrade, snapshot).

```
Display affected resources
printf "The following resources will be interacted with:\n"
echo -e '======================='
for resource in ${affected_resources[@]}; do
    echo $resource
done
echo -e '======================='
```

#### Phase 2: User Confirmation

Once the resource list is displayed, the script asks for confirmation to proceed with the actions. You’ll be prompted to type yes to confirm or no to cancel the operation.
* yes: Proceeds with the selected action (e.g., creating snapshots, deleting volumes).
* no: Cancels the operation, and no changes are made.
* If neither yes nor no is entered, the script will exit with a message.

```
Request user confirmation to proceed
read -rep "Proceed with the following actions: ${#affected_resources[@]}? [yes,no] `echo $'\n> '`" continue_input
case $continue_input in
    yes) 
        # Proceed with the actions
        ;;
    no)  
        # Cancel the operations
        echo "The operation has been canceled. No changes were made."
        exit 1
        ;;
    *)   
        # Invalid input
        echo "Invalid input. Please rerun the script."
        exit 1
        ;;
esac
```

### Dynamic vs Static Resource Identification

Depending on your preference and situation, you can either dynamically discover resources or use a predefined list.

#### Dynamic Approach

Use AWS CLI commands to fetch relevant resources directly from your AWS account. For example, to get all available volumes:
```
# Dynamically fetch all available volumes
avail_volumes=$(aws ec2 describe-volumes --filters Name=status,Values=available --query 'Volumes[*].VolumeId' --output text)
```

#### Static Approach

For predefined resources, simply create a .txt file listing the resource IDs. Each ID should be on a separate line. For example:
```
vol-123
vol-456
vol-789
```

The script will read these IDs and perform the necessary actions.
```
# Read resource IDs from a .txt file
resource_list=()
for line in $(cat resources_to_process.txt); do
    resource_list+=("$line")
done
```

### How to Use the Scripts

To use the scripts:
1. Upload the script to AWS CloudShell:
    * Open CloudShell in your AWS account.
    * Go to Actions → Upload file and select the script file.
2. Execute the script using:
```
bash <script>.sh
```

You’ll be prompted to confirm actions during execution.

### Reporting

Each script will generate a report detailing the actions taken:
* snapshots_deleted_id_list.csv: Contains IDs of deleted snapshots.
* snapshots_created_for_deleted_vols_id_list.csv: Contains IDs of snapshots created for volumes.
* volumes_upgraded_list.txt: Contains details of upgraded volumes.

### Notes

* Ensure that the .txt files (e.g., vols_to_del.txt, snapshot_to_del.txt) are placed in the same directory as the script.
* The confirmation steps can be helpful for safety, but advanced users can skip them if desired by modifying the script.
