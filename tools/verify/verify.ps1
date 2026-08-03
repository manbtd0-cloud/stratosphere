$ErrorActionPreference = "Stop"

$root = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$python = Get-Command python -ErrorAction SilentlyContinue

if ($null -eq $python) {
    $python = Get-Command py -ErrorAction SilentlyContinue
}

if ($null -eq $python) {
    Write-Error "Python 3 was not found on PATH."
    exit 1
}

Push-Location $root
try {
    if ($python.Name -eq "py.exe" -or $python.Name -eq "py") {
        & $python.Source -3 "tools/verify/verify.py"
    }
    else {
        & $python.Source "tools/verify/verify.py"
    }
    exit $LASTEXITCODE
}
finally {
    Pop-Location
}
