# Premissa
# Um VPN Gateway é considerado subtilizado quando está com baixo uso de rede por um longo período.

# Substitua 'MyTenantId' pelo ID de seu Tenant no Azure.
Connect-AzAccount -TenantId 'MyTenantId'

# Define o diretório para o arquivo CSV que armazenará os resultados da análise de VPN Gateways subutilizados.
$CsvPath = "Directory\Underutilized_VPNGateways.csv"

# Define o período de análise para os últimos 30 dias, ajustável conforme necessário.
$EndTime = Get-Date
$StartTime = $EndTime.AddDays(-30)

# Define um limite para utilização de rede em MBs, ajustável conforme necessário.
$BandwidthThreshold = 1

$Subscriptions = Get-AzSubscription
$UnderutilizedVpnGateways = @()
foreach ($Subscription in $Subscriptions) {
    Select-AzSubscription -SubscriptionId $Subscription.Id
    Write-Host "Processando assinatura: $($Subscription.Name) ($($Subscription.Id))"

    $ResourceGroups = Get-AzResourceGroup
    foreach ($ResourceGroup in $ResourceGroups) {
        $VnetGateways = Get-AzVirtualNetworkGateway -ResourceGroupName $ResourceGroup.ResourceGroupName

        foreach ($VnetGateway in $VnetGateways) {
            if ($VnetGateway.GatewayType -eq "VPN") {
                $BandwidthMetrics = Get-AzMetric -ResourceId $VnetGateway.Id -MetricNames "TunnelAverageBandwidth" -TimeGrain '01:00:00' -StartTime $StartTime -EndTime $EndTime -Aggregation Total
                $TotalBandwidth = ($BandwidthMetrics.Data | Measure-Object -Property Total -Sum).Sum / 1MB # Convertendo para MB
                
                    if ($TotalBandwidth -lt $BandwidthThreshold) {
                        $UnderutilizedVpnGateways += [PSCustomObject]@{
                            SubscriptionName          = $Subscription.Name
                            SubscriptionId            = $Subscription.Id
                            ResourceGroupName         = $ResourceGroup.ResourceGroupName
                            VirtualNetworkGatewayName = $VnetGateway.Name
                            Sku                       = $VnetGateway.Sku.Name
                            GatewayType               = $VnetGateway.GatewayType
                            TotalBandwidthMB          = [math]::Round($TotalBandwidth, 2)
                    }
                }
            }
        }
    }
}

$UnderutilizedVpnGateways | Export-Csv -Path $CsvPath -NoTypeInformation -Force
Write-Host "Exportação concluída. VPN Gateways subutilizados foram salvos em '$CsvPath'"