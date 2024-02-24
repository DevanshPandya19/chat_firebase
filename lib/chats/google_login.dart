import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleLogin extends StatefulWidget {
  const GoogleLogin({Key? key}) : super(key: key);

  @override
  State<GoogleLogin> createState() => _GoogleLoginState();
}

class _GoogleLoginState extends State<GoogleLogin> {
  GoogleSignInAccount? account;
  User? user;

  @override
  void initState() {
    super.initState();

    user=FirebaseAuth.instance.currentUser;
    // GoogleSignIn().isSignedIn().then((isLogin) {
    //   print("Login : $isLogin");
    //   if (isLogin) {
    //     GoogleSignIn().signInSilently().then((userAccount) {
    //       account = userAccount;
    //       setState(() {});
    //     });
    //   }
    // });
  }

  @override
  Widget build(BuildContext context) {
    return _buildBody();
  }

  Future<void> doGoogleLogin() async {
    try {
      GoogleSignInAccount? signedInAccount = await GoogleSignIn().signIn();

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
      if(userCredential!=null){
        user=userCredential.user;
        setState(() {

        });
      }

    } catch (e) {
      print("Error during login: $e");
    }
  }

  Future<void> doLogout() async {
    try {
      await GoogleSignIn().disconnect();
      await FirebaseAuth.instance.signOut();
      account = null;
      setState(() {});
    } catch (e) {
      print("Error : $e");
    }
  }

  Widget _buildBody() {
    return SafeArea(
        child: Scaffold(
      body: Container(
        width: double.maxFinite,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (user != null) GoogleAvt(),
            if (user != null) logoutBtn(),
            if (user == null) loginBtn(),
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

  Widget logoutBtn() {
    return InkWell(
      onTap: () {
        doLogout();
      },
      child: Container(
        color: Colors.blue,
        padding: EdgeInsets.all(10),
        child: Text(
          "Logout",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget GoogleAvt() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipOval(
          child: Container(
              height: 100,
              width: 100,
              child: Image.network(user!.photoURL!)),
        ),
        Text(user!.displayName!),
        Text(user!.email!),
        SizedBox(
          height: 50,
        )
      ],
    );
  }
}
