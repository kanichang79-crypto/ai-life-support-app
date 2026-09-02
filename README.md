# ai-life-support-app

Flutter製のシンプルなタスク管理アプリです。

## 機能

- タスクの追加・編集・削除
- タスクの完了チェック
- 期限日の設定
- ローカル保存(端末に保存され、アプリを閉じても消えない)

音声機能・AI会話機能は未実装です(今後追加予定)。

## 構成

```
lib/
  main.dart                     # エントリーポイント
  models/task.dart              # タスクのデータモデル
  repositories/task_repository.dart  # SharedPreferences を使ったローカル保存
  screens/task_list_screen.dart # タスク一覧画面
  screens/task_edit_screen.dart # タスク追加・編集画面
```

データはローカル保存(`shared_preferences`)にJSON形式で保存されます。

## 実行方法

```
flutter pub get
flutter run
```

## テスト

```
flutter test
```

## Web版のデプロイ(GitHub Pages)

`main` ブランチに push すると `.github/workflows/deploy-web.yml` が自動実行され、
Web版がビルドされて GitHub Pages に公開されます。

公開URL: `https://<ユーザー名>.github.io/ai-life-support-app/`

初回のみ、リポジトリの Settings > Pages で Source を「GitHub Actions」に設定してください。
