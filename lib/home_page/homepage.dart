import 'package:chit_chat/Helper/firebase_helper.dart';
import 'package:chit_chat/home_page/screen/chat_page.dart';
import 'package:chit_chat/model/user_model.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chit_chat/login_signup_page/loginpage.dart';

class HomePage extends StatefulWidget {
  final String currentUserEmail;

  const HomePage({super.key, required this.currentUserEmail});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // _usersDataFuture = _loadUsersData();
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Are you sure you want to log out?',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: const Text(
            'You saved your credentials, so logging back in will be easy. You can change that setting from the login screen.',
          ),
          actions: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black12,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Log Out',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  onPressed: () async {
                    Navigator.of(context).pop(); // Close the dialog
                    try {
                      await FirebaseAuth.instance.signOut();
                      SharedPreferences prefs =
                          await SharedPreferences.getInstance();
                      await prefs.setBool('isLoggedIn', false);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const LoginPage()),
                      );
                    } catch (e) {
                      print('Logout error: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Logout failed. Please try again.')),
                      );
                    }
                  },
                ),
                TextButton(
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                        color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(),
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(
            widget.currentUserEmail,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          actions: [
            IconButton(
              onPressed: () => _showLogoutDialog(context),
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        body: Center(
          child: FutureBuilder<List<UserData>>(
            future: FirebaseHelper.loadUsersData(widget.currentUserEmail),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                final usersData = snapshot.data!;
                return ListView.builder(
                  itemCount: usersData.length,
                  itemBuilder: (context, index) {
                    final userData = usersData[index];
                    String email = userData.email;
                    String userName = email.split('@')[0];
                    final chatRoom = FirebaseHelper.getChatRoom(
                        widget.currentUserEmail, userData.email);
                    return GestureDetector(
                      onTap: () async {
                        await FirebaseHelper.createChatRoom(
                            widget.currentUserEmail, userData.email, chatRoom);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatPage(
                              chatRoom: chatRoom,
                              currentUserEmail: widget.currentUserEmail,
                              username: userName,
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Stack(
                          alignment: const Alignment(0, 1),
                          children: [
                            Container(
                              margin: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                border: const Border(
                                  top: BorderSide(color: Colors.black),
                                  left: BorderSide(color: Colors.black),
                                  right: BorderSide(color: Colors.black),
                                  bottom: BorderSide(color: Colors.black),
                                ),
                                color: Colors.blue.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              height: 50,
                            ),
                            Container(
                              height: 50,
                              decoration: BoxDecoration(
                                border: const Border(
                                  bottom: BorderSide(color: Colors.black),
                                  left: BorderSide(color: Colors.black),
                                  right: BorderSide(color: Colors.black),
                                ),
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0x90000000).withOpacity(0.1),
                                    const Color(0x90000000).withOpacity(0.1),
                                  ],
                                  stops: const [
                                    0.1,
                                    1,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(userName),
                              ),
                            ),
                          ],
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
      ),
    );
  }
}
