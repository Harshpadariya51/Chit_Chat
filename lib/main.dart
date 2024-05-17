import 'package:chit_chat/login_signup_page/authscreen.dart';
import 'package:chit_chat/login_signup_page/loginpage.dart';
import 'package:chit_chat/login_signup_page/signup_page.dart';
import 'package:chit_chat/splash/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: 'Splash',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,
      routes: {
        'Splash': (context) => const SplashScreen(),
        'auth': (context) => const AuthScreen(),
        'signup': (context) => const SignupPage(),
        'login': (context) => const LoginPage(),
        // '/': (context) => const HomePage(),
        // 'chat': (context) => const ChatPage()
      },
    );
  }
}
