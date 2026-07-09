# omp-flake

Nix flake for [oh-my-pi](https://github.com/can1357/oh-my-pi) (omp) — a coding agent CLI.

Downloads prebuilt binaries from GitHub releases. The binary is a self-contained `bun build --compile` output that bundles bun and the application.

日本語版 README は [README.ja.md](README.ja.md) を参照してください。

## Supported systems

- `x86_64-linux`
- `aarch64-linux`
- `x86_64-darwin`
- `aarch64-darwin`

## Usage

### Run directly

```console
nix run github:turtton/omp-flake -- --version
```

### Install into a profile

```console
nix profile install github:turtton/omp-flake
```

### As a flake input

```nix
{
  inputs.omp.url = "github:turtton/omp-flake";

  outputs = { self, nixpkgs, omp, ... }: {
    # As a package
    # packages.x86_64-linux.default = omp.packages.x86_64-linux.default;

    # Or via the overlay
    # nixpkgs.overlays = [ omp.overlays.default ];
  };
}
```

Binary exposed:
- `omp` — the oh-my-pi coding agent CLI

## Auto-update

`.github/workflows/update.yml` runs on a daily cron. When it detects a new version on GitHub releases, it updates `hashes.json`, builds the package, and opens a pull request.

To run the update locally:

```console
bash update.sh
nix build .#omp
```

Required tools: `curl`, `jq`, `nix`.

## License

This flake (the packaging code) is provided as-is. The packaged `omp` binary is distributed under its upstream license — see the [oh-my-pi repository](https://github.com/can1357/oh-my-pi).
