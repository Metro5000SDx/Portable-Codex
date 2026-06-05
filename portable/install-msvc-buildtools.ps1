$ErrorActionPreference = 'Stop'

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    throw 'winget is required to install Visual Studio Build Tools.'
}

function Get-VsInstallerPath {
    $candidates = @(
        (Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vs_installer.exe'),
        (Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\setup.exe')
    )

    foreach ($candidate in $candidates) {
        if (Test-Path $candidate) {
            return $candidate
        }
    }

    return $null
}

function Get-BuildToolsInstallPath {
    $vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
    if (-not (Test-Path $vswhere)) {
        return $null
    }

    $path = & $vswhere `
        -latest `
        -products Microsoft.VisualStudio.Product.BuildTools `
        -version '[17.0,18.0)' `
        -property installationPath 2>$null

    if ($path) {
        return $path.Trim()
    }

    return $null
}

function Test-Kernel32Lib {
    $kitsRoot = Join-Path ${env:ProgramFiles(x86)} 'Windows Kits\10\Lib'
    if (-not (Test-Path $kitsRoot)) {
        return $false
    }

    $kernel32 = Get-ChildItem -Path $kitsRoot -Recurse -Filter kernel32.lib -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -match '\\um\\x64\\kernel32\.lib$' } |
        Select-Object -First 1

    return $null -ne $kernel32
}

$components = @(
    'Microsoft.VisualStudio.Workload.VCTools',
    'Microsoft.VisualStudio.Component.VC.Tools.x86.x64',
    'Microsoft.VisualStudio.Component.Windows11SDK.22000'
)

$override = @(
    '--quiet',
    '--wait',
    '--norestart',
    '--nocache'
)
foreach ($component in $components) {
    $override += @('--add', $component)
}

winget install `
    --exact `
    --id Microsoft.VisualStudio.2022.BuildTools `
    --source winget `
    --accept-package-agreements `
    --accept-source-agreements `
    --override ($override -join ' ')

if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

$installPath = Get-BuildToolsInstallPath
if (-not $installPath) {
    throw 'Visual Studio Build Tools install path could not be found after winget install.'
}

$installer = Get-VsInstallerPath
if (-not $installer) {
    throw 'Visual Studio Installer was not found after winget install.'
}

Write-Host ''
Write-Host 'Ensuring existing Build Tools install has VC tools and Windows SDK components...'
$modifyArgs = @(
    'modify',
    '--installPath', $installPath,
    '--quiet',
    '--wait',
    '--norestart',
    '--nocache'
)
foreach ($component in $components) {
    $modifyArgs += @('--add', $component)
}

& $installer @modifyArgs
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

if (-not (Test-Kernel32Lib)) {
    throw 'Windows SDK libraries are still missing: kernel32.lib was not found under Windows Kits\10\Lib. Re-run this script as Administrator and ensure the Windows SDK component is selected.'
}

Write-Host ''
Write-Host 'MSVC Build Tools and Windows SDK are ready. Open a fresh PowerShell or rerun portable\doctor.ps1.'
