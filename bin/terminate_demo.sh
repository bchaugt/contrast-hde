#!/bin/bash
# This script will terminate the EC2 with the specified Instance ID

#Variables
USAGE="Usage: $0 [region] [instance ID]\n\nExample: $0 us-west-1 i-12345a1b2cdefg34h"
REGION_AWS=$1
INSTANCE_ID=$2
HDE_PROFILE_NAME=contrast-hde

# Check if all expected arguments were provided
if [[ $# -ne 2 ]]; then
  echo -e $USAGE
  exit 1
fi

# Terminate the user-specified instance
WINDOWS_INSTANCE_STATUS="$(aws --profile ${HDE_PROFILE_NAME} --region=${REGION_AWS} ec2 describe-instance-status --instance-id ${INSTANCE_ID} | grep "Code" | grep -Eo "[0-9]{1,2}" )"
if [ $WINDOWS_INSTANCE_STATUS != 48 ]; then # EC2 status code of '48' means the instance is 'terminated'
  echo "Found instance with ID ${INSTANCE_ID}..."
  echo "Terminating Windows demo workstation instance ${INSTANCE_ID})..."
  aws --profile $HDE_PROFILE_NAME --region=$REGION_AWS ec2 terminate-instances --instance-ids $INSTANCE_ID
else
  echo "The specified instance ${INSTANCE_ID} is already terminated or does not exist in region ${REGION_AWS}."
fi

# Find associated Linux instances used for Ruby demos
# LINUX_INSTANCES="$(aws --profile $HDE_PROFILE_NAME --region=$REGION_AWS ec2 describe-instances --filter "Name=tag:Name,Values=Ruby-demo-for-${INSTANCE_ID}" | grep InstanceId | grep -o "i-[a-zA-Z0-9_]*")"
# echo $LINUX_INSTANCES