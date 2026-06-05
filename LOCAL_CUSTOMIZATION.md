# Local Codex TypeScript SDK Customization

This fork is set up for local work on the TypeScript SDK in `sdk/typescript`.

## Repository Layout

- `origin`: your fork, `https://github.com/Metro5000SDx/codex.git`
- `upstream`: OpenAI's source repository, `https://github.com/openai/codex.git`
- Active setup branch: `codex/local-sdk-customization`
- SDK package: `sdk/typescript`

The checkout is sparse so day-to-day SDK work stays focused on the TypeScript SDK and the root package manager files.

## Daily Commands

From the repository root:

```powershell
pnpm install --filter @openai/codex-sdk...
pnpm --dir sdk/typescript run build
pnpm --dir sdk/typescript lint
pnpm --dir sdk/typescript test
```

The SDK package includes `@openai/codex` as a dev dependency so the integration tests can use the packaged Codex CLI without requiring a Rust toolchain or a locally built `codex-rs` binary.

## Editing The SDK

Most SDK source changes live under:

```text
sdk/typescript/src
```

The public package entrypoint is:

```text
sdk/typescript/src/index.ts
```

Use watch mode while iterating:

```powershell
pnpm --dir sdk/typescript run build:watch
```

## Using Your Local SDK In Another Project

For a quick local package artifact:

```powershell
pnpm --dir sdk/typescript pack
```

Then install the generated `.tgz` from your app.

For link-style development:

```powershell
pnpm --dir sdk/typescript link --global
```

Then, in your app:

```powershell
pnpm link --global @openai/codex-sdk
```

Keep `pnpm --dir sdk/typescript run build:watch` running while your app consumes the linked SDK.

## Syncing From OpenAI

Fetch upstream and rebase your customization branch:

```powershell
git fetch upstream
git switch codex/local-sdk-customization
git rebase upstream/main
pnpm install --filter @openai/codex-sdk...
pnpm --dir sdk/typescript test
```

Push your branch back to your fork:

```powershell
git push -u origin codex/local-sdk-customization
```
