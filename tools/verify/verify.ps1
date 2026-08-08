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
        if (Test-Path $candidate) { return (Resolve-Path $candidate).Path }
        $command = Get-Command $candidate -ErrorAction SilentlyContinue
        if ($command) { return $command.Source }
    }
    throw "Godot was not found. Set GODOT_BIN or GODOT, or install Godot 4.7.x."
}

$Godot = Resolve-GodotExecutable

function Format-ProcessArgument {
    param([Parameter(Mandatory = $true)][string]$Value)
    if ($Value -notmatch '[\s"]') { return $Value }
    return '"' + ($Value -replace '([\\]*)"', '$1$1\"' -replace '(\\+)$', '$1$1') + '"'
}

function Invoke-GodotChecked {
    param(
        [Parameter(Mandatory = $true)][string]$Label,
        [Parameter(Mandatory = $true)][string[]]$Arguments
    )

    $StdoutPath = [System.IO.Path]::GetTempFileName()
    $StderrPath = [System.IO.Path]::GetTempFileName()
    try {
        $ProcessArguments = @($Arguments | ForEach-Object { Format-ProcessArgument -Value $_ })
        $Process = Start-Process -FilePath $Godot -ArgumentList $ProcessArguments `
            -Wait -PassThru -NoNewWindow `
            -RedirectStandardOutput $StdoutPath -RedirectStandardError $StderrPath
        $Stdout = if (Test-Path $StdoutPath) { Get-Content -Path $StdoutPath -Raw } else { "" }
        $Stderr = if (Test-Path $StderrPath) { Get-Content -Path $StderrPath -Raw } else { "" }
        if ($Stdout) { Write-Host $Stdout.TrimEnd() }
        if ($Stderr) { Write-Host $Stderr.TrimEnd() }
        $OutputText = ($Stdout + [Environment]::NewLine + $Stderr)
        if ($Process.ExitCode -ne 0) { throw "$Label failed with exit code $($Process.ExitCode)." }
        $FailurePattern = 'SCRIPT ERROR|ERROR: FAIL|ObjectDB instances were leaked|resources? still in use at exit'
        if ($OutputText -match $FailurePattern) {
            throw "$Label reported a script error, failed assertion, or leaked Godot object/resource."
        }
        return $OutputText
    }
    finally {
        Remove-Item -Path $StdoutPath, $StderrPath -Force -ErrorAction SilentlyContinue
    }
}

function Invoke-TickProbe {
    param([Parameter(Mandatory = $true)][int]$Ticks)
    $Output = Invoke-GodotChecked -Label "Tick-rate probe $Ticks Hz" -Arguments @(
        "--headless", "--fixed-fps", "$Ticks", "--path", $ProjectRoot,
        "--script", "res://tests/phase1/test_41_tick_rate_probe.gd", "--", "--ticks=$Ticks"
    )
    $Match = [regex]::Match($Output, "TICK_RESULT ticks=$Ticks speed=([0-9.]+)")
    if (-not $Match.Success) { throw "Tick-rate probe $Ticks Hz did not report speed." }
    return [double]$Match.Groups[1].Value
}

Write-Host "Using Godot: $Godot"
Write-Host "Project root: $ProjectRoot"
Write-Host "==> Import project"
Invoke-GodotChecked -Label "Godot project import" -Arguments @(
    "--headless", "--path", $ProjectRoot, "--editor", "--quit"
) | Out-Null

$Tests = Get-Content $Manifest |
    ForEach-Object { $_.Trim() } |
    Where-Object { $_ -and -not $_.StartsWith("#") }
foreach ($TestPath in $Tests) {
    Write-Host "==> Run $TestPath"
    Invoke-GodotChecked -Label "Test $TestPath" -Arguments @(
        "--headless", "--fixed-fps", "120", "--path", $ProjectRoot, "--script", $TestPath
    ) | Out-Null
}

Write-Host "==> Cross-process physics tick-rate matrix"
$Speed60 = Invoke-TickProbe -Ticks 60
$Speed120 = Invoke-TickProbe -Ticks 120
$Denominator = [Math]::Max([Math]::Max([Math]::Abs($Speed60), [Math]::Abs($Speed120)), 1e-9)
$RelativeDifference = [Math]::Abs($Speed60 - $Speed120) / $Denominator
if ($RelativeDifference -gt 0.12) {
    throw ("Tick-rate relative speed difference {0:P2} exceeds 12%." -f $RelativeDifference)
}
Write-Host ("PASS: 60/120 Hz relative speed difference = {0:P2}" -f $RelativeDifference)

if ($Benchmark) {
    Write-Host "==> Run non-authoritative benchmark contract"
    Invoke-GodotChecked -Label "Benchmark contract" -Arguments @(
        "--headless", "--fixed-fps", "120", "--path", $ProjectRoot,
        "--script", "res://tools/benchmark/run_benchmark.gd", "--",
        "--duration=1.0", "--profile=medium", "--output=user://reports/benchmark/latest.json"
    ) | Out-Null
}

Write-Host "PASS: repository verification ($($Tests.Count) tests + physics tick matrix)"
