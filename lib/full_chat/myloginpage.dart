import 'dart:collection';

import 'package:chat_firebase/full_chat/MyProvider.dart';
import 'package:chat_firebase/full_chat/MyuserModal.dart';
import 'package:chat_firebase/full_chat/myuserlist.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

class MyLoginPage extends StatefulWidget {
  const MyLoginPage({Key? key}) : super(key: key);

  @override
  State<MyLoginPage> createState() => _MyLoginPageState();
}

class _MyLoginPageState extends State<MyLoginPage> {
  GoogleSignInAccount? account;
  User? user;
  bool isLogin = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return _buildBody();
  }

  Future<void> doGoogleLogin() async {
    try {
      GoogleSignInAccount? signedInAccount = await GoogleSignIn().signIn();

      isLogin = true;
      setState(() {});

      if (signedInAccount != null) {
        print(" login  successfully");
        setState(() {
          account = signedInAccount; // Assign signedInAccount to account
        });
        doFirebaseLogin();
      } else {
        print("Not logged in");
      }
    } catch (e, s) {
      print("Error during login: $e");
      print(s);
    }
  }

  Future<void> doFirebaseLogin() async {
    try {
      GoogleSignInAuthentication authentication = await account!.authentication;

      FirebaseAuth auth = FirebaseAuth.instance;
      AuthCredential authCredential = GoogleAuthProvider.credential(
        accessToken: authentication.accessToken,
        idToken: authentication.idToken,
      );
      UserCredential? userCredential =
      await auth.signInWithCredential(authCredential);
      if (userCredential != null) {
        isLogin = false;
        setState(() {});
        checkAndSaveUser(userCredential.user!);
        //Navigator.push(
          //  context, MaterialPageRoute(builder: (ctx) => MyUserList()));
      }
    } catch (e) {
      isLogin = true;
      setState(() {});

      print("Error during login: $e");
    }
  }

  Future<void> checkAndSaveUser(User user) async {
    DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection("myusers")
        .doc(user.uid)
        .get();

    if (snapshot.data() == null) {
      print("New User ");

      Map<String, dynamic> userdata = HashMap();
      userdata["name"] = user.displayName;
      userdata["imgurl"] = user.photoURL;
      userdata["email"] = user.email;
      userdata["status"] = "online";
      userdata["uid"] = user.uid;
      //for putting

      MyUserModal modal = MyUserModal(
          name: user.displayName!,
          email: user.email!,
          uid: user.uid!,
          imgurl: user.photoURL!,
          status: "online");

   Provider.of<MyProvider>(context, listen: false)
          .setUserModal(modal, isRefresh: false);

      await FirebaseFirestore.instance
          .collection("myusers")
          .doc(user.uid)
          .set(userdata);
    } else {


      Map<dynamic,dynamic>data=snapshot.data() as Map;


      MyUserModal modal = MyUserModal(
        name: data["name"],
        email: data["email"],
        uid: user.uid!,
        imgurl: data["imgurl"],
        status: data["online"],
      );

     Provider.of<MyProvider>(context, listen: false)
          .setUserModal(modal, isRefresh: false);




      print("Old User ");
    }
    Navigator.push(context, MaterialPageRoute(builder: (ctx) => MyUserList()));
   // MyUserModal currentUser=Provider.of<MyProvider>(context,listen: false).usermodal!;

    //print("current user : ${currentUser.uid}");

  }

  Widget _buildBody() {
    return SafeArea(
        child: Scaffold(
          body: Container(
            width: double.maxFinite,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                isLogin
                    ? SpinKitCircle(
                  color: Colors.black,
                  size: 50,
                )
                    : loginBtn(),
              ],
            ),
          ),
        ));
  }

  Widget loginBtn() {
    return InkWell(
      onTap: () {
        doGoogleLogin();
      },
      child: Container(
        color: Colors.blue,
        padding: EdgeInsets.all(10),
        child: Text(
          "Login With Google",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

