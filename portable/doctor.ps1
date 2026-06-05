$ErrorActionPreference = 'Stop'

. "$PSScriptRoot\env.ps1"

Write-Host 'Portable Codex paths'
Write-Host "RepoRoot:          $RepoRoot"
Write-Host "CODEX_HOME:        $env:CODEX_HOME"
Write-Host "CARGO_HOME:        $env:CARGO_HOME"
Write-Host "RUSTUP_HOME:       $env:RUSTUP_HOME"
Write-Host "CARGO_TARGET_DIR:  $env:CARGO_TARGET_DIR"
Write-Host ''

Write-Host 'Tooling'
foreach ($cmd in @('git', 'node', 'pnpm', 'rustup', 'cargo', 'cl', 'link')) {
    $found = Get-Command $cmd -ErrorAction SilentlyContinue
    if ($found) {
        Write-Host ("{0,-8} {1}" -f $cmd, $found.Source)
    } else {
        Write-Host ("{0,-8} missing" -f $cmd)
    }
}
Write-Host ''

if (Test-Path (Join-Path $PortableTargetDir 'debug\codex.exe')) {
    Write-Host 'Build: debug codex.exe exists'
} else {
    Write-Host 'Build: debug codex.exe not built yet'
}
