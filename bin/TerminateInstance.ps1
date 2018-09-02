# Set the access credentials for demo.person@contrastsecurity.com.
Set-AWSCredential -ProfileName DemoPerson

<#
	Check to see if the instance is already running.
#>
$status = Get-EC2InstanceStatus -InstanceId $env:linux_instance_id
if ($status.InstanceState.Name -eq "terminated") {
	Write-Host "Instance already terminated"

	exit
}

Write-Host "Terminating EC2 Linux Instance"
Remove-EC2Instance -InstanceId $env:linux_instance_id -Force