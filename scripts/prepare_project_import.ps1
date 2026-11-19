param(
    [Parameter(Mandatory)]
    [ValidateSet('game', 'devtools')]
    [string] $Launcher
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$godotCache = Join-Path $projectRoot '.godot'
$snapshotPath = Join-Path $projectRoot 'temp/project-import-state.txt'
$relativeLogPath = "temp/$Launcher/import.log"
$logPath = Join-Path $projectRoot $relativeLogPath

function Get-FileState([IO.FileInfo] $File) {
    '{0}|{1}|{2}' -f $File.FullName, $File.Length, $File.LastWriteTimeUtc.Ticks
}

function Get-ImportState {
    $sources = [Collections.Generic.List[string]]::new()
    $metadata = [Collections.Generic.List[string]]::new()
    $directories = [Collections.Generic.Stack[IO.DirectoryInfo]]::new()
    $cacheReady = $true
    $directories.Push([IO.DirectoryInfo]::new($projectRoot))
    while ($directories.Count -gt 0) {
        $directory = $directories.Pop()
        if ([IO.File]::Exists((Join-Path $directory.FullName '.gdignore'))) { continue }
        foreach ($entry in $directory.EnumerateFileSystemInfos()) {
            if ($entry.Name.StartsWith('.')) { continue }
            if ($entry.Attributes -band [IO.FileAttributes]::ReparsePoint) {
                $cacheReady = $false
            } elseif ($entry -is [IO.DirectoryInfo]) {
                $directories.Push($entry)
            } elseif ($entry.Extension -in '.import', '.uid') {
                $metadata.Add((Get-FileState $entry))
            } else {
                $sources.Add((Get-FileState $entry))
            }
        }
    }
    $sources.Add((Get-FileState ([IO.FileInfo]::new($env:GODOT_PATH))))
    $sources.Sort([StringComparer]::Ordinal)

    $imported = [IO.DirectoryInfo]::new((Join-Path $godotCache 'imported'))
    $cacheReady = $cacheReady -and $imported.Exists
    foreach ($name in 'global_script_class_cache.cfg', 'uid_cache.bin') {
        $file = [IO.FileInfo]::new((Join-Path $godotCache $name))
        if ($file.Exists -and $file.Length -gt 0) {
            $metadata.Add((Get-FileState $file))
        } else {
            $cacheReady = $false
        }
    }
    if ($imported.Exists) {
        foreach ($file in $imported.EnumerateFiles()) {
            $metadata.Add((Get-FileState $file))
        }
    }
    $metadata.Sort([StringComparer]::Ordinal)
    $sourceState = [string]::Join("`n", $sources)
    @{
        Sources = $sourceState
        Snapshot = $sourceState + "`n" + [string]::Join("`n", $metadata)
        CacheReady = $cacheReady
    }
}

$hash = [Security.Cryptography.SHA256]::Create()
$projectKey = [Convert]::ToBase64String($hash.ComputeHash([Text.Encoding]::UTF8.GetBytes($projectRoot.ToUpperInvariant())))
$hash.Dispose()
$mutex = [Threading.Mutex]::new($false, 'StarWorldProjectImport-' + $projectKey.Replace('/', '_'))
try {
    try { $null = $mutex.WaitOne() } catch [Threading.AbandonedMutexException] {}
    try {
        $before = Get-ImportState
        if ($before.CacheReady -and [IO.File]::Exists($snapshotPath) -and
            [IO.File]::ReadAllText($snapshotPath) -ceq $before.Snapshot) { exit 0 }

        [IO.File]::Delete($snapshotPath)
        Write-Host "[Import] $relativeLogPath"
        & {
            $ErrorActionPreference = 'Continue'
            & $env:GODOT_PATH --headless --path $projectRoot --editor --import --quit 2>&1 |
                ForEach-Object { $_.ToString() } | Out-File -LiteralPath $logPath -Encoding utf8
        }
        if ($LASTEXITCODE -ne 0) {
            Get-Content -LiteralPath $logPath
            throw 'Resource import failed. Check the Godot output and GODOT_PATH.'
        }

        if (Select-String -LiteralPath $logPath -Pattern '^(SCRIPT )?ERROR:' -Quiet) { exit 0 }
        $after = Get-ImportState
        if ($after.CacheReady -and $after.Sources -ceq $before.Sources) {
            [IO.File]::WriteAllText($snapshotPath, $after.Snapshot)
        }
    } finally {
        $mutex.ReleaseMutex()
    }
} finally {
    $mutex.Dispose()
}
