param(
	[Parameter(Mandatory = $true)]
	[string]$Path,

	[string]$Label = "manual",

	[int]$Timeout = 120,

	[ValidateSet("standard", "read_only")]
	[string]$Policy = "standard",

	[string]$TargetClient,

	[int]$Port = 8124
)

$ErrorActionPreference = "Stop"

$Code = [string](Get-Content -LiteralPath $Path -Raw)
$Payload = [PSCustomObject]@{
	label = $Label
	code = ([string]$Code)
	timeout = $Timeout
	policy = $Policy
	targetClient = if ([string]::IsNullOrWhiteSpace($TargetClient)) { $null } else { $TargetClient.Trim() }
} | ConvertTo-Json -Depth 8 -Compress

Invoke-RestMethod `
	-Uri "http://127.0.0.1:$Port/enqueue" `
	-Method Post `
	-Body $Payload `
	-ContentType "application/json"
