# Premissa
# Uma Storage Account é considerada subtilizada quando está com baixo tráfego de entrada e saída de dados por um longo período.

# Substitua 'MyTenantId' pelo ID de seu Tenant no Azure.
Connect-AzAccount -TenantId 'MyTenantId'

# Define o diretório para o arquivo CSV que armazenará os resultados da análise de Storage Accounts subutilizadas.
$CsvPath = "Directory\Underutilized_StorageAccounts.csv"

# Define o período de análise para os últimos 30 dias, ajustável conforme necessário.
$EndTime = Get-Date
$StartTime = $EndTime.AddDays(-30)

# Define um limite para entrada e saida de dados em MBs, ajustável conforme necessário.
$EgressDataThreshold = 50
$IngressDataThreshold = 50

$Subscriptions = Get-AzSubscription
$UnderutilizedStorageAccounts = @()
foreach ($Subscription in $Subscriptions) {
    Select-AzSubscription -SubscriptionId $Subscription.Id
    Write-Host "Processando assinatura: $($Subscription.Name) ($($Subscription.Id))"
   
    $StorageAccounts = Get-AzStorageAccount
    foreach ($StorageAccount in $StorageAccounts) {
        $EgressDataMetrics = Get-AzMetric -ResourceId $StorageAccount.Id -MetricNames "Egress" -TimeGrain '01:00:00' -StartTime $StartTime -EndTime $EndTime -Aggregation Total
        $TotalEgressData = ($EgressDataMetrics.Data | Measure-Object -Property Total -Sum).Sum / 1MB #Converte para MB

        $IngressDataMetrics = Get-AzMetric -ResourceId $StorageAccount.Id -MetricNames "Ingress" -TimeGrain '01:00:00' -StartTime $StartTime -EndTime $EndTime -Aggregation Total
        $TotalIngressData = ($IngressDataMetrics.Data | Measure-Object -Property Total -Sum).Sum / 1MB #Converte para MB

        $AccountCapacityMetrics = Get-AzMetric -ResourceId $StorageAccount.Id -MetricNames "UsedCapacity" -TimeGrain '01:00:00' -StartTime $StartTime -EndTime $EndTime -Aggregation Average
        $AverageAccountCapacity = ($AccountCapacityMetrics.Data | Measure-Object -Property Average -Average).Average / 1GB #Converte para GB

        $TransactionMetrics = Get-AzMetric -ResourceId $StorageAccount.Id -MetricNames "Transactions" -TimeGrain '01:00:00' -StartTime $StartTime -EndTime $EndTime -Aggregation Total
        $TotalTransactions = ($TransactionMetrics.Data | Measure-Object -Property Total -Sum).Sum

        if ($TotalEgressData -lt $EgressDataThreshold -and $TotalIngressData -lt $IngressDataThreshold) {
            $UnderutilizedStorageAccounts += [PSCustomObject]@{
                SubscriptionName             = $Subscription.Name
                SubscriptionId               = $Subscription.Id
                ResourceGroupName            = $StorageAccount.ResourceGroupName
                StorageAccountName           = $StorageAccount.StorageAccountName
                ReplicationType              = $StorageAccount.Sku.Name
                Kind                         = $StorageAccount.Kind
                TotalEgressDataInMB          = [math]::Round($TotalEgressData, 2) 
                TotalIngressDataInMB         = [math]::Round($TotalIngressData, 2)
                TotalTransactions            = $TotalTransactions
                AverageAccountCapacityInGB   = [math]::Round($AverageAccountCapacity, 3)
            }
        }
    }
}

$UnderutilizedStorageAccounts | Export-Csv -Path $CsvPath -NoTypeInformation -Force
Write-Host "Exportação concluída. Storage Accounts subutilizadas foram salvas em '$CsvPath'"