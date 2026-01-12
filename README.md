# AWS 環境変数の設定

本プロジェクトを実行するために、以下の環境変数を設定してください。

## 環境変数の設定方法

端末（ターミナル）で以下のコマンドを実行します。

```bash
export AWS_ACCESS_KEY_ID="anaccesskey"
export AWS_SECRET_ACCESS_KEY="asecretkey"
export AWS_REGION="aregion"
```

> [!CAUTION]
> `anaccesskey` と `asecretkey` は、ご自身の AWS IAM ユーザーから取得した実際の値に置き換えてください。

## 各変数の説明

- **AWS_ACCESS_KEY_ID**: AWS にアクセスするためのアクセスキー ID です。
- **AWS_SECRET_ACCESS_KEY**: AWS にアクセスするためのシークレットアクセスキーです。
- **AWS_REGION**: Terraform がリソースを作成するデフォルトのリジョンです（例: `ap-northeast-1`, `us-west-2`）。

## 設定の確認

正しく設定されたか確認するには、以下のコマンドを実行します。

```bash
env | grep AWS
```

## Ansible のバージョンについて

本プロジェクトでは Ubuntu 20.04 を使用しています。Ubuntu 20.04 のデフォルト Python は 3.8 ですが、Ansible 2.17 以降ではターゲットサーバーに Python 3.9 以上が必要になります。

そのため、以下のコマンドで ansible-core を 2.16 にダウングレードしてください。

```bash
pip install 'ansible-core>=2.16,<2.17'
```
