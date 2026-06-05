$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path -LiteralPath (Split-Path -Parent $PSScriptRoot)).Path
$SubstDrive = 'P:'
$SubstRoot = "$SubstDrive\"
$substOutput = (& subst) -join "`n"
if ($substOutput -match "P:\\: => (.+)") {
    $existingSubstTarget = $matches[1].Trim()
    if ($existingSubstTarget -ne $RepoRoot) {
        $SubstRoot = $RepoRoot
    }
} else {
    & subst $SubstDrive $RepoRoot
}

$PortablePathRoot = if (Test-Path $SubstRoot) { $SubstRoot } else { $RepoRoot }
$PortableRoot = Join-Path $PortablePathRoot '.portable'
$PortableBin = Join-Path $PortableRoot 'bin'
$PortableNpmRoot = Join-Path $PortableRoot 'npm'
$PortableCodexHome = Join-Path $PortableRoot 'codex-home'
$PortableCargoHome = Join-Path $PortableRoot 'cargo'
$PortableRustupHome = Join-Path $PortableRoot 'rustup'
$PortableTargetDir = Join-Path $PortableRoot 'target'

foreach ($path in @(
    $PortableRoot,
    $PortableBin,
    $PortableNpmRoot,
    $PortableCodexHome,
    $PortableCargoHome,
    $PortableRustupHome,
    $PortableTargetDir
)) {
    New-Item -ItemType Directory -Force -Path $path | Out-Null
}

$env:CODEX_HOME = $PortableCodexHome
$env:CARGO_HOME = $PortableCargoHome
$env:RUSTUP_HOME = $PortableRustupHome
$env:CARGO_TARGET_DIR = $PortableTargetDir
$env:npm_config_prefix = $PortableNpmRoot
$env:NPM_CONFIG_PREFIX = $PortableNpmRoot
$env:CARGO_NET_GIT_FETCH_WITH_CLI = 'true'
$env:GIT_CONFIG_COUNT = '1'
$env:GIT_CONFIG_KEY_0 = 'core.longpaths'
$env:GIT_CONFIG_VALUE_0 = 'true'
$env:Path = @(
    (Join-Path $PortableCargoHome 'bin'),
    $PortableNpmRoot,
    (Join-Path $PortableNpmRoot 'node_modules\.bin'),
    $PortableBin,
    $env:Path
) -join ';'

function Enter-PortableVsDevShell {
    $vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
    if (-not (Test-Path $vswhere)) {
        return
    }

    $installPath = & $vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath 2>$null
    if (-not $installPath) {
        return
    }

    $vsDevCmd = Join-Path $installPath 'Common7\Tools\VsDevCmd.bat'
    if (-not (Test-Path $vsDevCmd)) {
        return
    }

    $arch = if ($env:PROCESSOR_ARCHITEW6432 -eq 'ARM64' -or $env:PROCESSOR_ARCHITECTURE -eq 'ARM64') { 'arm64' } else { 'x64' }
    $envLines = & cmd.exe /c ('"{0}" -no_logo -arch={1} -host_arch={1} & set' -f $vsDevCmd, $arch)
    foreach ($line in $envLines) {
        if ($line -match '^(.*?)=(.*)$') {
            [Environment]::SetEnvironmentVariable($matches[1], $matches[2], 'Process')
        }
    }
}

Enter-PortableVsDevShell
