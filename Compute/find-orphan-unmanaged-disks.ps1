$deleteUnattachedVHDs = $false # $true to delete | $false to see full URI of unattached VHD
$storageAccounts = Get-AzStorageAccount
foreach ($storageAccount in $storageAccounts) {
    $storageKey = (Get-AzStorageAccountKey -ResourceGroupName $storageAccount.ResourceGroupName -Name $storageAccount.StorageAccountName)[0].Value
    $context = New-AzStorageContext -StorageAccountName $storageAccount.StorageAccountName -StorageAccountKey $storageKey
    $containers = Get-AzStorageContainer -Context $context
    foreach ($container in $containers) {
        $blobs = Get-AzStorageBlob -Container $container.Name -Context $context
        #Fetch all the Page blobs with extension .vhd as only Page blobs can be attached as disk to Azure VMs
        $blobs | Where-Object { $_.BlobType -eq 'PageBlob' -and $_.Name.EndsWith('.vhd') } | ForEach-Object { 
            #If a Page blob is not attached as disk then LeaseStatus will be unlocked
            if ($_.ICloudBlob.Properties.LeaseStatus -eq 'Unlocked') {
                if ($deleteUnattachedVHDs) {
                    Write-Host "Deleting unattached VHD with Uri: $($_.ICloudBlob.Uri.AbsoluteUri)"
                    $_ | Remove-AzStorageBlob -Force
                    Write-Host "Deleted unattached VHD with Uri: $($_.ICloudBlob.Uri.AbsoluteUri)"
                }
                else {
                    $_.ICloudBlob.Uri.AbsoluteUri
                }
            }
        }
    }
}