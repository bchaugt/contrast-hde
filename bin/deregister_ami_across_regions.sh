#!/bin/bash
# This script will deregister private AMIs with the inputted name across all AWS regions

# Variables
AMI_NAME=$1
USAGE="Usage: $0 [target AMI name]\n\nExample:\n$0 hde-0.1.0"
ANSWER=n

if [[ $# -ne 1 ]]; then
  echo -e $USAGE
  exit 1
fi

echo "Are you sure you want to delete the AMI named ${AMI_NAME} from all AWS regions? [Y/n]?"
read ANSWER
if [ "${ANSWER}" = "Y" ] || [ "${ANSWER}" = "y" ]; then
  # Delete the AMI from all AWS regions
  for REGION in us-east-1 us-east-2 us-west-1 us-west-2 ap-northeast-1 ap-northeast-2 ap-south-1 ap-southeast-1 ap-southeast-2 ca-central-1 eu-central-1 eu-west-1 eu-west-2 eu-west-3 sa-east-1
  do
    # Get the AMI ID of the target AMI from its name
    AMI_ID="$(aws --region=${REGION} ec2 describe-images --filters "Name=platform,Values=windows" "Name=name,Values=${AMI_NAME}" --owner self | grep -o "ami-[a-zA-Z0-9_]*")"
    if [ -z $AMI_ID ]; then
      echo -e "\nERROR: No AMI found with the name ${AMI_NAME} in region ${REGION}."
    else
      echo -e "\nDeregisteing AMI ${AMI_ID} from ${REGION}..."
      aws --region=$REGION ec2 deregister-image --image-id $AMI_ID
    fi
  done
elif [ "${ANSWER}" = "N" ] || [ "${ANSWER}" = "n" ]; then
  exit 0
else
  echo -e "Invalid input.  Please try again."
  exit 1
fi