#!/bin/bash
# Use this script to make Contrast Demo AMIs available to other AWS regions.
# It uses the AMI name to know what to copy.

# Variables
VERSION=$1
SOURCE_REGION=$2
USAGE="Usage: $0 [source AMI name] [source region]\n\nExample:\n$0 hde-0.1.0 us-east-1" 

if [[ $# -ne 2 ]]; then
  echo -e $USAGE
  exit 1
fi

# Get the AMI ID of the latest HDE Golden Image
AMI_ID="$(aws ec2 describe-images --filters "Name=name,Values=${VERSION}" --region=${SOURCE_REGION} | grep -o "ami-[a-zA-Z0-9_]*")"
echo "Found matching AMI (${AMI_ID})..."

# Copy AMI to all regions
for REGION in us-east-1 us-east-2 us-west-1 us-west-2 ap-northeast-1 ap-northeast-2 ap-south-1 ap-southeast-1 ap-southeast-2 ca-central-1 cn-north-1 cn-northwest-1 eu-central-1 eu-west-1 eu-west-2 eu-west-3 sa-east-1
do
  if [ $REGION != $SOURCE_REGION ] then
    echo "Copying AMI named '${VERSION}' to '${REGION}' region..."
    aws ec2 copy-image --source-image $AMI_ID --source-region $SOURCE_REGION --region $REGION --name $VERSION
  fi
done