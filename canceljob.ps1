# Set variables
$workspaceSubscriptionId = Read-Host "Enter Sentinel workspace subscription ID"
$workspaceResourceGroupName = Read-Host "Enter Sentinel workspace resource group name"
$workspaceName = Read-Host "Enter Sentinel workspace name"
$jobId = Read-Host "Enter export job ID"
$apiVersion = "2023-09-01-preview"

# Build request URL
$apiEndpoint = 'https://api.loganalytics.io'
$path = "/v2/subscriptions/$workspaceSubscriptionId/resourcegroups/$workspaceResourceGroupName"
$provider = "Microsoft.OperationalInsights/workspaces/$workspaceName"
$queryString = "?api-version=$apiVersion"
$url = "$apiEndpoint$path/providers/$provider/jobs/export/$jobId/cancel$queryString"

# Send request
$invokeAzRestMethodParams = @{
  Method   = 'POST'
  Uri      = $url
}

Invoke-AzRestMethod @invokeAzRestMethodParams