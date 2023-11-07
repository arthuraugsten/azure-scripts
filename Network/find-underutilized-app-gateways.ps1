# Premissa
# Um Application Gateway é considerado subutilizado quando não recebe nenhuma requisição por um longo período.

# Substitua 'MyTenantId' pelo ID de seu Tenant no Azure.
Connect-AzAccount -TenantId 'MyTenantId'

# Define o diretório para o arquivo CSV que armazenará os resultados da análise de Application Gateways subutilizados.
$CsvPath = "Directory\Underutilized_AppGateway.csv"

# Define o período de análise para os últimos 30 dias, ajustável conforme necessário.
$EndTime = Get-Date
$StartTime = $EndTime.AddDays(-30)

# Define um limite para o total de requisições, ajustável conforme necessário.
$TotalRequestsThreshold = 0

$Subscriptions = Get-AzSubscription
$UnderutilizedAppGateway = @()
foreach ($Subscription in $Subscriptions) {
    Select-AzSubscription -SubscriptionId $Subscription.SubscriptionId
    Write-Host "Processando assinatura: $($Subscription.Name) ($($Subscription.SubscriptionId))"

    $AppGateways = Get-AzApplicationGateway
    foreach ($AppGateway in $AppGateways) {
        $Metrics = Get-AzMetric -ResourceId $AppGateway.Id -MetricNames "TotalRequests" -TimeGrain '01:00:00' -StartTime $StartTime -EndTime $EndTime -Aggregation Total
        $TotalRequests = ($Metrics.Data | Measure-Object -Property Total -Sum).Sum
        if ($TotalRequests -eq $TotalRequestsThreshold) {
            $UnderutilizedAppGateway += [PSCustomObject]@{
                SubscriptionName   = $Subscription.Name
                SubscriptionId     = $Subscription.SubscriptionId
                ResourceGroupName  = $AppGateway.ResourceGroupName
                AppGatewayName     = $AppGateway.Name
                Tier               = $AppGateway.Sku.Tier
                TotalRequests      = $TotalRequests
            }
        }
    }
}

$UnderutilizedAppGateway | Export-Csv -Path $CsvPath -NoTypeInformation -Force
Write-Host "Exportação concluída. Application Gateways subutilizados foram salvos em '$CsvPath'"