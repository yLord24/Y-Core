param(
	[int]$Port = 8124,
	[string]$HostName = "127.0.0.1"
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$Node = Get-Command node -ErrorAction SilentlyContinue

if (-not $Node) {
	Write-Error "Node.js was not found in PATH."
	exit 1
}

& $Node.Source "$PSScriptRoot\dev-listener.js" --root "$Root" --port $Port --host $HostName
exit $LASTEXITCODE
