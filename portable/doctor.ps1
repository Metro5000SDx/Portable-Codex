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

$kitsRoot = Join-Path ${env:ProgramFiles(x86)} 'Windows Kits\10\Lib'
$kernel32 = if (Test-Path $kitsRoot) {
    Get-ChildItem -Path $kitsRoot -Recurse -Filter kernel32.lib -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -match '\\um\\x64\\kernel32\.lib$' } |
        Select-Object -First 1
} else {
    $null
}
if ($kernel32) {
    Write-Host "Windows SDK: $($kernel32.Directory.FullName)"
} else {
    Write-Host 'Windows SDK: missing kernel32.lib'
}
Write-Host ''

if (Test-Path (Join-Path $PortableTargetDir 'debug\codex.exe')) {
    Write-Host 'Build: debug codex.exe exists'
} else {
    Write-Host 'Build: debug codex.exe not built yet'
}
