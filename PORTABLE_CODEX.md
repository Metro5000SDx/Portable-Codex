# Portable Codex

This checkout is arranged so local Codex CLI development does not share mutable
state with the installed Codex Windows app.

## What Is Isolated

The helper scripts in `portable/` set these repo-local paths:

- `CODEX_HOME=.portable/codex-home`
- `CARGO_HOME=.portable/cargo`
- `RUSTUP_HOME=.portable/rustup`
- `CARGO_TARGET_DIR=.portable/target`
- `npm_config_prefix=.portable/npm`

That keeps Codex auth, sessions, plugins, logs, Rust toolchains, cargo binaries,
Node package updates, and build output inside this checkout.

The scripts also make Cargo use the Git CLI with long paths enabled for Git
dependencies, which avoids common Windows checkout failures in deep dependency
trees. On Windows, they map this checkout to `P:` when that drive letter is
free, so Cargo sees short paths while files still live in this repository.

## First Run

From the repository root:

```powershell
.\portable\setup.ps1
.\portable\codex.ps1 --version
```

That installs a local Rust toolchain and a prebuilt Codex CLI package under
`.portable/`. The prebuilt package makes the clone usable immediately. When you
have MSVC Build Tools installed, build from source with:

```powershell
.\portable\build.ps1
.\portable\codex.ps1 --version
```

To launch the local CLI:

```powershell
.\portable\codex.ps1
```

`portable\codex.ps1` prefers `.portable/target/debug/codex.exe` when you have
built from source. If that binary is not present yet, it falls back to the
prebuilt package in `.portable/npm`.

The first interactive login will write credentials under `.portable/codex-home`,
not your normal `%USERPROFILE%\.codex` app setup.

## Git Remotes

This checkout uses:

- `upstream`: `https://github.com/openai/codex.git`
- `origin`: `https://github.com/Metro5000SDx/Portable-Codex.git`

If the personal fork does not exist yet, create a GitHub fork/repository named
`Portable-Codex`, then push with:

```powershell
git push -u origin main
```

## Windows Build Note

The upstream install document recommends Windows builds via WSL2. Native Windows
builds require the MSVC C++ toolchain and Windows SDK. If `portable\build.ps1`
fails because `link.exe` or `kernel32.lib` is missing, install or repair Visual
Studio 2022 Build Tools with the C++ workload and Windows SDK, then run the
build again:

```powershell
.\portable\install-msvc-buildtools.ps1
.\portable\build.ps1
```
