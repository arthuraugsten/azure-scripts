# Conectar ao seu Tenant no Azure
Connect-AzAccount -TenantId 9b2ef2e2-23c7-457b-b406-e7993fcc303c

# Obter todas as assinaturas
$subscriptions = Get-AzSubscription

# Definir o período para os últimos 30 dias
$endTime = Get-Date
$startTime = $endTime.AddDays(-30)

# Definir o Threshold de utilização de CPU, exemplo 5% de utilização média de CPU
$cpuThreshold = 20

# Criar uma lista para armazenar os resultados
$gatewaysToReport = @()

foreach ($subscription in $subscriptions) {
    # Selecionar a assinatura
    Select-AzSubscription -SubscriptionId $subscription.Id

    Write-Host "Processando assinatura: $($subscription.Name) ($($subscription.Id))"

    # Obter todos os grupos de recursos na assinatura
    $resourceGroups = Get-AzResourceGroup

    foreach ($resourceGroup in $resourceGroups) {
        # Obter todos os Virtual Network Gateways no grupo de recursos
        $vnetGateways = Get-AzVirtualNetworkGateway -ResourceGroupName $resourceGroup.ResourceGroupName

        foreach ($vnetGateway in $vnetGateways) {
            if ($vnetGateway.GatewayType -eq "ExpressRoute") {
                # Obter métricas de CPU
                $cpuMetrics = Get-AzMetric -ResourceId $vnetGateway.Id -MetricNames "ExpressRouteGatewayCpuUtilization" -StartTime $startTime -EndTime $endTime -Aggregation Average

                $BitsPerSecondMetrics = Get-AzMetric -ResourceId $vnetGateway.Id -MetricNames "ExpressRouteGatewayBitsPerSecond" -StartTime $startTime -EndTime $endTime -AggregationType Average
                $averageBitsPerSecond = ($BitsPerSecondMetrics.Data | Measure-Object -Property Average -Average).Average / 1MB # converte para MB

                if ($cpuMetrics.Data) {
                    $averageCpuUtilization = ($cpuMetrics.Data | Measure-Object Average -Average).Average
                    if ($averageCpuUtilization -lt $cpuThreshold) {
                        # Adicionar à lista
                        $gatewaysToReport += [PSCustomObject]@{
                            SubscriptionName          = $subscription.Name
                            ResourceGroup             = $resourceGroup.ResourceGroupName
                            VirtualNetworkGatewayName = $vnetGateway.Name
                            Sku                       = $vnetGateway.Sku.Name
                            GatewayType               = $vnetGateway.GatewayType
                            AverageCpuUtilization     = [math]::Round($averageCpuUtilization, 2)
                            AverageBitsPerSecondInMB  = [math]::Round($averageBitsPerSecond, 2)
                        }
                    }
                }
            }
        }
    }
}

# Exportar a lista para um arquivo CSV
$csvPath = "C:\Users\murilo.augsten\OneDrive - Accenture\Desktop\Underutilized_ExpressRoute.csv"
$gatewaysToReport | Export-Csv -Path $csvPath -NoTypeInformation -Force

Write-Host "Exportação concluída. Os gateways que atendem às condições foram salvos em '$csvPath'"
