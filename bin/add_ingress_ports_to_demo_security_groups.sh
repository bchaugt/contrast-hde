#!/bin/bash
# Adds the specified TCP port number to the existing 'ContrastDemo' AWS security groups across all regions.
# Includes AWS regions described here except ap-northeast-3: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.RegionsAndAvailabilityZones.html.

# Variables
USAGE="Usage: $0 [port number]\n\nExample:\n$0 8080"
GROUP_NAME="ContrastDemo"
PORT=$1
# IP_PERMISSIONS="$("IpProtocol": "tcp", "FromPort": ${PORT}, "ToPort": ${PORT}, "IpRanges": [{"CidrIp": "0.0.0.0/0"}], "Ipv6Ranges": [{"CidrIpv6": "::/0"}])"

# Check if all expected arguments were provided
if [[ $# -ne 1 ]]; then
  echo -e $USAGE
  exit 1
fi

# Add inbound security group rule across all regions except for China (cn-north-1 cn-northwest-1) where it's not allowed
for REGION in us-east-1 us-east-2 us-west-1 us-west-2 ap-northeast-1 ap-northeast-2 ap-south-1 ap-southeast-1 ap-southeast-2 ca-central-1 eu-central-1 eu-west-1 eu-west-2 eu-west-3 sa-east-1
do
  echo "Updating '${GROUP_NAME}' EC2 security group in region '${REGION}' to allow inbound access from port ${PORT}..."
  aws --region=$REGION ec2 authorize-security-group-ingress \
  --group-name $GROUP_NAME \
  --ip-permissions IpProtocol=tcp,FromPort=$PORT,ToPort=$PORT,IpRanges=' [{CidrIp=0.0.0.0/0}]',Ipv6Ranges=' [{CidrIpv6=::/0}]'
done