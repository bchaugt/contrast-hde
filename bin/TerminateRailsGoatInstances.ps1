# Set the access credentials for demo.person@contrastsecurity.com.
# To set new credentials, use: Set-AWSCredential -AccessKey [access key] -SecretKey [secret key] -StoreAs DemoPerson
Set-AWSCredential -ProfileName DemoPerson

# Fix AWS Windows 2016 network issue
# ./win_2016_aws_network_fix.ps1

# Get the AWS region of this running instance
$az = Invoke-RestMethod -uri http://169.254.169.254/latest/meta-data/placement/availability-zone
$region = $az.Substring(0,$az.Length-1)

# Get the instance ID of this running (Windows) instance
$windows_instance_id = Invoke-RestMethod -uri http://169.254.169.254/latest/meta-data/instance-id
$windows_instance_name = "Ruby-demo-for-" + $windows_instance_id

# Get Linux instance(s) associated with this running (Windows) instance
$linux_instances = (Get-EC2Instance -Filter @{Name="tag:Name";Value=$windows_instance_name}).Instances
For ($i=0; $i -lt $linux_instances.Length; $i++) {
	# If the found Linux instance is not already terminated, then terminate it.
	$status = Get-EC2InstanceStatus -Region $region -InstanceId $linux_instances[$i].InstanceId
	if ($status.InstanceState.Name -ne "terminated") {
		Remove-EC2Instance -Region $region -InstanceId $linux_instances[$i].InstanceId -Force
		Write-Host "Terminating Linux EC2 instance ("$linux_instances[$i].InstanceId")..."
	}
}
Write-Host "`n"