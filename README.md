# ai-life-support-app

Flutter製のシンプルなタスク管理アプリです。

## 機能

- タスクの追加・編集・削除
- タスクの完了チェック
- 期限日の設定
- ローカル保存(端末に保存され、アプリを閉じても消えない)
- 生活サポートAI向けの音声読み上げ(Google Cloud Text-to-Speech, 日本語Neural2ボイス)の動作確認用機能

AI会話機能そのものは未実装です(今後追加予定)。

## 構成

```
lib/
  main.dart                          # エントリーポイント
  models/task.dart                   # タスクのデータモデル
  repositories/task_repository.dart  # SharedPreferences を使ったローカル保存
  screens/task_list_screen.dart      # タスク一覧画面
  screens/task_edit_screen.dart      # タスク追加・編集画面
  screens/ai_support_screen.dart     # 生活サポートAI(音声読み上げ確認)画面
  services/tts_service.dart          # Google Cloud Text-to-Speech 連携
```

データはローカル保存(`shared_preferences`)にJSON形式で保存されます。

## 実行方法

```
flutter pub get
flutter run
```

## 音声読み上げ機能(Google Cloud Text-to-Speech)

「AI音声」タブのテキストボックスにテキストを入力して「読み上げる」ボタンを押すと、
Google Cloud Text-to-Speech APIで日本語音声(`ja-JP-Neural2-B`)に変換して再生します。

利用するには [Google Cloud Text-to-Speech API](https://cloud.google.com/text-to-speech) の
APIキーが必要です。**APIキーはソースコードに直接埋め込まず、ビルド・実行時に
`--dart-define` で環境変数として渡します。**

```
flutter run --dart-define=GOOGLE_TTS_API_KEY=<あなたのAPIキー>
```

APIキーが指定されていない場合、画面上に警告が表示され、読み上げは失敗します。

### GitHub Pagesへのデプロイ時

`.github/workflows/deploy-web.yml` はリポジトリの Secrets に登録された
`GOOGLE_TTS_API_KEY` を読み込み、`flutter build web` 実行時に
`--dart-define=GOOGLE_TTS_API_KEY=...` として安全に渡します
(Secretsの値がビルド成果物のソースに直接書き込まれることはありません)。

リポジトリの Settings > Secrets and variables > Actions で
`GOOGLE_TTS_API_KEY` を登録してください。

## テスト

```
flutter test
```

## Web版のデプロイ(GitHub Pages)

`main` ブランチに push すると `.github/workflows/deploy-web.yml` が自動実行され、
Web版がビルドされて GitHub Pages に公開されます。

公開URL: `https://<ユーザー名>.github.io/ai-life-support-app/`

初回のみ、リポジトリの Settings > Pages で Source を「GitHub Actions」に設定してください。
