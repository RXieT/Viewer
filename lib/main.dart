import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'providers/bookmark_provider.dart';
import 'services/storage_service.dart';
import 'services/tag_service.dart';
import 'screens/main_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storageService = StorageService();
  await storageService.init();

  // Initialize in-memory EhViewer-style bilingual tag dictionary
  final tagService = TagService();
  await tagService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AppProvider(storageService: storageService),
        ),
        ChangeNotifierProvider(
          create: (_) => BookmarkProvider(storageService: storageService),
        ),
      ],
      child: const KemonoViewerApp(),
    ),
  );
}

class KemonoViewerApp extends StatelessWidget {
  const KemonoViewerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();

    return MaterialApp(
      title: 'Kemono 快捷浏览',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(isAmoled: appProvider.isAmoled),
      themeMode: appProvider.themeMode,
      home: const MainScreen(),
    );
  }
}
