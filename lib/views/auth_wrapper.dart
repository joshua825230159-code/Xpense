import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xpense/viewmodels/auth_viewmodel.dart';
import 'package:xpense/views/login_screen.dart';
import 'package:xpense/views/main_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, auth, child) {
        if (auth.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (auth.isLoggedIn) {
          return const MainScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
