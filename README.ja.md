# omp-flake

[oh-my-pi](https://github.com/can1357/oh-my-pi) (omp) — コーディングエージェントCLIのためのNix flakeです。

GitHubリリースからプリビルドバイナリをダウンロードします。バイナリは `bun build --compile` で生成された自己完結型で、bunランタイムとアプリケーションがバンドルされています。

English README is available at [README.md](README.md).

## 対応システム

- `x86_64-linux`
- `aarch64-linux`
- `x86_64-darwin`
- `aarch64-darwin`

## 使い方

### 直接実行

```console
nix run github:turtton/omp-flake -- --version
```

### プロファイルにインストール

```console
nix profile install github:turtton/omp-flake
```

### flake入力として

```nix
{
  inputs.omp.url = "github:turtton/omp-flake";

  outputs = { self, nixpkgs, omp, ... }: {
    # パッケージとして
    # packages.x86_64-linux.default = omp.packages.x86_64-linux.default;

    # またはオーバーレイ経由で
    # nixpkgs.overlays = [ omp.overlays.default ];
  };
}
```

公開されるバイナリ:
- `omp` — oh-my-pi コーディングエージェントCLI

## 自動更新

`.github/workflows/update.yml` が日次cronで実行されます。GitHubリリースで新しいバージョンを検出すると、`hashes.json` を更新し、ビルドし、プルリクエストを作成します。

ローカルで更新を実行する場合:

```console
bash update.sh
nix build .#omp
```

必要なツール: `curl`, `jq`, `nix`

## ライセンス

このflake（パッケージングコード）は現状のまま提供されます。パッケージ化された `omp` バイナリはアップストリームのライセンスに従います — [oh-my-piリポジトリ](https://github.com/can1357/oh-my-pi) を参照してください。
