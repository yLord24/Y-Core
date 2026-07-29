param(
	[string]$Game = "shinsei",
	[string]$Out = "",
	[string]$Root = ""
)

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = if ($Root) { $Root } else { Resolve-Path (Join-Path $scriptRoot "..") }
$builder = Join-Path $scriptRoot "build-game.js"
$arguments = @($builder, "--root", $projectRoot, "--game", $Game)

if ($Out) {
	$arguments += @("--out", $Out)
}

node @arguments
