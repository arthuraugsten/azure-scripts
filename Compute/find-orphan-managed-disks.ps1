# Premissa
# Um disco é considerado órfão quando não está sendo gerenciado por nenhuma Virtual Machine e seu estado é igual a Unattached.

# Substitua 'MyTenantId' pelo ID de seu Tenant no Azure.
Connect-AzAccount -TenantId 'MyTenantId'

# Define o diretório para o arquivo CSV que armazenará os resultados da análise de Discos órfãos.
$CsvPath = "Directory\Orphaned_Disks.csv"

$Subscriptions = Get-AzSubscription
$OrphanedDisks = @()
foreach ($Subscription in $Subscriptions) {
    Select-AzSubscription -SubscriptionId $Subscription.Id
    Write-Host "Processando assinatura: $($Subscription.Name) ($($Subscription.Id))"

    $Disks = Get-AzDisk
    foreach ($Disk in $Disks) {
        if ($Disk.DiskState -eq 'Unattached' -and -not $Disk.ManagedBy -and -not $Disk.ManagedByExtended) {
            $OrphanedDisks += [PSCustomObject]@{
                SubscriptionName    = $Subscription.Name
                SubscriptionId      = $Subscription.Id
                ResourceGroupName   = $Disk.ResourceGroupName
                DiskName            = $Disk.Name
                StorageType         = $Disk.Sku.Name
                DiskSizeGB          = $Disk.DiskSizeGB
                DiskState           = $Disk.DiskState
            }
        }
    }
}

$OrphanedDisks | Export-Csv -Path $CsvPath -NoTypeInformation -Force
Write-Host "Exportação concluída. Discos órfãos foram salvos em '$CsvPath'"