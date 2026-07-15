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

## 継続的インテグレーション (CI)

`.github/workflows/ci.yml` が `main` ブランチへのプルリクエストとプッシュ時に `nix build .#omp` を実行し、バイナリのバージョンを検証します。

## 自動更新

`.github/workflows/update.yml` が日次cronで実行されます。GitHubリリースで新しいバージョンを検出すると、`hashes.json` を更新し、ビルドし、`auto-update` ブランチにプルリクエストを作成します。

ローカルで更新を実行する場合:

```console
bash update.sh
nix build .#omp
```

必要なツール: `curl`, `jq`, `nix`

### 自動更新PRでCIを実行するには

デフォルトでは、自動更新ワークフローは `GITHUB_TOKEN` を使用してPRを作成するため、CIの実行にはPRページでの手動承認が必要になります。自動更新PRでCIを自動実行するには、**Personal Access Token (PAT)** を設定してください。

1. [fine-grained PAT](https://github.com/settings/tokens) を作成:
   - リポジトリアクセス: `turtton/omp-flake` のみ
   - 権限: **Contents** (読み取り・書き込み), **Pull requests** (読み取り・書き込み)
2. リポジトリシークレットとして追加: **Settings → Secrets and variables → Actions → New repository secret**
   - 名前: `PAT_TOKEN`
   - 値: 作成したPAT

`PAT_TOKEN` を設定すると、自動更新PRでCIが自動実行されます。

**注意**: `PAT_TOKEN` が設定済みだが有効期限切れまたは失効している場合、`${{ secrets.PAT_TOKEN || secrets.GITHUB_TOKEN }}` は期限切れトークンを真（空でない文字列）と評価するため、`GITHUB_TOKEN` へのフォールバックは**行われません**。`create-pull-request` ステップが認証エラーで失敗し、PRも作成されません。回復するには: PATを更新するか、`PAT_TOKEN` シークレットを削除して `GITHUB_TOKEN` の動作に戻してください。

## ライセンス

このflake（パッケージングコード）は現状のまま提供されます。パッケージ化された `omp` バイナリはアップストリームのライセンスに従います — [oh-my-piリポジトリ](https://github.com/can1357/oh-my-pi) を参照してください。
