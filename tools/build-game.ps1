param(
	[string]$Game = "shinsei",
	[string]$Out = "",
	[string]$Root = "",
	[string]$PublicBaseUrl = "",
	[string[]]$ExternalPrefix = @(),
	[switch]$Full,
	[switch]$Verbose
)

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = if ($Root) { $Root } else { Resolve-Path (Join-Path $scriptRoot "..") }
$builder = Join-Path $scriptRoot "build-game.js"
$arguments = @($builder, "--root", $projectRoot, "--game", $Game)

if ($Out) {
	$arguments += @("--out", $Out)
}

if ($PublicBaseUrl) {
	$arguments += @("--public-base-url", $PublicBaseUrl)
}

foreach ($prefix in $ExternalPrefix) {
	if ($prefix) {
		$arguments += @("--external-prefix", $prefix)
	}
}

if ($Full) {
	$arguments += "--full"
}

if ($Verbose) {
	$arguments += "--verbose"
}

node @arguments
