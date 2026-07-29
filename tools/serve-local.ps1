param(
	[int]$Port = 8124
)

$Root = Split-Path -Parent $PSScriptRoot
Write-Host "Serving Y Core from $Root"
Write-Host "Local server: http://127.0.0.1:$Port"
Write-Host "Root loader:  http://127.0.0.1:$Port/loader.lua"

$node = Get-Command node -ErrorAction SilentlyContinue
if ($node) {
	& node "$PSScriptRoot\serve-local.js" --root "$Root" --port $Port
	exit $LASTEXITCODE
}

Write-Error "Node.js was not found in PATH. Install Node.js or host this folder with another local HTTP server."
exit 1
