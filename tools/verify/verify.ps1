$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path

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
$Tests = @(
    "res://tests/smoke/test_project_contract.gd",
    "res://tests/smoke/test_cross_platform_contract.gd",
    "res://tests/unit/test_logger.gd"
)

Write-Host "Using Godot: $Godot"
Write-Host "Project root: $ProjectRoot"

Write-Host "==> Import project"
& $Godot --headless --path $ProjectRoot --editor --quit
if ($LASTEXITCODE -ne 0) {
    throw "Godot project import failed with exit code $LASTEXITCODE."
}

foreach ($testPath in $Tests) {
    Write-Host "==> Run $testPath"
    & $Godot --headless --path $ProjectRoot --script $testPath
    if ($LASTEXITCODE -ne 0) {
        throw "Test failed ($testPath) with exit code $LASTEXITCODE."
    }
}

Write-Host "PASS: repository baseline verification"
