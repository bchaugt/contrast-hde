#!/bin/bash
# Creates SSH key pairs across all AWS EC2 regions with the user-specified key name.

USAGE="Usage: $0 [key name]\n\nExample:\n$0 brianchaukey (Please note that the key name cannot have spaces)"

if [[ $# -ne 1 ]]; then
  echo -e $USAGE
  exit 1
fi

# Variables
KEY_NAME=$1

for REGION in us-east-1 us-east-2 us-west-1 us-west-2 ap-northeast-1 ap-northeast-2 ap-south-1 ap-southeast-1 ap-southeast-2 ca-central-1 cn-north-1 cn-northwest-1 eu-central-1 eu-west-1 eu-west-2 eu-west-3 sa-east-1
do
  echo "Creating EC2 key pair named '${KEY_NAME}' in region '${REGION}'..."
  aws ec2 create-key-pair --key-name ${KEY_NAME} --region=${REGION}
done