# Premissa
# Um Resource Group é considerado sem uso quando não possuir nenhum recurso.

# Substitua 'MyTenantId' pelo ID de seu Tenant no Azure.
Connect-AzAccount -TenantId 'MyTenantId'

# Define o diretório para o arquivo CSV que armazenará os resultados da análise de Resource Groups vazios.
$CsvPath = "Directory\Empty_ResourceGroups.csv"

$Subscriptions = Get-AzSubscription
$EmptyResourceGroups = @()
foreach ($Subscription in $Subscriptions) {
    Select-AzSubscription -SubscriptionId $Subscription.Id
    Write-Host "Processando assinatura: $($Subscription.Name) ($($Subscription.Id))"

    $ResourceGroups = Get-AzResourceGroup  
    foreach ($ResourceGroup in $ResourceGroups) {
        $resources = Get-AzResource -ResourceGroupName $ResourceGroup.ResourceGroupName
        
        if (-not $resources) {
            $EmptyResourceGroups += [PSCustomObject]@{ 
                SubscriptionName  = $Subscription.Name
                SubscriptionId    = $Subscription.Id
                ResourceGroupName = $ResourceGroup.ResourceGroupName
            }
        }
    }
}

$EmptyResourceGroups | Export-Csv -Path $CsvPath -NoTypeInformation -Force
Write-Host "Exportação concluída. Resource Groups vazios foram salvos em '$CsvPath'"