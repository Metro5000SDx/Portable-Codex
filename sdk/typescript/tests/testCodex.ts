import { existsSync } from "node:fs";
import { createRequire } from "node:module";
import path from "node:path";

import { Codex } from "../src/codex";
import type { CodexConfigObject } from "../src/codexOptions";

const moduleRequire = createRequire(import.meta.url);

export const codexExecPath = process.env.CODEX_EXEC_PATH ?? resolveDefaultCodexExecPath();

type CreateTestClientOptions = {
  apiKey?: string;
  baseUrl?: string;
  config?: CodexConfigObject;
  env?: Record<string, string>;
  inheritEnv?: boolean;
};

export type TestClient = {
  cleanup: () => void;
  client: Codex;
};

export function createMockClient(url: string): TestClient {
  return createTestClient({
    config: {
      model_provider: "mock",
      model_providers: {
        mock: {
          name: "Mock provider for test",
          base_url: url,
          wire_api: "responses",
          supports_websockets: false,
        },
      },
    },
  });
}

export function createTestClient(options: CreateTestClientOptions = {}): TestClient {
  const env =
    options.inheritEnv === false ? { ...options.env } : { ...getCurrentEnv(), ...options.env };

  return {
    cleanup: () => {},
    client: new Codex({
      codexPathOverride: codexExecPath,
      baseUrl: options.baseUrl,
      apiKey: options.apiKey,
      config: mergeTestConfig(options.baseUrl, options.config),
      env,
    }),
  };
}

function mergeTestConfig(
  baseUrl: string | undefined,
  config: CodexConfigObject | undefined,
): CodexConfigObject | undefined {
  const mergedConfig: CodexConfigObject | undefined =
    !baseUrl || hasExplicitProviderConfig(config)
      ? config
      : {
          ...config,
          // Built-in providers are merged before user config, so tests need a
          // custom provider entry to force SSE against the local mock server.
          model_provider: "mock",
          model_providers: {
            mock: {
              name: "Mock provider for test",
              base_url: baseUrl,
              wire_api: "responses",
              supports_websockets: false,
            },
          },
        };
  const featureOverrides = mergedConfig?.features;

  return {
    ...mergedConfig,
    // Disable plugins in SDK integration tests so background curated-plugin
    // sync does not race temp CODEX_HOME cleanup.
    features:
      featureOverrides && typeof featureOverrides === "object" && !Array.isArray(featureOverrides)
        ? { ...featureOverrides, plugins: false }
        : { plugins: false },
  };
}

function hasExplicitProviderConfig(config: CodexConfigObject | undefined): boolean {
  return config?.model_provider !== undefined || config?.model_providers !== undefined;
}

function getCurrentEnv(): Record<string, string> {
  const env: Record<string, string> = {};

  for (const [key, value] of Object.entries(process.env)) {
    if (key === "CODEX_INTERNAL_ORIGINATOR_OVERRIDE") {
      continue;
    }
    if (value !== undefined) {
      env[key] = value;
    }
  }

  return env;
}

function resolveDefaultCodexExecPath(): string {
  const rustBinaryPath = path.join(
    process.cwd(),
    "..",
    "..",
    "codex-rs",
    "target",
    "debug",
    process.platform === "win32" ? "codex.exe" : "codex",
  );
  if (existsSync(rustBinaryPath)) {
    return rustBinaryPath;
  }

  const nativePackage = nativePackageName();
  if (nativePackage) {
    try {
      const packageJsonPath = moduleRequire.resolve(`${nativePackage.packageName}/package.json`);
      const targetTriple = nativePackage.targetTriple;
      const codexBinaryName = process.platform === "win32" ? "codex.exe" : "codex";
      return path.join(
        path.dirname(packageJsonPath),
        "vendor",
        targetTriple,
        "bin",
        codexBinaryName,
      );
    } catch {
      // Fall through to the Rust path so failures point at the expected source-built location.
    }
  }

  return rustBinaryPath;
}

type NativePackageResolution = {
  packageName: string;
  targetTriple: string;
};

function nativePackageName(): NativePackageResolution | null {
  const { platform, arch } = process;
  const target =
    platform === "win32" && arch === "x64"
      ? { packageName: "@openai/codex-win32-x64", targetTriple: "x86_64-pc-windows-msvc" }
      : platform === "win32" && arch === "arm64"
        ? { packageName: "@openai/codex-win32-arm64", targetTriple: "aarch64-pc-windows-msvc" }
        : platform === "darwin" && arch === "x64"
          ? { packageName: "@openai/codex-darwin-x64", targetTriple: "x86_64-apple-darwin" }
          : platform === "darwin" && arch === "arm64"
            ? { packageName: "@openai/codex-darwin-arm64", targetTriple: "aarch64-apple-darwin" }
            : platform === "linux" && arch === "x64"
              ? {
                  packageName: "@openai/codex-linux-x64",
                  targetTriple: "x86_64-unknown-linux-musl",
                }
              : platform === "linux" && arch === "arm64"
                ? {
                    packageName: "@openai/codex-linux-arm64",
                    targetTriple: "aarch64-unknown-linux-musl",
                  }
                : null;

  if (!target) {
    return null;
  }

  return target;
}
