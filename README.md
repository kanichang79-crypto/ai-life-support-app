# ai-life-support-app

Flutter製のシンプルなタスク管理アプリです。

## 機能

- タスクの追加・編集・削除
- タスクの完了チェック
- 期限日の設定
- ローカル保存(端末に保存され、アプリを閉じても消えない)
- 生活サポートAIとの音声会話(マイクで話しかける→AIが返答→音声で読み上げる)

キャラクターのカスタマイズ機能(名前・口調・性格・見た目)は未実装で、
現在は固定の1キャラクター(「ミライ」)との会話のみ行えます。

## 構成

```
lib/
  main.dart                          # エントリーポイント
  models/task.dart                   # タスクのデータモデル
  models/chat_message.dart           # AI会話画面のメッセージデータモデル
  repositories/task_repository.dart  # SharedPreferences を使ったローカル保存
  screens/task_list_screen.dart      # タスク一覧画面
  screens/task_edit_screen.dart      # タスク追加・編集画面
  screens/voice_chat_screen.dart     # 生活サポートAIとの音声会話画面
  services/tts_service.dart          # Google Cloud Text-to-Speech 連携(音声合成)
  services/stt_service.dart          # Google Cloud Speech-to-Text 連携(音声認識)
  services/ai_chat_service.dart      # Gemini API 連携(AI応答生成)
```

データはローカル保存(`shared_preferences`)にJSON形式で保存されます。

## 実行方法

```
flutter pub get
flutter run
```

## AI会話機能(音声入力→AI応答→音声出力)

「AI会話」タブのマイクボタンをタップして話しかけると、次の流れで会話が成立します。

1. **音声入力 → テキスト化**: Google Cloud Speech-to-Text APIで発話を日本語テキストに変換
2. **AI応答生成**: 変換したテキストをGemini API (Generative Language API) に送り、
   固定キャラクター「ミライ」としての返答テキストを生成
3. **テキスト → 音声出力**: Google Cloud Text-to-Speech APIで返答を日本語音声
   (`ja-JP-Neural2-B`)に変換して再生
4. やり取りはすべてチャット形式で画面にも表示されます

### なぜAI応答生成にGemini APIを使っているか

Text-to-Speech / Speech-to-Text とも同じくGoogle CloudのAPIキーで利用でき、
シンプルなHTTPリクエストだけで会話用の応答を生成できるため採用しています。
同一のGoogle Cloudプロジェクトで Generative Language API を有効化すれば
既存の `GOOGLE_TTS_API_KEY` を流用することも可能ですが、APIごとに権限を絞れるよう
本プロジェクトでは別キー(`GOOGLE_GEMINI_API_KEY`)として分けています。
(Anthropic Claude APIなど他のLLM APIに差し替えることも可能です。)

### 必要なAPIキー

利用するには次のAPIキーが必要です。**APIキーはソースコードに直接埋め込まず、
ビルド・実行時に `--dart-define` で環境変数として渡します。**

- [Google Cloud Text-to-Speech API](https://cloud.google.com/text-to-speech) /
  [Google Cloud Speech-to-Text API](https://cloud.google.com/speech-to-text) の
  APIキー: `GOOGLE_TTS_API_KEY`(両APIとも同じキーでアクセス)
- [Gemini API](https://ai.google.dev/) (Generative Language API) のAPIキー:
  `GOOGLE_GEMINI_API_KEY`

```
flutter run \
  --dart-define=GOOGLE_TTS_API_KEY=<あなたのAPIキー> \
  --dart-define=GOOGLE_GEMINI_API_KEY=<あなたのAPIキー>
```

APIキーが指定されていない場合、画面上に警告が表示され、該当する機能は失敗します。

マイクを使用するため、初回起動時にマイクの使用許可を求められます
(Android/iOS/macOSでは端末側の権限許可、Webではブラウザの許可が必要です)。

### GitHub Pagesへのデプロイ時

`.github/workflows/deploy-web.yml` はリポジトリの Secrets に登録された
`GOOGLE_TTS_API_KEY` と `GOOGLE_GEMINI_API_KEY` を読み込み、`flutter build web`
実行時に `--dart-define=...` として安全に渡します
(Secretsの値がビルド成果物のソースに直接書き込まれることはありません)。

リポジトリの Settings > Secrets and variables > Actions で
`GOOGLE_TTS_API_KEY` と `GOOGLE_GEMINI_API_KEY` を登録してください。

## テスト

```
flutter test
```

## Web版のデプロイ(GitHub Pages)

`main` ブランチに push すると `.github/workflows/deploy-web.yml` が自動実行され、
Web版がビルドされて GitHub Pages に公開されます。

公開URL: `https://<ユーザー名>.github.io/ai-life-support-app/`

初回のみ、リポジトリの Settings > Pages で Source を「GitHub Actions」に設定してください。
