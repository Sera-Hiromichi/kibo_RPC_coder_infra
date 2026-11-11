---
display_name: Int-Ball2 ROS Noetic
description: ROS Noetic development workspace with persistent home
icon: /icon/docker.svg
tags: [docker, ros, python]
---

# Int-Ball2 開発用Workspace

ベースは `ros:noetic`。Python 3、pip、venv、Python開発ヘッダー、Git、
GCC/G++、make、CMake、catkin、NumPy、rospkgと、付属サンプルが使うROSパッケージを導入する。
`ib2_msgs`、`platform_msgs`、`sample_tests`は `/opt/intball2_ws` に配置してビルド済み。
Gazebo・RViz・GSEは共通シミュレータ側で起動する。

## イメージの作成

`kibo-coder`リポジトリのルートで実行する。公式ソースはDockerビルド中に
`workspace-image/fetch-official-sources.sh`で取得するため、別途cloneする必要はない。
取得元は `https://github.com/jaxa/int-ball2_platform_works.git`、固定コミットは
`b24d13496f3dd2ac739070667d81e23eff1056cf`。取得にはインターネット接続が必要。
更新時は取得スクリプトのコミットを変更し、ビルドとimport確認を実施する。

```bash
docker compose -f workspace-image/compose.yaml --profile build build
```

このComposeはイメージ作成用。Workspaceの起動はCoderがTerraformで行う。
Coderサーバーと同じDocker Engineに `intball2-workspace:noetic-v1` を作成する。
Dockerfileを変更した場合はタグを更新し、main.tfのimageも合わせる。

```bash
cd templates/docker-workspace
terraform validate
coder templates push docker --directory .
```

既存WorkspaceへはCoderでテンプレート更新を適用する。
AgentはCoderから起動し、code-serverは既存のCoderモジュールで導入・起動する。
エディタの開始フォルダは `/home/coder/projects`。

## ユーザー領域の永続化

ホーム `/home/coder` は `coder-<workspace-id>-home` という固有のDocker Volumeへ保存する。
停止中もVolumeを維持し、同じWorkspaceの再開・テンプレート更新時に再利用する。
Workspace削除ではVolumeも削除対象になるため、事前にバックアップする。

追加のPythonライブラリはホーム内の仮想環境へ導入する。
ROS・NumPyなどapt導入済みのライブラリを参照するには次のようにする。

```bash
python3 -m venv --system-site-packages ~/venvs/rcjp
source ~/venvs/rcjp/bin/activate
python -m pip install <package>
python -m pip freeze > ~/projects/requirements.txt
```

`sudo apt-get install` も可能だが、ホーム外への変更はコンテナ再作成で失われる。
ユーザー固有のapt依存はホームに再導入スクリプトを保存し、必要時に再実行する。
全員に必要になった依存は共通Dockerfileへ追加する。

## サンプルの確認

```bash
source /opt/intball2_ws/devel/setup.bash
rospack find sample_tests
python3 -c 'import rospy, actionlib, numpy, ib2_msgs.msg, platform_msgs.msg'
```

サンプル実行時はシミュレータのROS Masterへ接続できるネットワークと
`ROS_MASTER_URI`、相互通信可能な `ROS_IP` または `ROS_HOSTNAME` の設定が必要。
このテンプレートでは共通シミュレータへ自動接続しない。
実行用イメージへの組み込みとGSEからの起動は別途行う。

## Windows側への世代バックアップ

ホームVolumeとWindows側のバックアップを分離する。
bind mountだけではファイル削除も反映されるため、停止中のホームをtar.gzとして保存する。
バックアップ先全体やDockerソケットを各Workspaceには公開しない。

1. Windows側にバックアップフォルダを作成する（例：`C:\int-ball2-backups`）。
2. Coderで対象Workspaceを停止する。
3. WSLホストで対象Volumeを確認して実行する。

```bash
docker volume ls --filter label=coder.workspace_id=<workspace-id>
bash backup-workspace.sh coder-<workspace-id>-home /mnt/c/int-ball2-backups
```

保存先は `<保存先>/<volume名>/<UTC日時>-<PID>.tar.gz`。
稼働中のコンテナがVolumeを利用している場合は中断する。
この処理は手動実行で、自動スケジュール・世代削除は設定していない。
CoderのPostgreSQLやホーム外のデータは対象外。

復元は元のVolumeを上書きせず、新しいVolumeで内容を確認する。

```bash
docker volume create intball2-home-restore-check
docker run --rm -i --user 0 --network none --entrypoint tar \
  --mount type=volume,source=intball2-home-restore-check,target=/restore \
  intball2-workspace:noetic-v1 -xzf - -C /restore < /mnt/c/int-ball2-backups/<volume>/<archive>.tar.gz
```

## 適用後の確認項目

- Coder Agent接続とcode-serverのブラウザ起動
- ホームへ確認用ファイルを作り、停止・再開・テンプレート更新後も残ること
- 2ユーザーのWorkspaceでホームVolumeが異なり、一方の停止が他方へ影響しないこと
- 指定したWindows保存先へのバックアップと別Volumeへの復元
- シミュレータへ登録した実行用イメージからのサンプル動作
