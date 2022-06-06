param (
    [switch]$GenerateFile,
    [string]$FilePath=".\output.csv"
)

$PadLength = 30

if ($GenerateFile -and (Test-Path -Path $FilePath -PathType Leaf)) {
    Remove-Item -Path $FilePath
}

# You may filter the resources by tenant or subscription.
#$Context = Set-AzContext -Tenant "<tenant-id>" or -Subscription "<subscription-id>"

$ErrorActionPreference = 'SilentlyContinue'
Write-Host "ResourceGroupName".PadRight($PadLength) "StorageAccountName".PadRight($PadLength) "Kind".PadRight($PadLength) HasPolicy
Write-Host "".PadRight($PadLength, '-') "".PadRight($PadLength, '-') "".PadRight($PadLength, '-') "".PadRight($PadLength, '-')

Get-AzStorageAccount -DefaultProfile $Context | ForEach-Object {
    $HasPolicy = $_.Kind -eq 'StorageV2' -and (Get-AzStorageAccountManagementPolicy -StorageAccount $_) -ne $null

    Write-Host $_.ResourceGroupName.PadRight($PadLength) $_.StorageAccountName.PadRight($PadLength) $_.Kind.PadRight($PadLength) $HasPolicy

    if ($GenerateFile) {
        Add-Content -Path $FilePath -Value "$($_.ResourceGroupName);$($_.StorageAccountName);$($_.Kind);$($HasPolicy)"
    }
}