param(
    [switch]$Benchmark
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$Manifest = Join-Path $ProjectRoot "tests\test_manifest.txt"

function Resolve-GodotExecutable {
    $candidates = @(
        $env:GODOT_BIN,
        $env:GODOT,
        "C:\Tools\Godot\godot.cmd",
        "C:\Tools\Godot\godot.exe",
        "godot4",
        "godot"
    ) | Where-Object { $_ -and $_.Trim().Length -gt 0 }

    foreach ($candidate in $candidates) {
        if (Test-Path $candidate) {
            return (Resolve-Path $candidate).Path
        }
        $command = Get-Command $candidate -ErrorAction SilentlyContinue
        if ($command) {
            return $command.Source
        }
    }
    throw "Godot was not found. Set GODOT_BIN or GODOT, or install Godot 4.7.x."
}

$Godot = Resolve-GodotExecutable

function Invoke-GodotChecked {
    param(
        [Parameter(Mandatory = $true)][string]$Label,
        [Parameter(Mandatory = $true)][string[]]$Arguments
    )

    $Output = & $Godot @Arguments 2>&1
    $ExitCode = $LASTEXITCODE
    $Output | ForEach-Object { Write-Host $_ }
    if ($ExitCode -ne 0) {
        throw "$Label failed with exit code $ExitCode."
    }
    $LeakPattern = 'ObjectDB instances were leaked|resources? still in use at exit'
    if (($Output | Out-String) -match $LeakPattern) {
        throw "$Label reported leaked Godot objects or resources."
    }
}
Write-Host "Using Godot: $Godot"
Write-Host "Project root: $ProjectRoot"

Write-Host "==> Import project"
Invoke-GodotChecked -Label "Godot project import" -Arguments @(
    "--headless", "--path", $ProjectRoot, "--editor", "--quit"
)

$Tests = Get-Content $Manifest |
    ForEach-Object { $_.Trim() } |
    Where-Object { $_ -and -not $_.StartsWith("#") }

foreach ($TestPath in $Tests) {
    Write-Host "==> Run $TestPath"
    Invoke-GodotChecked -Label "Test $TestPath" -Arguments @(
        "--headless", "--path", $ProjectRoot, "--script", $TestPath
    )
}

if ($Benchmark) {
    Write-Host "==> Run non-authoritative benchmark contract"
    Invoke-GodotChecked -Label "Benchmark contract" -Arguments @(
        "--headless", "--path", $ProjectRoot,
        "--script", "res://tools/benchmark/run_benchmark.gd", "--",
        "--duration=1.0", "--profile=medium",
        "--output=user://reports/benchmark/latest.json"
    )
}

Write-Host "PASS: repository verification ($($Tests.Count) tests)"
