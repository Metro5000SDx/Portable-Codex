$ErrorActionPreference = 'Stop'

. "$PSScriptRoot\env.ps1"

Push-Location (Join-Path $RepoRoot 'codex-rs')
try {
    cargo build -p codex-cli --bin codex
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}
finally {
    Pop-Location
}
