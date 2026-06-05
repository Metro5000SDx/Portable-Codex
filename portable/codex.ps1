$ErrorActionPreference = 'Stop'

. "$PSScriptRoot\env.ps1"

$debugBinary = Join-Path $PortableTargetDir 'debug\codex.exe'
if (Test-Path $debugBinary) {
    & $debugBinary @args
    exit $LASTEXITCODE
}

$prebuiltBinary = Join-Path $PortableNpmRoot 'node_modules\.bin\codex.cmd'
if (Test-Path $prebuiltBinary) {
    & $prebuiltBinary @args
    exit $LASTEXITCODE
}

Write-Host 'No source-built or prebuilt portable Codex binary was found.'
Write-Host 'Run portable\install-prebuilt.ps1 for immediate use, or portable\build.ps1 after MSVC Build Tools are installed.'
exit 1
