# omp-flake — AGENTS.md

Nix flake for [oh-my-pi](https://github.com/can1357/oh-my-pi) (omp). Downloads prebuilt bun-compiled binaries from GitHub releases.

## Repo structure

| File | Purpose |
|---|---|
| `flake.nix` | Flake entrypoint — calls `package.nix` per system, exposes an overlay |
| `package.nix` | Derivation — fetches from URL in `hashes.json`, no build step |
| `hashes.json` | Version + per-system URL+SRI-hash map |
| `update.sh` | Fetches latest release from GitHub API, re-hashes, writes `hashes.json` |
| `.github/workflows/update.yml` | Daily cron: `update.sh` → build → version check → PR |

## Key commands

```bash
# Build locally (after update.sh)
nix build .#omp

# Run the built binary
./result/bin/omp --version

# Update to latest upstream release
bash update.sh
nix build .#omp
```

`update.sh --force` re-fetches hashes even if the version hasn't changed — useful for hash refresh when the same tag was re-released.

## Supported systems

`x86_64-linux`, `aarch64-linux`, `x86_64-darwin`, `aarch64-darwin`.

## Packaging quirks

- **NixOS Linux**: bun-compiled binaries hardcode `/lib64/ld-linux-x86-64.so.2`, which does not exist on NixOS. `package.nix` handles this by placing the raw binary in `libexec/` and creating a wrapper that invokes Nix's dynamic linker via `stdenv.cc.bintools.dynamicLinker`. `autoPatchelfHook` would corrupt the embedded bun payload, so it is intentionally not used.
- **macOS**: The binary is symlinked directly into `bin/` — no wrapper needed.
- **`dontFixup = true`** is set intentionally to preserve the bun-compiled binary integrity.
- **`pi` alias**: A `pi` symlink is created alongside `omp` in `$out/bin`.

## Updating

The CI workflow (`.github/workflows/update.yml`) runs daily at 06:00 UTC and can be triggered manually via workflow_dispatch. It runs `update.sh`, builds, verifies `./result/bin/omp --version` matches the version in `hashes.json`, and opens a PR on `auto-update` branch.

Version verification assertion in CI:
```bash
test "$(./result/bin/omp --version)" = "omp/$VERSION"
```

## No tests

There are no unit or integration tests. Verification is: `nix build .#omp` succeeds and the binary reports the expected version.
