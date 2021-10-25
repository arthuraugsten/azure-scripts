$deleteUnattachedDisks = 0 # 1 to delete | 0 to print disk ID

# ManagedBy property stores the Id of the VM to which Managed Disk is attached to
# If ManagedBy property is $null then it means that the Managed Disk is not attached to a VM
Get-AzDisk | Where-Object  { $_.ManagedBy -eq $null } | ForEach-Object {
    if ($deleteUnattachedDisks -eq 1) {
        Write-Host "Deleting unattached Managed Disk with Id: $($_.Id)"
        $_ | Remove-AzDisk -Force
        Write-Host "Deleted unattached Managed Disk with Id: $($_.Id) "
    }
    else {
        $_.Id
    }
}