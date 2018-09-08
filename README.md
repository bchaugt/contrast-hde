# Contrast Security Hosted Demo Environment
This repo contains multiple scripts used to launch, manage, and use the Contrast Security Hosted Demo Environment.  The demo environment is comprised of a "virtual developer workstation" and related services hosted in AWS, which enables demonstrations of Contrast's innovative application security monitoring and protection platform.

The provided shell scripts are meant to  be run from a Mac.  The included PowerShell scripts are meant to be used from within the Windows "virtual developer workstation" for demonstration additional Contrast capabilities.

# Script Descriptions and Details
The `/bin` folder contains various scripts; below is more information about each one.

## Shell Scripts (for Mac users)
### add_ingress_ports_to_demo_security_groups.sh
This script will add a new AWS security group inbound TCP rule for the user-specified port number.<br/>
**Usage:** `./add_ingress_ports_to_demo_security_groups.sh [port number]`

**Example:**
`./add_ingress_ports_to_demo_security_groups.sh 8080`
<br/>

### copy_ami_to_all_regions.sh
This script will copy a source AMI across all AWS regions.  The source AMI is identified based on its name and source AWS region.<br/>
**Usage:** `./copy_ami_to_all_regions.sh [source AMI name] [source region]`

**Example:**
`./copy_ami_to_all_regions.sh hde-0.1.0 us-east-1`
<br/>

### create_demo_security_groups.sh
This script will create a security group call `ContrastDemo` across all AWS regions.<br/>
**Usage:** `./create_demo_security_groups.sh`

### demo_contrast.sh
This script will launch a new Contrast demo "virtual developer workstation".  It expects 5 input arguments:
* Demo version/name of the latest demo EC2 AMI – you can specify default and that will automatically launch the latest AMI
* Customer name or description, so your instance can be distinguished among your other demo instances
* Your name, to help identify instances you’ve created
* Your target AWS region, which should be closest to your geographic location (find your closest region at https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.RegionsAndAvailabilityZones.html)
* Number of hours you need to keep the instance running – the instance will automatically terminate after the specified number of hours

**Usage:** `./demo_contrast.sh [demo version] [customer name or description] [your name] [your target AWS region] [hours to keep demo running]`

**Example:**
`./demo_contrast.sh default 'Acme Corp' 'Brian Chau' us-west-1 2`
<br/>

### deregister_ami_across_regions.sh
This script will deregister AMIs across all AWS regions based on the specified AMI name.  It is meant to be used to easily deregister obsolete Contrast demo workstation AMIs.<br/>
**Usage:** `./deregister_ami_across_regions.sh [target AMI name]`

**Example:**
`./deregister_ami_across_regions.sh hde-0.1.0`
<br/>

<br/><br/>
## PowerShell Scripts
The following PowerShell scripts are designed to only be run from within a Contrast demo "virtual developer workstation".  There are located in `C:\Contrast` within the demo workstation.

### CreateRailsGoatInstance.ps1
This script will launch a Linux EC2 instance from within a Windows "virtual developer workstation" to support a Ruby RailsSGoat demonstration.  The result is a Linux server in the same AWS VPC that is pre-configured to serve RailsGoat and connect to the Contrast TeamServer running on the Wndows workstation.  This script can be used to launch multiple Linux instances with RailsGoat if needed.<br/>
**Usage:** `.\CreateRailsGoatInstance.ps1`
<br/>

### dotNet_agent_delayed_start.ps1
This script will wait for 120 seconds, then stop the Contrast .NET agent service and start it up again to ensure it is active and running.<br/>
**Usage:** `.\dotNet_agent_delayed_start.ps1`
<br/>

### TerminateRailsGoatInstances.ps1
This script will terminate all Linux EC2 instances that are associated with the Windows "virtual developer workstation" from which it is run.  If multiple Linux instances for RailsGoat were launched, this script will terminate them all.<br/>
**Usage:** `.\TerminateRailsGoatInstances.ps1`
<br/>

### win_2016_aws_network_fix.ps1
This script is kindly borrowed from https://gist.github.com/Gonzales/e000b7c2e72e13701c77431d3a2ffd73.  It fixes an issue with AWS Windows 2016 AMIs where it does not properly register routes to 169.254.169.254 by default, the AWS EC2 meta-data service to get information about a running instance from within an instance itself.  This script is automatically run upon startup from the Contrast demo "virtual developer workstation" and should not need to be run again.<br/>
**Usage:** `.\win_2016_aws_network_fix.ps1`