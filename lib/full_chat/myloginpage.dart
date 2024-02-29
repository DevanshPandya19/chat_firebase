import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import 'MyProvider.dart';
import 'MyUserModel.dart';
import 'myuserlist.dart';

class MyLoginPage extends StatefulWidget {
  const MyLoginPage({Key? key});

  @override
  State<MyLoginPage> createState() => _MyLoginPageState();
}

class _MyLoginPageState extends State<MyLoginPage> {
  GoogleSignInAccount? account;

  bool isLogin = false;

  @override
  Widget build(BuildContext context) {
    return _buildBody();
  }

  Future<void> doGoogleLogin() async {
    try {
      account = await GoogleSignIn().signIn();

      setState(() {
        isLogin = true;
      });

      if (account != null) {
        await doFirebaseLogin();
      } else {
        setState(() {
          isLogin = false;
        });
        print("Google sign in failed");
      }
    } catch (e) {
      print("Error : $e");
      setState(() {
        isLogin = false;
      });
    }
  }

  Future<void> doFirebaseLogin() async {
    try {
      GoogleSignInAuthentication authentication =
      await account!.authentication;
      FirebaseAuth auth = FirebaseAuth.instance;

      AuthCredential authCredential = GoogleAuthProvider.credential(
        accessToken: authentication.accessToken,
        idToken: authentication.idToken,
      );

      UserCredential? userCredential =
      await auth.signInWithCredential(authCredential);

      if (userCredential != null) {
        await checkAndSaveUser(userCredential.user!);
      } else {
        setState(() {
          isLogin = false;
        });
        print("Firebase sign in failed");
      }
    } catch (e) {
      print("Error : $e");
      setState(() {
        isLogin = false;
      });
    }
  }

  Future<void> checkAndSaveUser(User user) async {
    DocumentSnapshot snapshot =
    await FirebaseFirestore.instance.collection("myusers").doc(user.uid).get();

    if (!snapshot.exists) {
      print("New user");

      Map<String, dynamic> userdata = HashMap();
      userdata["name"] = user.displayName;
      userdata["imgurl"] = user.photoURL;
      userdata["email"] = user.email;
      userdata["status"] = "online";
      userdata["uid"] = user.uid;
      userdata["createdAt"] = FieldValue.serverTimestamp();

      MyUserModel model = MyUserModel(
        name: user.displayName!,
        email: user.email!,
        imgurl: user.photoURL!,
        status: "online",
        uid: user.uid!,
      );

      Provider.of<MyProvider>(context, listen: false).setUserModel(model, isRefresh: false);

      await FirebaseFirestore.instance.collection("myusers").doc(user.uid).set(userdata);
    } else {
      print("Existing user");

      Map<dynamic, dynamic> data = snapshot.data() as Map;

      MyUserModel model = MyUserModel(
        name: data["name"],
        email: data["email"],
        imgurl: data["imgurl"],
        status: data["status"],
        uid: user.uid!,
      );

      Provider.of<MyProvider>(context, listen: false).setUserModel(model, isRefresh: false);
    }


    await updateUserStatus("online", user.uid!);


    Navigator.pushReplacement(context, MaterialPageRoute(builder: (ctx) => MyUserList()));
  }

  Future<void> updateUserStatus(String status, String uid) async {
    await FirebaseFirestore.instance.collection("myusers").doc(uid).update({
      "status": status,
    });
    print("User status updated successfully to $status");
  }


  Widget _buildBody() {
    return SafeArea(
        child: Scaffold(
          body: Container(
            width: double.maxFinite,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                isLogin?SpinKitCircle(color: Colors.orange,size: 50,): _loginBtn(),
              ],
            ),
          ),
        ));
  }

  Widget _loginBtn() {
    return InkWell(
      onTap: () {
        doGoogleLogin();
      },
      child: Container(
        color: Colors.blue,
        padding: EdgeInsets.all(10),
        child: Text(
          "Login With Google",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

