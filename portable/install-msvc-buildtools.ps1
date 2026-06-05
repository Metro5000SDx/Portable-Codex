$ErrorActionPreference = 'Stop'

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    throw 'winget is required to install Visual Studio Build Tools.'
}

$override = @(
    '--quiet',
    '--wait',
    '--norestart',
    '--nocache',
    '--add', 'Microsoft.VisualStudio.Workload.VCTools',
    '--add', 'Microsoft.VisualStudio.Component.VC.Tools.x86.x64',
    '--add', 'Microsoft.VisualStudio.Component.Windows11SDK.22000'
) -join ' '

winget install `
    --exact `
    --id Microsoft.VisualStudio.2022.BuildTools `
    --source winget `
    --accept-package-agreements `
    --accept-source-agreements `
    --override $override

if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

Write-Host ''
Write-Host 'MSVC Build Tools install finished. Open a fresh PowerShell or rerun portable\doctor.ps1.'
