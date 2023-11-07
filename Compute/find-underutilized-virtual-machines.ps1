# Premissa
# Uma Virtual Machine é considerada subutilizada quando está com baixo uso de CPU por um longo período.

# Substitua 'MyTenantId' pelo ID de seu Tenant no Azure.
Connect-AzAccount -TenantId 'MyTenantId'

# Define o diretório para o arquivo CSV que armazenará os resultados da análise de Virtual Machines subutilizadas.
$CsvPath = "Directory\Underutilized_VirtualMachines.csv"

# Define o período de análise para os últimos 30 dias, ajustável conforme necessário.
$EndTime = Get-Date
$StartTime = $EndTime.AddDays(-30)

# Define um limite para utilização de CPU, ajustável conforme necessário.
$CpuThreshold = 5 

$Subscriptions = Get-AzSubscription
$UnderutilizedVMs = @()
foreach ($Subscription in $Subscriptions) {
    Set-AzContext -SubscriptionId $Subscription.Id
    Write-Host "Processando assinatura: $($Subscription.Name) ($($Subscription.Id))"

    $Vms = Get-AzVM
    foreach ($Vm in $Vms) {
        $CpuMetrics = Get-AzMetric -ResourceId $Vm.Id -MetricNames "Percentage CPU" -TimeGrain '01:00:00' -StartTime $StartTime -EndTime $EndTime -AggregationType Average
        $AverageCpu = ($CpuMetrics.Data | Measure-Object -Property Average -Average).Average

        $MemoryMetrics = Get-AzMetric -ResourceId $Vm.Id -MetricNames "Available Memory Bytes" -TimeGrain '01:00:00' -StartTime $StartTime -EndTime $EndTime -AggregationType Average
        $AverageMemory = ($MemoryMetrics.Data | Measure-Object -Property Average -Average).Average / 1GB # Converte para GB

        if ($AverageCpu -lt $CpuThreshold) {
            $UnderutilizedVMs += [PSCustomObject]@{
                SubscriptionName            = $Subscription.Name
                SubscriptionId              = $Subscription.Id
                ResourceGroupName           = $Vm.ResourceGroupName
                VMName                      = $Vm.Name
                VmSize                      = $Vm.HardwareProfile.VmSize
                AverageCpu                  = [math]::Round($AverageCpu, 2)
                AverageAvailableMemoryInGB  = [math]::Round($AverageMemory, 2)
            }
        }
    }
}

$UnderutilizedVMs | Export-Csv -Path $CsvPath -NoTypeInformation -Force
Write-Host "Exportação concluída. Virtual Machines subutilizadas foram salvas em '$CsvPath'"