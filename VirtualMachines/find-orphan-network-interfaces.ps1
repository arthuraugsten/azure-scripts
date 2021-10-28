$deleteNetworkInterfaces = 0 # 1 to delete | 0 to print NIC ID

Get-AzNetworkInterface | Where-Object { $_.VirtualMachine -eq $null } | ForEach-Object {
    if ($deleteNetworkInterfaces -eq 1) {
        Write-Host "Deleting unattached NIC with Id: $($_.Id)"
        $_ | Remove-AzNetworkInterface -Force
        Write-Host "Deleted unattached NIC with Id: $($_.Id)"
    }
    else {
        $_.Id
    }
}