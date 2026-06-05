$ErrorActionPreference = 'Stop'

. "$PSScriptRoot\env.ps1"

if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
    throw 'npm is required to install the portable prebuilt Codex package.'
}

Write-Host 'Installing prebuilt Codex CLI into .portable/npm...'
npm install --prefix $PortableNpmRoot @openai/codex@latest
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

$prebuiltBinary = Join-Path $PortableNpmRoot 'node_modules\.bin\codex.cmd'
if (-not (Test-Path $prebuiltBinary)) {
    throw "Expected prebuilt Codex launcher was not created: $prebuiltBinary"
}

Write-Host ''
Write-Host 'Prebuilt portable Codex is ready.'
Write-Host 'Run: portable\codex.ps1'
