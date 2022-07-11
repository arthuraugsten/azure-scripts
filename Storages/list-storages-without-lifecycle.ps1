param (
    [switch]$GenerateFile,
    [string]$FilePath=".\output.csv"
)

$PadLength = 50

if ($GenerateFile -and (Test-Path -Path $FilePath -PathType Leaf)) {
    Remove-Item -Path $FilePath
}

$ErrorActionPreference = 'SilentlyContinue'
Write-Host "SubscriptionName".PadRight($PadLength) "ResourceGroupName".PadRight($PadLength) "StorageAccountName".PadRight($PadLength) "Kind".PadRight(20) HasPolicy
Write-Host "".PadRight($PadLength, '-') "".PadRight($PadLength, '-') "".PadRight($PadLength, '-') "".PadRight(20, '-') "".PadRight(10, '-')

ForEach ($Subscription in Get-AzSubscription) {
    $Context = Set-AzContext -Subscription $Subscription

    Get-AzStorageAccount -DefaultProfile $Context | ForEach-Object {
        $HasPolicy = $_.Kind -eq 'StorageV2' -and (Get-AzStorageAccountManagementPolicy -StorageAccount $_) -ne $null

        Write-Host $Subscription.Name.PadRight($PadLength) $_.ResourceGroupName.PadRight($PadLength) $_.StorageAccountName.PadRight($PadLength) $_.Kind.PadRight(20) $HasPolicy

        if ($GenerateFile) {
            Add-Content -Path $FilePath -Value "$($_.Name);$($_.ResourceGroupName);$($_.StorageAccountName);$($_.Kind);$($HasPolicy)"
        }
    }
}