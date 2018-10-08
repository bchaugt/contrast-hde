#!/bin/bash
# Launches Contrast Security SE virtual Windows developer workstation in AWS for demo purposes
# This script is meant to be run on MacOS

# Variables
DEFAULT_DEMO_AMI=hde-0.1.21 # This value should updated whenever a new AMI for the Contrast demo "golden image" is created
USAGE="Usage: $0 [demo version] [customer name or description] [your name] [your target AWS region] [hours to keep demo running]\n\nExample:\n$0 default 'Acme Corp' 'Brian Chau' us-west-1 2"
VERSION=$1
CUSTOMER=$2
CONTACT=$3
REGION_AWS=$4 # For a list of AWS regions, look here: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.RegionsAndAvailabilityZones.html
TTL=$5
ALARM_PERIOD=900 # CloudWatch alarm period of 900 seconds (15 minutes)
TTL_BUFFER=2 # Number of additional $ALARM_PERIOD duration buffers before automatic termination of demo instances
TTL_PERIODS=0
CREATION_TIMESTAMP="$(date '+%Y-%m-%d %H:%M:%S')"
INSTANCE_TYPE=m5.xlarge
AWS_DIR=~/.aws
AWS_CONFIG_FILE=~/.aws/config
AWS_CRED_FILE=~/.aws/credentials
HDE_PROFILE_NAME=contrast-hde
PUBLIC_IP=""
PING_COUNT=3
DESKTOP_WIDTH=2560
DESKTOP_HEIGHT=1600

# Check if all expected arguments were provided
if [[ $# -ne 5 ]]; then
  echo -e $USAGE
  exit 1
fi

# Create directory and files for AWS access info if they do not exist
if [ ! -d $AWS_DIR ]; then
  mkdir -p $AWS_DIR
fi

if [ -e $AWS_CONFIG_FILE ]
then
  # Backup existing AWS config
  cp $AWS_CONFIG_FILE ~/.aws/config.bak
else
  echo -e "Creating ${AWS_CONFIG_FILE}..."
  touch $AWS_CONFIG_FILE
fi

if [ -e $AWS_CRED_FILE ]
then
  # Backup existing AWS credentials files
  cp $AWS_CRED_FILE ~/.aws/credentials.bak
else
  echo -e "Creating ${AWS_CRED_FILE}..."
  touch $AWS_CRED_FILE
fi

# Check if the AWS config file already has the `contrast-hde` profile and configure if not
if ! grep -Fxq "[profile ${HDE_PROFILE_NAME}]" $AWS_CONFIG_FILE
then
  # Configure the AWS config file
  echo "Configuring ${AWS_CONFIG_FILE}... "
  echo -e "\n[profile ${HDE_PROFILE_NAME}]\nregion = ${REGION_AWS}\noutput = json" >> $AWS_CONFIG_FILE
fi

# Check if the AWS credentials file already has the `contrast-hde` profile and configure if not
if ! grep -Fxq "[${HDE_PROFILE_NAME}]" $AWS_CRED_FILE
then
  # Get user's AWS access and secret keys
  echo -e "Enter the Contrast demo environment AWS Access Key:"
  read AWS_ACCESS_KEY
  echo -e "Enter the Contrast demo environment AWS Secret Access Key:"
  read AWS_SECRET_KEY

  # Configure the AWS credential files to contain necessary keys
  echo "Configuring ${AWS_CRED_FILE}... "
  echo -e "\n[${HDE_PROFILE_NAME}]\naws_access_key_id = ${AWS_ACCESS_KEY}\naws_secret_access_key = ${AWS_SECRET_KEY}" >> $AWS_CRED_FILE
fi

# Get the AMI ID of the latest HDE "Golden Image"
# The 'default' AMI name is hde-0.1.0 as of August 31, 2018.
if [[ $VERSION = default ]]; then
  VERSION=$DEFAULT_DEMO_AMI # This value should be set to the name of the latest Contrast demo AMI
fi
echo "${CREATION_TIMESTAMP} - Input version is: ${VERSION}"
AMI_ID="$(aws --profile ${HDE_PROFILE_NAME} ec2 describe-images --filters "Name=name,Values=${VERSION}" --region=${REGION_AWS} | grep -o "ami-[a-zA-Z0-9_]*")"
if [ ! -z $AMI_ID ]; then
  echo "Found matching AMI (${AMI_ID})..."
else
  echo "ERROR: Could not find matching AMI named ${VERSION} in the ${REGION_AWS} region."
  exit 1
fi

# Create instance Name tag
TAG_NAME="${CUSTOMER}-${CONTACT}"

# Create log directory if it does not already exist
if [ ! -d "logs" ]; then
  mkdir -p logs
fi

# Launch the AWS EC2 instance
LAUNCH_INSTANCE=$(aws --profile $HDE_PROFILE_NAME ec2 run-instances \
--image-id $AMI_ID \
--count 1 \
--instance-type $INSTANCE_TYPE \
--security-groups 'ContrastDemo' \
--tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${TAG_NAME}},{Key=Owner,Value=${CONTACT}},{Key=Demo-Version,Value=${VERSION}},{Key=x-purpose,Value='demo'},{Key=x-creation-timestamp,Value=${CREATION_TIMESTAMP}}]" \
--block-device-mapping "DeviceName=/dev/sda1,Ebs={DeleteOnTermination=true}" \
--region=$REGION_AWS \
> "logs/demo_instance_${REGION_AWS}_${CREATION_TIMESTAMP}.log")

if [ $LAUNCH_INSTANCE ]; then
  echo "Something went wrong, launching the EC2 instance failed!  Please try again or contact the Contrast Sales Engineering team for assistance."
  exit 1
fi

# Get the Instance ID of the newly created instance
INSTANCEID="$(aws --profile ${HDE_PROFILE_NAME} ec2 describe-instances --region=${REGION_AWS} --filters "Name=tag:Name,Values=${TAG_NAME}" "Name=instance-state-name,Values=pending" | grep InstanceId | grep -o "i-[a-zA-Z0-9_]*")"

if [ ! -z $INSTANCEID ]; then
  echo -e "\nLaunching Contrast virtual Windows developer workstation..."

  # Get public IP address of the newly created instance
  PUBLIC_IP="$(aws --profile ${HDE_PROFILE_NAME} ec2 describe-instances --region=${REGION_AWS} --filters "Name=tag:Name,Values=${TAG_NAME}" "Name=instance-id,Values=${INSTANCEID}" | grep PublicIpAddress | grep -Eo "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}")"
  echo -e "  InstanceID: ${INSTANCEID}"
  echo -e "  Public IP: ${PUBLIC_IP}"
  echo -e "\nWait about 10 minutes, then open your remote desktop client and connect to ${PUBLIC_IP} as 'Administrator'."
  echo -e "If you do not know the password, please ask your friendly neighborhood sales engineer."

  if [ $TTL -gt 0 ]; then
    # Check if the TTL value is greater than 24, and if so, then set it to the maximum alarm duration allowed by CloudWatch, which is 24
    if [ $TTL -gt 24 ]; then
      TTL=24
      TTL_PERIODS=$(expr $TTL \* 3600 / $ALARM_PERIOD)
      echo -e "\nThe maximum allowed CloudWatch alarm duration is 24 hours.  Resetting the auto-termination alarm to trigger after 24 hours."
    else
      TTL_PERIODS=$(expr $TTL \* 3600 / $ALARM_PERIOD + $TTL_BUFFER)
    fi
    # Set unique name for the CloudWatch alarm
    ALARM_NAME="Auto-terminate ${INSTANCEID} after ${TTL} hours"

    # Set CloudWatch alarm to automatically terminate the EC2 instance when the TTL expires
    TERMINATION_ALARM=$(aws --profile $HDE_PROFILE_NAME --region=${REGION_AWS} cloudwatch put-metric-alarm \
    --alarm-name "${ALARM_NAME}" \
    --alarm-description "Terminate instance after ${TTL} hours" \
    --namespace AWS/EC2 \
    --metric-name CPUUtilization \
    --unit Percent \
    --statistic Average \
    --period $ALARM_PERIOD \
    --evaluation-periods $TTL_PERIODS \
    --threshold 0 \
    --comparison-operator GreaterThanOrEqualToThreshold \
    --dimensions "Name=InstanceId,Value=${INSTANCEID}" \
    --alarm-actions arn:aws:automate:$REGION_AWS:ec2:terminate)

    if [ $TERMINATION_ALARM ]; then
      aws --profile $HDE_PROFILE_NAME --region=${REGION_AWS} ec2 terminate-instances --instance-ids $INSTANCEID
      echo "Something went wrong, setting the alarm to automatically terminate this instance failed!  Please try again or contact the Contrast Sales Engineering team for assistance."
      exit 1
    else
      echo -e "\nYour workstation will automatically terminate after ${TTL} hour(s)."
    fi
  else
    # No alarm will be set and this instance will need to be auto-terminated
    echo -e "\n*** PLEASE NOTE THAT THIS NEW INSTANCE WILL NOT BE AUTOMATICALLY TERMINATED ***"
  fi

  # Sleep 5 minutes and then check if the new instance is network accessible
  echo -e "\nNow let's wait for 5 minutes and then check if the instance is ready..."
  sleep 300

  # Check if the new instance is publicly accessible every 10 seconds
  while true; do
    # Ping the new instance's public IP address to see if there is any packet loss
    PING_RESPONSE="$(ping -c ${PING_COUNT} ${PUBLIC_IP} | grep -o " 0.0% packet loss" )" # The blank space before '0.0%...' is important
    echo $PING_RESPONSE

    if [ "${PING_RESPONSE}" = " 0.0% packet loss" ]; then
      # If the instance is available, then launch Microsoft Remote Desktop to connect
      echo -e "Opening Microsoft Remote Desktop session to your new virtual Windows developer workstation!"
      open -Fa /Applications/Microsoft\ Remote\ Desktop.app "rdp://full%20address=s:${PUBLIC_IP}&audiomode=i:0&disable%20themes=i:1&screen%20mode%20id=i:2&smart%20sizing=i:1&username=s:Administrator&session%20bpp=i:32&allow%20font%20smoothing=i:1&prompt%20for%20credentials%20on%20client=i:0&disable%20full%20window%20drag=i:1&autoreconnection%20enabled=i:1"
      # open -Fa /Applications/Microsoft\ Remote\ Desktop.app "rdp://full%20address=s:${PUBLIC_IP}&audiomode=i:0&disable%20themes=i:1&desktopwidth:i:${DESKTOP_WIDTH}&desktopheight:i:${DESKTOP_HEIGHT}&screen%20mode%20id=i:2&smart%20sizing=i:1&username=s:Administrator&session%20bpp=i:32&allow%20font%20smoothing=i:1&prompt%20for%20credentials%20on%20client=i:0&disable%20full%20window%20drag=i:1&autoreconnection%20enabled=i:1"
      break
    else
      echo -n "."
      sleep 10
    fi
  done
fi