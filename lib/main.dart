import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xpense/viewmodels/auth_viewmodel.dart';
import 'package:xpense/viewmodels/main_viewmodel.dart';
import 'package:xpense/views/auth_wrapper.dart';
import 'providers/theme_provider.dart';
import 'utils/app_themes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),

        ChangeNotifierProvider(create: (_) => AuthViewModel()),

        ChangeNotifierProxyProvider<AuthViewModel, MainViewModel>(
          create: (context) => MainViewModel(
            context.read<AuthViewModel>().user?.id,
          ),
          update: (context, auth, previousViewModel) =>
          previousViewModel!..updateUser(auth.user?.id),
        ),
      ],
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
          theme: AppThemes.lightTheme,
          darkTheme: AppThemes.darkTheme,
          themeMode: themeProvider.themeMode,
          home: const AuthWrapper(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}