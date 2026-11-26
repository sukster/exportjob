# Set variables.
$workspaceSubscriptionId = Read-Host "Enter Sentinel workspace subscription ID"
$workspaceResourceGroupName = Read-Host "Enter Sentinel workspace resource group name"
$workspaceName = Read-Host "Enter Sentinel workspace name"
$apiVersion = "2023-09-01-preview"
$storageSubscriptionId = Read-Host "Enter storage account subscription ID"
$storageResourceGroupName = Read-Host "Enter storage account resource group name"
$storageAccountName = Read-Host "Enter storage account name"
$query = Read-Host "Enter table name (or query) to be exported"
$startTime = Read-Host "Enter query start time e.g. 2026-10-24T08:00:00Z"
$endTime = Read-Host "Enter query end time e.g. 2026-11-24T08:00:00Z"


# Build request URL
$apiEndpoint = 'https://api.loganalytics.io'
$path = "/v2/subscriptions/$workspaceSubscriptionId/resourcegroups/$workspaceResourceGroupName"
$provider = "Microsoft.OperationalInsights/workspaces/$workspaceName"
$queryString = "?api-version=$apiVersion"
$url = "$apiEndpoint$path/providers/$provider/jobs/export$queryString"

# Build destination storage account resource ID
$storagePath = "/subscriptions/$storageSubscriptionId/resourceGroups/$storageResourceGroupName"
$storageProviders = "Microsoft.Storage/storageAccounts/$storageAccountName"
$destinationStorageAccount = "$storagePath/providers/$storageProviders"
$containerName = (($query -split '\|', 2)[0]).Trim().ToLowerInvariant()

# Build request body
$createJobBody = @{
  startTime                  = $startTime
  endTime                    = $endTime
  query                      = $query
  destinationStorageAccounts = @($destinationStorageAccount)
  containerName              = $containerName
  outputDataFormat           = 'Parquet'
  dateTimeFormat             = 'yyyy-MM-ddTHH'
} | ConvertTo-Json -Depth 4

# Send request
$invokeAzRestMethodParams = @{
  Method   = 'POST'
  Uri      = $url
  Payload  = $createJobBody
}

$response = Invoke-AzRestMethod @invokeAzRestMethodParams
$operationId = ($response.Content | ConvertFrom-Json).operationId

if ([string]::IsNullOrWhiteSpace($operationId)) {
  Write-Error "The export job response did not contain an operationId."
  exit 1
}

Write-Host "Export job operation ID: $operationId"

# Build request URL to check status of the export job
$apiEndpoint = 'https://api.loganalytics.io'
$path = "/v2/subscriptions/$workspaceSubscriptionId/resourcegroups/$workspaceResourceGroupName"
$provider = "Microsoft.OperationalInsights/workspaces/$workspaceName"
$queryString = "?api-version=$apiVersion"
$url = "$apiEndpoint$path/providers/$provider/jobs/export/$operationId/status$queryString"

# Check the status of the export job every 10 seconds
$invokeAzRestMethodParams = @{
  Method   = 'GET'
  Uri      = $url
}

while ($true) {
  $statusResponse = Invoke-AzRestMethod @invokeAzRestMethodParams
  $statusContent = $statusResponse.Content | ConvertFrom-Json
  $jobStatus = $statusContent.jobStatus

  Write-Host "Export job status: $jobStatus"

  if ($jobStatus -eq 'Completed') {
    $statusContent
    exit 0
  }

  if ($jobStatus -in @('Failed', 'Cancelled')) {
    Write-Error "Export job ended with status '$jobStatus'."
    exit 1
  }

  Start-Sleep -Seconds 10
}
