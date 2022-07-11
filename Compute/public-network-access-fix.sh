declare -a resourceGroups

while test $# -gt 0; do
    if [[ "$1" = -* ]]
    then
        break;
    else
        resourceGroups+=($1)
        shift
    fi
done

updateApp() {
  declare -a resources

  while test $# -gt 0; do
    case "$1" in
    --resourceGroup|-g)
      shift
      rg="$1"
      shift
      ;;
    --appType|-t)
      shift
      appType="$1"
      shift
      ;;
    --resources|-r)
        shift
        while test $# -gt 0; do
            if [[ "$1" = -* ]]
            then
                break;
            else
                resources+=($1)
                shift
            fi
        done
        ;;
    *)
      break
      ;;
    esac
  done

  if [ -z "$resources" ]; then
    echo "No ${appType} found";
  else
    for resource in ${resources[@]}
    do
      printf "Updating $resource... "
      az resource update --resource-group $rg --name $resource --resource-type "Microsoft.Web/sites" -o none --set properties.siteConfig.publicNetworkAccess=Enabled
      #az rest -o none --method put --url /subscriptions/<subscription-id>/resourceGroups/$rg/providers/Microsoft.Web/sites/$resource?api-version=2022-03-01 --body  "{ \"location\": \"East US 2\", \"properties\": { \"siteConfig\": { \"publicNetworkAccess\": \"Enabled\" } } }"
      echo "UPDATED"
    done
  fi
}

for resourceGroup in ${resourceGroups[@]}; do
  echo "------------------ ${resourceGroup} ------------------"

  appServices=$(az webapp list -g ${resourceGroup} --query [].name -o tsv | sed 's/\r$//')
  updateApp -t "App Service" -g $resourceGroup -r $appServices

  functionApps=$(az functionapp list -g ${resourceGroup} --query [].name -o tsv | sed 's/\r$//')
  updateApp -t "Function App" -g $resourceGroup -r $functionApps

  echo ""
done