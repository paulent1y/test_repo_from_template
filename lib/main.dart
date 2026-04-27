import 'package:flutter/material.dart';

import 'logging/app_log.dart';
import 'roguelite/roguelite_controller.dart';
import 'roguelite/roguelite_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppLog.init();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final RogueliteController _controller = RogueliteController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '2048 Roguelite',
      debugShowCheckedModeBanner: false,
      navigatorObservers: [appLog.observer],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF8F7A66)),
        useMaterial3: true,
      ),
      home: RogueliteScreen(controller: _controller),
    );
  }
}
