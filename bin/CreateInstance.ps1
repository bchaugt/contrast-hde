# Set the access credentials for demo.person@contrastsecurity.com.
Set-AWSCredential -ProfileName DemoPerson

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
$host_ip = (Get-NetIPConfiguration | `
				Where-Object { `
					$_.IPv4DefaultGateway -ne $null `
					-and `
					$_.NetAdapter.Status -ne "Disconnected" `
				} `
			).IPv4Address.IPAddress

# Prepare User Data to send to the Linux machine.
$bytes = [System.Text.Encoding]::Unicode.GetBytes($host_ip)
$user_data = [Convert]::ToBase64String($bytes)

# Get EC2 image ID
$name_values = New-Object 'collections.generic.list[string]'
$name_values.add($target_ami_name)
$filter_name = New-Object Amazon.EC2.Model.Filter -Property @{Name = "name"; Values = $name_values}
$target_image = Get-EC2Image -Filter $filter_name

# Setup tags for new Linux instance
$tag_purpose = @{ Key="x-purpose"; Value="ruby demo" }
$instance_name = "Ruby-demo"
$tag_name = @{ Key="Name"; Value=$instance_name }
$tagspec = new-object Amazon.EC2.Model.TagSpecification
$tagspec.ResourceType = "instance"
$tagspec.Tags.Add($tag_purpose)
$tagspec.Tags.Add($tag_name)

# Launch new Linux instance (OLD ami-0a9b8f30792e14be5)
Write-Host "Launching new EC2 Linux instance for Ruby demo..."
$instance = New-EC2Instance -ImageId $target_image.ImageId -MinCount 1 -MaxCount 1 -KeyName Girish -SecurityGroups "ContrastDemo" -InstanceType t2.medium -UserData $user_data -TagSpecification $tagspec

$reservation = New-Object 'collections.generic.list[string]'
$reservation.add($instance.ReservationId)

$filter_reservation = New-Object Amazon.EC2.Model.Filter -Property @{Name = "reservation-id"; Values = $reservation}
$instances = (Get-EC2Instance -Filter $filter_reservation).Instances
$instances[0]

# Save new Linux instance ID and private IP address to environment variables
$env:linux_instance_id = $instances[0].InstanceId
$env:linux_instance_ip = $instances[0].PrivateIpAddress
 
# Open web browser to new Linux instance running RailsGoat
$path = "http://" + $env:linux_instance_ip + ":5000"
cmd /c start /min $path