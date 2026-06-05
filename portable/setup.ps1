$ErrorActionPreference = 'Stop'

. "$PSScriptRoot\env.ps1"

$rustupInit = Join-Path $PortableBin 'rustup-init.exe'
if (-not (Test-Path $rustupInit)) {
    Write-Host 'Downloading rustup-init into .portable/bin...'
    Invoke-WebRequest -Uri 'https://static.rust-lang.org/rustup/dist/x86_64-pc-windows-msvc/rustup-init.exe' -OutFile $rustupInit
}

if (-not (Get-Command rustup -ErrorAction SilentlyContinue)) {
    Write-Host 'Installing local Rustup without modifying user PATH...'
    & $rustupInit -y --no-modify-path --profile minimal --default-toolchain none
}

Write-Host 'Installing repo Rust toolchain into .portable/rustup...'
rustup toolchain install 1.95.0 --profile minimal --component clippy --component rustfmt --component rust-src

$configPath = Join-Path $PortableCodexHome 'config.toml'
if (-not (Test-Path $configPath)) {
    @'
# Portable Codex uses this local CODEX_HOME so it does not share auth,
# sessions, plugins, logs, or config with the Codex Windows app.

[features]
'@ | Set-Content -Path $configPath -Encoding utf8
}

Write-Host ''
Write-Host 'Portable environment ready.'
Write-Host "CODEX_HOME=$env:CODEX_HOME"
Write-Host "CARGO_HOME=$env:CARGO_HOME"
Write-Host "RUSTUP_HOME=$env:RUSTUP_HOME"
Write-Host ''
& "$PSScriptRoot\install-prebuilt.ps1"
Write-Host ''
Write-Host 'Next: portable\build.ps1'
