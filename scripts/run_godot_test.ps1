param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]] $GodotArgs
)

$ErrorActionPreference = 'Stop'
if (-not $env:GODOT_PATH -or -not (Test-Path -LiteralPath $env:GODOT_PATH -PathType Leaf)) {
    throw 'Set GODOT_PATH to the Godot executable.'
}
$projectRoot = Split-Path -Parent $PSScriptRoot
$tempRoot = Join-Path $projectRoot 'temp'
$roaming = Join-Path $tempRoot 'godot-test/roaming'
$local = Join-Path $tempRoot 'godot-test/local'
New-Item -ItemType Directory -Force -Path $roaming, $local | Out-Null
$ignore = Join-Path $tempRoot '.gdignore'
if (-not (Test-Path -LiteralPath $ignore)) { New-Item -ItemType File -Path $ignore | Out-Null }

# This PowerShell process and its child use isolated test data, never player saves.
$env:APPDATA = $roaming
$env:LOCALAPPDATA = $local
& $env:GODOT_PATH --path $projectRoot @GodotArgs
exit $LASTEXITCODE
