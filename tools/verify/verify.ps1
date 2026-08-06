$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path

function Resolve-GodotExecutable {
    $candidates = @(
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

    throw "Godot was not found. Set the GODOT environment variable or install Godot 4.7.x."
}

$Godot = Resolve-GodotExecutable
Write-Host "Using Godot: $Godot"
Write-Host "Project root: $ProjectRoot"

Write-Host "==> Import project"
& $Godot --headless --path $ProjectRoot --editor --quit
if ($LASTEXITCODE -ne 0) {
    throw "Godot project import failed with exit code $LASTEXITCODE."
}

Write-Host "==> Run baseline smoke test"
& $Godot --headless --path $ProjectRoot --script "res://tests/smoke/test_project_contract.gd"
if ($LASTEXITCODE -ne 0) {
    throw "Baseline smoke test failed with exit code $LASTEXITCODE."
}

Write-Host "PASS: repository baseline verification"
