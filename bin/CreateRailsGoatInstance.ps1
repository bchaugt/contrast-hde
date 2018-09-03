# Set the access credentials for demo.person@contrastsecurity.com.
# To set new credentials, use: Set-AWSCredential -AccessKey [access key] -SecretKey [secret key] -StoreAs DemoPerson
Set-AWSCredential -ProfileName DemoPerson

# Fix AWS Windows 2016 network issue
# ./win_2016_aws_network_fix.ps1

# Define target Linux AMI by name
$target_ami_name = "hde-linux-ruby-0.1.0"
Write-Host $target_ami_name

# Check to see if the instance is already running.
<#
$status = Get-EC2InstanceStatus -InstanceId $env:linux_instance_id
if ($status.InstanceState.Name -eq "running") {
	Write-Host "Instance already running"
	$path = "http://" + $env:linux_instance_ip + ":5000"

	cmd /c start /min $path
	exit
}
#>

<#
	Get the Host IP address (AWS Internal), to send to the Linux instance. 
	The agents running on Linux instance will use it to connect to this Team Server.
#>
# $host_ip = (Get-NetIPConfiguration | `
# 				Where-Object { `
# 					$_.IPv4DefaultGateway -ne $null `
# 					-and `
# 					$_.NetAdapter.Status -ne "Disconnected" `
# 				} `
# 			).IPv4Address.IPAddress

# Get the internal (AWS internal) local IP address of this running instance to send to the new Linux instance.
# The agents running on the Linux instance will use it to connect to the TeamServer on this host.
$host_ip = Invoke-RestMethod -uri http://169.254.169.254/latest/meta-data/local-ipv4

# Prepare User Data to send to the Linux machine.
$bytes = [System.Text.Encoding]::Unicode.GetBytes($host_ip)
$user_data = [Convert]::ToBase64String($bytes)

# Get the AWS region of this running instance
$az = Invoke-RestMethod -uri http://169.254.169.254/latest/meta-data/placement/availability-zone
$region = $az.Substring(0,$az.Length-1)
Write-Host "Current region is" $region

# Get EC2 image ID
$name_values = New-Object 'collections.generic.list[string]'
$name_values.add($target_ami_name)
$filter_name = New-Object Amazon.EC2.Model.Filter -Property @{Name = "name"; Values = $name_values}
$target_image = Get-EC2Image -Filter $filter_name -Region $region

# Get the Instance Id of this running instance
$instance_id = Invoke-RestMethod -uri http://169.254.169.254/latest/meta-data/instance-id
Write-Host "Instance ID is" $instance_id

# Get the AWS public key used to launch this running instance
# $public_key = Invoke-RestMethod -uri http://169.254.169.254/latest/meta-data/public-keys
# $keyname = $public_key.Substring(2,$public_key.Length-2)
If ($keyname.Length -lt 1) {$keyname="brian"}
# Write-Host "Key is" $keyname

# Setup tags for new Linux instance
$tag_purpose = @{ Key="x-purpose"; Value="ruby demo" }
$instance_name = "Ruby-demo-for-" + $instance_id
$tag_name = @{ Key="Name"; Value=$instance_name }
$tagspec = new-object Amazon.EC2.Model.TagSpecification
$tagspec.ResourceType = "instance"
$tagspec.Tags.Add($tag_purpose)
$tagspec.Tags.Add($tag_name)

# Launch new Linux instance
Write-Host "Launching new EC2 Linux instance for Ruby demo..."
$instance = New-EC2Instance -Region $region -ImageId $target_image.ImageId -MinCount 1 -MaxCount 1 -KeyName $keyname -SecurityGroups "ContrastDemo" -InstanceType t2.medium -UserData $user_data -TagSpecification $tagspec

# Get the new Linux instance ID and IP address via it's AWS reservation info
$reservation = New-Object 'collections.generic.list[string]'
$reservation.add($instance.ReservationId)

$filter_reservation = New-Object Amazon.EC2.Model.Filter -Property @{Name = "reservation-id"; Values = $reservation}
$instances = (Get-EC2Instance -Filter $filter_reservation -Region $region).Instances
$instances[0]

# Save new Linux instance ID and private IP address to environment variables
$env:linux_instance_id = $instances[0].InstanceId
$env:linux_instance_ip = $instances[0].PrivateIpAddress
 
# Open web browser to new Linux instance running RailsGoat
$path = "http://" + $env:linux_instance_ip + ":5000"
cmd /c start /min $path

Write-Host "Your Linux instance running Ruby RailsGoat should be available in a few minutes at" $path".`n"