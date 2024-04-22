import 'package:chit_chat/home_page/screen/chat_page.dart';
import 'package:chit_chat/login_signup_page/authscreen.dart';
import 'package:chit_chat/home_page/homepage.dart';
import 'package:chit_chat/login_signup_page/loginpage.dart';
import 'package:chit_chat/login_signup_page/signup_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  String initialRoute =
      isLoggedIn ? '/' : 'auth'; // Determine initial route based on login state

  runApp(MyApp(initialRoute: initialRoute));
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({Key? key, required this.initialRoute}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: initialRoute,
      routes: {
        'auth': (context) => const AuthScreen(),
        'signup': (context) => const SignupPage(),
        'login': (context) => const LoginPage(),
        '/': (context) => const HomePage(),
        'chat': (context) => const ChatPage()
      },
    );
  }
}
