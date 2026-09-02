import 'package:flutter/material.dart';

import 'screens/alarm_list_screen.dart';
import 'screens/task_list_screen.dart';
import 'screens/voice_chat_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.init();
  runApp(const TaskManagerApp());
}

class TaskManagerApp extends StatelessWidget {
  const TaskManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'タスク管理',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

/// タスク管理・アラーム・生活サポートAIをタブで切り替えるホーム画面。
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: switch (_selectedIndex) {
        0 => const TaskListScreen(),
        1 => const AlarmListScreen(),
        _ => const VoiceChatScreen(),
      },
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.checklist), label: 'タスク'),
          NavigationDestination(icon: Icon(Icons.alarm), label: 'アラーム'),
          NavigationDestination(icon: Icon(Icons.mic), label: 'AI会話'),
        ],
      ),
    );
  }
}
