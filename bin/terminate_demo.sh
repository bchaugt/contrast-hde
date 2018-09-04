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

echo "Terminating instance ${INSTANCE_ID})..."
aws --profile $HDE_PROFILE_NAME --region=$REGION_AWS ec2 terminate-instances --instance-ids $INSTANCE_ID