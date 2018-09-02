# Set the access credentials for demo.person@contrastsecurity.com.
# To set new credentials, use: Set-AWSCredential -AccessKey [access key] -SecretKey [secret key] -StoreAs DemoPerson
Set-AWSCredential -ProfileName DemoPerson

# Get the AWS region of this running instance
$az = Invoke-RestMethod -uri http://169.254.169.254/latest/meta-data/placement/availability-zone
$region = $az.Substring(0,$az.Length-1)

<#
	Check to see if the instance is already running.
#>
$status = Get-EC2InstanceStatus -Region $region -InstanceId $env:linux_instance_id
if ($status.InstanceState.Name -eq "terminated") {
	Write-Host "Instance already terminated"

	exit
}

Write-Host "Terminating EC2 Linux Instance"
Remove-EC2Instance -Region $region -InstanceId $env:linux_instance_id -Force