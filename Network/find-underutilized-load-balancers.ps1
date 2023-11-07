# Premissa
# Um Load Balancer é considerado subutilizado quando não possui nenhum BackendPool.

# Substitua 'MyTenantId' pelo ID de seu Tenant no Azure.
Connect-AzAccount -TenantId 'MyTenantId'

# Define o diretório para o arquivo CSV que armazenará os resultados da análise de Load Balancers subutilizados.
$CsvPath = "Directory\Underutilized_LoadBalancers.csv"

$Subscriptions = Get-AzSubscription
$UnderutilizedLoadBalancers = @()
foreach ($Subscription in $Subscriptions) {
    Select-AzSubscription -SubscriptionId $Subscription.Id
    Write-Host "Processando assinatura: $($Subscription.Name) ($($Subscription.SubscriptionId))"

    $LoadBalancers = Get-AzLoadBalancer
    foreach ($LoadBalancer in $LoadBalancers) {
        if ($LoadBalancer.BackendAddressPools.Count -eq 0) {
            $UnderutilizedLoadBalancers += [PSCustomObject]@{
                SubscriptionName    = $Subscription.Name
                SubscriptionId      = $Subscription.Id
                ResourceGroupName   = $LoadBalancer.ResourceGroupName
                LoadBalancerName    = $LoadBalancer.Name
                Sku                 = $LoadBalancer.Sku.Name
                Tier                = $LoadBalancer.Sku.Tier
            }
        }
    }
}

$UnderutilizedLoadBalancers | Export-Csv -Path $CsvPath -NoTypeInformation -Force
Write-Host "Exportação concluída. Load Balancers subutilizados foram salvos em '$CsvPath'"