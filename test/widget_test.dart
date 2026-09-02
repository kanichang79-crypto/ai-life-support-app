import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:task_manager/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('タスク一覧画面が表示され、タスクを追加できる', (WidgetTester tester) async {
    await tester.pumpWidget(const TaskManagerApp());
    await tester.pumpAndSettle();

    // 初期状態ではタスクが無いことを示すメッセージが表示される
    expect(find.text('タスクがありません。右下の + から追加してください。'), findsOneWidget);

    // + ボタンからタスク追加画面へ遷移
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    // タイトルを入力して追加
    await tester.enterText(find.widgetWithText(TextFormField, 'タイトル'), '牛乳を買う');
    await tester.tap(find.text('追加する'));
    await tester.pumpAndSettle();

    // 一覧に追加したタスクが表示される
    expect(find.text('牛乳を買う'), findsOneWidget);

    // チェックを入れて完了にできる
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();

    final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
    expect(checkbox.value, isTrue);
  });
}
