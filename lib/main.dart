// main.dart (Contoh, sesuaikan dengan file Anda)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart'; // import provider
import 'screens/main_screen.dart';       // import main_screen
import 'styles/app_themes.dart';         // import tema

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Xpense App',
          theme: AppThemes.lightTheme, // Tema terang
          darkTheme: AppThemes.darkTheme, // Tema gelap
          themeMode: themeProvider.themeMode, // Mode tema saat ini
          home: const MainScreen(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}