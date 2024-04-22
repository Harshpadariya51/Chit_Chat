import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chit_chat/login_signup_page/loginpage.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  late Future<List<Map<String, dynamic>>> _usersDataFuture;

  @override
  void initState() {
    super.initState();
    _usersDataFuture = _loadUsersData();
  }

  Future<List<Map<String, dynamic>>> _loadUsersData() async {
    List<Map<String, dynamic>> usersData = [];
    try {
      QuerySnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance.collection('users').get();

      for (var doc in snapshot.docs) {
        if (doc.exists) {
          usersData.add(doc.data());
        }
      }
    } catch (e) {
      print('Error fetching users data: $e');
    }
    return usersData;
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    } catch (e) {
      print('Logout error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logout failed. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "Chit Chat",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => _signOut(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _usersDataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
              final List<Map<String, dynamic>> usersData = snapshot.data!;
              return ListView.builder(
                itemCount: usersData.length,
                itemBuilder: (context, index) {
                  final userData = usersData[index];
                  String email = userData['email'];
                  String userName = email.split('@')[0];
                  return GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushNamed('chat');
                    },
                    child: Container(
                      height: 50,
                      margin: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(userName),
                      ),
                    ),
                  );
                },
              );
            } else {
              return const Text('No users data found.');
            }
          },
        ),
      ),
    );
  }
}
