import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/verify_otp_screen.dart';
import 'screens/auth/forgot_email_screen.dart';
import 'screens/home_screen.dart';
import 'screens/groups_screen.dart';
import 'screens/group_details_screen.dart';
import 'screens/create_group_screen.dart';
import 'screens/add_expense_screen.dart';
import 'screens/settings_screen.dart';
import 'app_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: appThemeMode,
      builder: (context, mode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'SettleUp',
          theme: ThemeData(
            primarySwatch: Colors.deepPurple,
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primarySwatch: Colors.deepPurple,
          ),
          themeMode: mode,
          initialRoute: '/',
          routes: {
            '/': (_) => const SplashScreen(),
            '/login': (_) => const LoginScreen(),
            '/signup': (_) => const SignupScreen(),
            '/verify-otp': (_) => const VerifyOtpScreen(),
            '/forgot-email': (_) => const ForgotPasswordEmailScreen(),
            '/home': (_) => const HomeScreen(),
            '/groups': (_) => const GroupsScreen(),
            '/group-details': (_) => const GroupDetailsScreen(),
            '/create-group': (_) => const CreateGroupScreen(),
            '/add-expense': (_) => const AddExpenseScreen(),
            '/settings': (_) => const SettingsScreen(),
          },
        );
      },
    );
  }
}
