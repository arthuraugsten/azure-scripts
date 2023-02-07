Write-Host "ResourceGroupName".PadRight(30) "NetworkInterface".PadRight(100) "PrivateEndpoint Name".PadRight(30) 
Write-Host "".PadRight(30, '-') "".PadRight(100, '-') "".PadRight(30, '-') 

ForEach ($Subscription in Get-AzSubscription) {
    $Context = Set-AzContext -Subscription $Subscription

    Get-AzPrivateEndpoint -DefaultProfile $Context | Where-Object {$_.PrivateLinkServiceConnections[0].PrivateLinkServiceConnectionState.Status -eq "Disconnected"} | ForEach-Object {
        $Nic = Get-AzNetworkInterface -ResourceId $_.NetworkInterfaces[0].Id
        Write-Host $_.ResourceGroupName.PadRight(30) $Nic.Name.PadRight(100) $_.PrivateLinkServiceConnections[0].Name.PadRight(30)
    }
}