# This script fixes a networking configuration issue with AWS Windows 2016 instances.
# After running this script, users will be able to successfully query local instance metadata.
# This script is kindly borrowed from https://gist.github.com/Gonzales/e000b7c2e72e13701c77431d3a2ffd73

Add-Content 'c:\script.log' (date)
 
# This fixes a bug in AWS startup script processing.
 
# 169.254.169.254 is for metadata service
# 169.254.169.250 is for KmsInstanceVpc1
# 169.254.169.251 is for KmsInstanceVpc2
$ipAddrs = @("169.254.169.254/32", "169.254.169.250/32", "169.254.169.251/32")
 
$sleepTime = 1
$count = 0
 
# Retry logic for querying primary network interface and adding routes.
while($true)
{
    try
    {
        Add-Content 'c:\script.log' "Checking primary network interface"
 
        $ipConfigs = Get-NetIPConfiguration | Sort-Object -Property "InterfaceIndex" | select InterfaceIndex, IPv4DefaultGateway
        if(-not $ipConfigs -or $ipConfigs.Length -eq 0)
        {
            throw New-Object System.Exception("Failed to find the primary network interface")
        }
        $primaryIpConfig = $ipConfigs[0]
        $interfaceIndex = $primaryIpConfig.InterfaceIndex
        $defaultGateway = $primaryIpConfig.IPv4DefaultGateway.NextHop
        $interfaceMetric = 1
 
        Add-Content 'c:\script.log' "Primary network interface found. Adding routes now..."
 
        foreach ($ipAddr in $ipAddrs)
        {
            try
            {
                Remove-NetRoute -DestinationPrefix $ipAddr -PolicyStore ActiveStore -Confirm:$false -ErrorAction SilentlyContinue
                Remove-NetRoute -DestinationPrefix $ipAddr -PolicyStore PersistentStore -Confirm:$false -ErrorAction SilentlyContinue
                New-NetRoute -DestinationPrefix $ipAddr -InterfaceIndex $interfaceIndex `
                    -NextHop $defaultGateway -RouteMetric $interfaceMetric -ErrorAction Stop
                Add-Content 'c:\script.log' ("Successfully added the Route: {0}, gateway: {1}, NIC index: {2}, Metric: {3}" `
                    -f $ipAddr, $defaultGateway, $interfaceIndex, $interfaceMetric)
            }
            catch
            {
                Add-Content 'c:\script.log' ("Failed to add routes: {0}" -f $ipAddr)
            }
        }
 
        # Break if routes are added successfully.
        break
    }
    catch
    {
        Add-Content 'c:\script.log' ("Failed to add routes.. attempting it again {0}" -f $_.Exception.Message)
    }
 
    # It logs the status every 2 minutes.
    if (($count * $sleepTime) % 120 -eq 0)
    {
        Add-Content 'c:\script.log' "Message: Failed to add routes.. attempting it again"
    }
 
    Start-Sleep -seconds $sleepTime
    $count ++
}