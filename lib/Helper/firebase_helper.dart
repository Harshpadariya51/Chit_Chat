import 'package:chit_chat/model/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirebaseHelper {
  static Future<bool> loginUser(String email, String password) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      if (userCredential.user != null) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('email', email);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  static Future<List<UserData>> loadUsersData(String currentUserEmail) async {
    try {
      final usersSnapshot =
          await FirebaseFirestore.instance.collection('users').get();
      return usersSnapshot.docs
          .where((element) => element['email'] != currentUserEmail)
          .map((e) => UserData(email: e['email'] ?? ''))
          .toList();
    } catch (e) {
      print('Error fetching users data: $e');
      return [];
    }
  }

  static Future<void> signUpUser(String email, String password) async {
    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String userId = userCredential.user!.uid;
      Timestamp timestamp = Timestamp.now();

      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'email': email,
        'createdAt': timestamp,
      });
    } catch (e) {
      print('Signup error: $e');
      rethrow;
    }
  }

  static String getChatRoom(String userEmail1, String userEmail2) {
    List<String> users = [userEmail1, userEmail2];
    users.sort();
    return '${users[0]}_${users[1]}';
  }

  static Future<UserData> getUserData(String userId) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
          .instance
          .collection('users')
          .doc(userId)
          .get();
      if (snapshot.exists) {
        Map<String, dynamic> userDataMap = snapshot.data()!;
        return UserData(
          email: userDataMap['email'] ?? '',
        );
      } else {
        print('User data not found for user ID: $userId');
        return UserData(email: '');
      }
    } catch (e) {
      print('Error fetching user data: $e');
      return UserData(email: '');
    }
  }
}

// import 'package:chit_chat/model/user_model.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// class FirebaseHelper {
//   static Future<bool> loginUser(String email, String password) async {
//     try {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       await prefs.setString('email', email);
//       QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
//           .instance
//           .collection('users')
//           .where('email', isEqualTo: email)
//           .where('password', isEqualTo: password)
//           .get();
//
//       return snapshot.docs.isNotEmpty;
//     } catch (e) {
//       print('Login error: $e');
//       return false;
//     }
//   }
//
//   static Future<List<UserData>> loadUsersData(String currentUserEmail) async {
//     // List<Map<String, dynamic>> usersData = [];
//     try {
//       final usersSnapshot =
//           // QuerySnapshot<Map<String, dynamic>> snapshot =
//           await FirebaseFirestore.instance.collection('users').get();
//
//       // for (var doc in snapshot.docs) {
//       //   if (doc.exists) {
//       //     usersData.add(doc.data());
//       //   }
//       // }
//       return usersSnapshot.docs
//           .where((element) => element['email'] != currentUserEmail)
//           .map(
//             (e) => UserData(email: e['email'] ?? ''),
//           )
//           .toList();
//     } catch (e) {
//       print('Error fetching users data: $e');
//     }
//   }
//
//   static Future<void> signUpUser(String email, String password) async {
//     try {
//       UserCredential userCredential =
//           await FirebaseAuth.instance.createUserWithEmailAndPassword(
//         email: email,
//         password: password,
//       );
//
//       String userId = userCredential.user!.uid;
//
//       Timestamp timestamp = Timestamp.now();
//
//       await FirebaseFirestore.instance.collection('users').doc(userId).set({
//         'email': email,
//         'createdAt': timestamp,
//         'password': password,
//       });
//     } catch (e) {
//       print('Signup error: $e');
//       rethrow;
//     }
//   }
//
//   static String getChatRoom(String userEmail1, String userEmail2) {
//     List<String> users = [userEmail1, userEmail2];
//     users.sort();
//     return '${users[0]}_${users[1]}';
//   }
//
//   static Future<UserData> getUserData(String userId) async {
//     try {
//       DocumentSnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
//           .instance
//           .collection('users')
//           .doc(userId)
//           .get();
//
//       if (snapshot.exists) {
//         Map<String, dynamic> userDataMap = snapshot.data()!;
//         return UserData(
//           email: userDataMap['email'] ?? '',
//         );
//       } else {
//         print('User data not found for user ID: $userId');
//         return UserData(email: '');
//       }
//     } catch (e) {
//       print('Error fetching user data: $e');
//       return UserData(email: '');
//     }
//   }
// }
