#!/bin/bash
# Creates AWS EC2 security groups in the default VPC of all AWS regions with ingress rules suitable for Contrast Security demos.
# Includes AWS regions described here except ap-northeast-3: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.RegionsAndAvailabilityZones.html.

# Variables
GROUP_NAME="ContrastDemo"

for REGION in us-east-1 us-east-2 us-west-1 us-west-2 ap-northeast-1 ap-northeast-2 ap-south-1 ap-southeast-1 ap-southeast-2 ca-central-1 cn-north-1 cn-northwest-1 eu-central-1 eu-west-1 eu-west-2 eu-west-3 sa-east-1
do
  echo "Creating '${GROUP_NAME}' EC2 security group in region '${REGION}'..."
  GROUP_ID="$(aws ec2 create-security-group --group-name ${GROUP_NAME} --description "Security group is appropriate inbound rules for Contrast demo workstation instances" --region=${REGION} | grep -o "sg-[a-zA-Z0-9_]*")"
  aws ec2 authorize-security-group-ingress \
  --group-id ${GROUP_ID} \
  --region=${REGION} \
  --ip-permissions '[{"IpProtocol": "icmp", "FromPort": -1, "ToPort": -1, "IpRanges": [{"CidrIp": "0.0.0.0/0"}], "Ipv6Ranges": [{"CidrIpv6": "::/0"}]}, {"IpProtocol": "tcp", "FromPort": 80, "ToPort": 80, "IpRanges": [{"CidrIp": "0.0.0.0/0"}], "Ipv6Ranges": [{"CidrIpv6": "::/0"}]}, {"IpProtocol": "tcp", "FromPort": 8080, "ToPort": 8080, "IpRanges": [{"CidrIp": "0.0.0.0/0"}], "Ipv6Ranges": [{"CidrIpv6": "::/0"}]}, {"IpProtocol": "tcp", "FromPort": 5000, "ToPort": 5000, "IpRanges": [{"CidrIp": "0.0.0.0/0"}], "Ipv6Ranges": [{"CidrIpv6": "::/0"}]}, {"IpProtocol": "tcp", "FromPort": 7000, "ToPort": 7000, "IpRanges": [{"CidrIp": "0.0.0.0/0"}], "Ipv6Ranges": [{"CidrIpv6": "::/0"}]}, {"IpProtocol": "tcp", "FromPort": 3389, "ToPort": 3389, "IpRanges": [{"CidrIp": "0.0.0.0/0"}], "Ipv6Ranges": [{"CidrIpv6": "::/0"}]}, {"IpProtocol": "tcp", "FromPort": 6000, "ToPort": 6000, "IpRanges": [{"CidrIp": "0.0.0.0/0"}], "Ipv6Ranges": [{"CidrIpv6": "::/0"}]}, {"IpProtocol": "tcp", "FromPort": 9000, "ToPort": 9000, "IpRanges": [{"CidrIp": "0.0.0.0/0"}], "Ipv6Ranges": [{"CidrIpv6": "::/0"}]}, {"IpProtocol": "tcp", "FromPort": 90, "ToPort": 90, "IpRanges": [{"CidrIp": "0.0.0.0/0"}], "Ipv6Ranges": [{"CidrIpv6": "::/0"}]}, {"IpProtocol": "tcp", "FromPort": 2000, "ToPort": 2000, "IpRanges": [{"CidrIp": "0.0.0.0/0"}], "Ipv6Ranges": [{"CidrIpv6": "::/0"}]}, {"IpProtocol": "tcp", "FromPort": 22, "ToPort": 22, "IpRanges": [{"CidrIp": "0.0.0.0/0"}], "Ipv6Ranges": [{"CidrIpv6": "::/0"}]}, {"IpProtocol": "tcp", "FromPort": 8000, "ToPort": 8000, "IpRanges": [{"CidrIp": "0.0.0.0/0"}], "Ipv6Ranges": [{"CidrIpv6": "::/0"}]}, {"IpProtocol": "tcp", "FromPort": 4000, "ToPort": 4000, "IpRanges": [{"CidrIp": "0.0.0.0/0"}], "Ipv6Ranges": [{"CidrIpv6": "::/0"}]}, {"IpProtocol": "tcp", "FromPort": 3000, "ToPort": 3000, "IpRanges": [{"CidrIp": "0.0.0.0/0"}], "Ipv6Ranges": [{"CidrIpv6": "::/0"}]}]'
done