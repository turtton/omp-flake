# omp-flake — AGENTS.md

Nix flake for [oh-my-pi](https://github.com/can1357/oh-my-pi) (omp). Downloads prebuilt bun-compiled binaries from GitHub releases.

## Repo structure

| File | Purpose |
|---|---|
| `flake.nix` | Flake entrypoint — calls `package.nix` per system, exposes an overlay |
| `package.nix` | Derivation — fetches from URL in `hashes.json`, no build step |
| `hashes.json` | Version + per-system URL+SRI-hash map |
| `update.sh` | Fetches latest release from GitHub API, re-hashes, writes `hashes.json` |
| `.github/workflows/ci.yml` | PR/push CI: `nix build .#omp` — triggered on `pull_request` and `push` to `main` |
| `.github/workflows/update.yml` | Daily cron: `update.sh` → build → PR |

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

The auto-update workflow (`.github/workflows/update.yml`) runs daily at 06:00 UTC and can be triggered manually via workflow_dispatch. It runs `update.sh`, builds the derivation, and opens a PR on `auto-update` branch. Binary version verification is handled by `.github/workflows/ci.yml` (read-only `pull_request` workflow).

## CI

`.github/workflows/ci.yml` runs `nix build .#omp` on every PR targeting `main` and every push to `main`. It verifies that the derivation builds and the binary runs.

## Auto-update PR and CI

The auto-update workflow creates PRs on the `auto-update` branch. For CI to run automatically on those PRs (via the `pull_request` trigger in `ci.yml`), a **GitHub Personal Access Token (PAT)** must be configured:

1. Create a fine-grained PAT at https://github.com/settings/tokens with:
   - Repository access: `turtton/omp-flake` only
   - Permissions: **Contents** (Read and write), **Pull requests** (Read and write)
2. Add it as a repository secret: **Settings → Secrets and variables → Actions → New repository secret**
   - Name: `PAT_TOKEN`
   - Value: the PAT you created

Without `PAT_TOKEN`, the workflow falls back to `GITHUB_TOKEN`. PRs are still created, but CI runs must be approved manually on the PR page ("Approve and run").

**Important**: If `PAT_TOKEN` is set but expired or revoked, the expression `${{ secrets.PAT_TOKEN || secrets.GITHUB_TOKEN }}` evaluates the expired token as truthy (non-empty string), so the fallback to `GITHUB_TOKEN` does **not** activate. The `create-pull-request` step will fail with an authentication error. To recover:
- Renew the PAT at https://github.com/settings/tokens
- Update the repository secret with the new token
- Alternatively, delete the `PAT_TOKEN` secret to revert to `GITHUB_TOKEN` behavior

## No tests

There are no unit or integration tests. Verification is: `nix build .#omp` succeeds and the binary reports the expected version.
