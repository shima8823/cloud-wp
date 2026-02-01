## AWSアカウントの初期セットアップ

このセクションでは、AWS アカウントの作成から、STS AssumeRole による一時的な認証情報を取得するまでの全手順を説明します。
**この手順は最初に一度だけ実行します。**セットアップ完了後は、上記の通常のデプロイ手順に従ってください。

### 構成概要
```
Root アカウント
  └─ IAM User (初期設定用、AdministratorAccess を一時的に付与)
      └─ STS AssumeRole → TerraformDevRole (日常の開発作業用)
```

AWS 無料プランでは IAM Identity Center (IdC) が使用できないため、STS AssumeRole を使用して短期的な認証情報を取得する方式を採用しています。

> **注**: ベストプラクティスでは IAM ユーザーの長期的な認証情報（パスワードやアクセスキー）の使用は推奨されていませんが、無料プランの制約上、本構成では IAM ユーザーに長期パスワードを設定します。また、MFA（多要素認証）も今回は設定していません。詳細は [AWS 公式ドキュメント](https://docs.aws.amazon.com/ja_jp/IAM/latest/UserGuide/root-user-best-practices.html) を参照してください。

---

### 1. Root アカウントでの初期設定 (AWS コンソール)

**目的**: AWS のベストプラクティスに従い、Root アカウントを直接使わずに IAM ユーザーで作業できる環境を作ります。

1.  **Root でログイン**: AWS コンソールに Root ユーザーでログインします。

2.  **IAM ユーザーの作成**: 
    - IAM コンソールから、管理者権限を持つ IAM ユーザー（例: `admin-user`）を作成します。
    - このユーザーに **AdministratorAccess マネージドポリシー**を一時的にアタッチします（後で削除します）。
      - ※ AdministratorAccess は AWS が提供する管理ポリシーであり、インラインポリシーではありません。
    - **コンソールパスワードの設定**: 
      - ユーザー作成後、「セキュリティ認証情報」タブから「コンソールパスワードを有効にする」を選択します。
      - 「ユーザーは次回サインイン時に新しいパスワードを作成する必要があります」にチェックを入れます。
      - 発行されたコンソール URL を開き、ユーザー名と一時パスワードを入力して新しいパスワードを設定します。

3.  **AWS CLI での認証情報の設定**:
    ```bash
    aws login
    ```
    - 先ほど設定したIAMユーザーのコンソールパスワードを入力します。
    - regionは(例: `ap-northeast-1`)を設定します。
    - この情報は`~/.aws/`ディレクトリに保存されます。

この時点で、Root ではなく IAM ユーザーとして AWS を操作できる状態になります。

---

### 2. 基盤リソースの構築 (Terraform Bootstrap)

**目的**: Terraform の状態管理用 S3 バケットと、AssumeRole 用の各種ロールを作成します。

1.  **Bootstrap の初期化と適用**:
    ```bash
    cd infra
    make init-bootstrap
    make apply-bootstrap
    ```

2.  **作成されるリソース**:
    - **S3 Bucket**: Terraform の状態ファイル（tfstate）を保管。バージョニング有効、削除保護付き。
    - **TerraformAdminRole**: 全権限を持つロール。緊急時の復旧作業用。
    - **TerraformDevRole**: 日常の開発作業用。AdministratorAccess を持つが、ガードレール（Deny Policy）により危険な操作は禁止。
    - **インラインポリシー (自動付与)**: 現在の IAM ユーザーに `AllowAssumeTerraformAdminRole` が自動的にアタッチされ、これらのロールを引き受けられるようになります。

---

### 3. セキュリティの強化 (手動クリーンアップ)

**目的**: 初期設定で付与した強力な権限（AdministratorAccess マネージドポリシー）を削除し、AssumeRole 経由でのみ権限を行使できるようにします。

1.  **削除コマンドの確認**:
    ```bash
    make delete-iam-admin-inline-policy
    ```
    これは、削除用の AWS CLI コマンドを表示するだけです。表示されたコマンドを確認してください。

2.  **実際に削除**:
    表示されたコマンドを実行して、IAM ユーザーから AdministratorAccess マネージドポリシーをデタッチします。
    ```bash
    aws iam detach-user-policy --policy-arn arn:aws:iam::aws:policy/AdministratorAccess --user-name <YOUR_IAM_USERNAME>
    ```

この段階で、あなたの IAM ユーザーは直接的な管理者権限を持たなくなり、AssumeRole を通じてのみ作業を行えるようになります。

---

### 3.5. TerraformAdminRole への切り替え（必須）

**目的**: セクション 2 で作成した `TerraformAdminRole` を引き受け、以降の作業でこのロールの権限を使用できるようにします。

1.  **AWS コンソールでロールを切り替え**:
    - AWS コンソールにログインし、画面右上のアカウント名をクリックします。
    - 「ロールの切り替え（Switch Role）」を選択します。
    - アカウント ID とロール名（`TerraformAdminRole`）を入力して切り替えます。

2.  **AWS CLI で認証情報を保存**:
    ```bash
    aws login
    ```
    - 上記コマンドを実行すると、現在コンソールでログインしているロール（`TerraformAdminRole`）の一時的な認証情報が `~/.aws` ディレクトリに保存されます。
    - これにより、CLI からも `TerraformAdminRole` の権限で AWS 操作が可能になります。

> **注**: 他の方法（`aws sts assume-role` を直接使用するなど）もありますが、本ガイドでは上記の手順を推奨します。

---

### 4. 日常の開発フロー (get-auth-dev)

**目的**: 日々のインフラ開発では、ガードレールが適用された `TerraformDevRole` を使用します。

> **⚠️ 重要**: セクション 3.5 で `aws login` コマンドにより取得した認証情報を使用している場合、Terraform AWS Provider の既知のバグにより、一部のリソース（特に IAM 関連）の削除操作が失敗することがあります。削除操作を行う際は、以下の `eval $(make get-auth-dev)` により STS AssumeRole で取得した認証情報を使用することを推奨します。詳細は [GitHub Issue #45316](https://github.com/hashicorp/terraform-provider-aws/issues/45316) を参照してください。

1.  **ロールの引き受け (AssumeRole)**:
    ```bash
    # 環境変数に一時認証情報をセットするため eval を使用
    eval $(make get-auth-dev)
    ```
    - このコマンドは内部で `aws sts assume-role` を実行し、一時的な Access Key, Secret Key, Session Token を取得して環境変数にエクスポートします。
    - **有効期限**: Role Chaining（ロールからロールへの移行）のため、最大 **1時間** です。期限が切れたら再度実行してください。

2.  **アイデンティティの確認**:
    ```bash
    aws sts get-caller-identity
    ```
    出力の `Arn` が `arn:aws:sts::...:assumed-role/TerraformDevRole/dev-session` となっていれば成功です。

3.  **セッションのクリア（長期キーに戻る場合）**:
    ```bash
    eval $(make clear-auth)
    ```

---

### 5. 権限管理の仕組み

#### ガードレール (Deny Policy)
`TerraformDevRole` には、`iam_dev_role.tf` で定義された以下の強力な保護が適用されています：
- **ステートバケットの保護**: S3 バケットやその中のオブジェクトの削除を禁止。
- **IAM ユーザーの操作禁止**: IAM ユーザーの作成・削除、アクセスキーの発行を禁止。
- **脱獄の防止**: 自分自身（TerraformDevRole）や TerraformAdminRole の権限変更・削除を禁止。
- **ガードレール自体の保護**: ガードレールポリシーの編集・削除を禁止。

これらは **Explicit Deny（明示的な拒否）** として定義されており、たとえ AdministratorAccess を持っていても回避できません。

#### 安全な運用
- **長期キーの排除**: PC 内に永続的なアクセスキーを保存しないため、端末紛失時のリスクを最小化。
- **時間制限**: AssumeRole で取得した認証情報は最大 1 時間で自動失効。
- **監査可能**: すべての操作が CloudTrail で記録され、誰がどのロールで何をしたか追跡可能。※ここでは設定していない。
