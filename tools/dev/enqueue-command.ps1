param(
	[Parameter(Mandatory = $true)]
	[string]$Path,

	[string]$Label = "manual",

	[int]$Port = 8124
)

$ErrorActionPreference = "Stop"

$Code = [string](Get-Content -LiteralPath $Path -Raw)
$Payload = [PSCustomObject]@{
	label = $Label
	code = ([string]$Code)
} | ConvertTo-Json -Depth 8 -Compress

Invoke-RestMethod `
	-Uri "http://127.0.0.1:$Port/enqueue" `
	-Method Post `
	-Body $Payload `
	-ContentType "application/json"
