import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

import 'GroupChat.dart';
import 'MyProvider.dart';
import 'MyUserModel.dart';
import 'Splash_page.dart';
import 'chatscreen.dart';

class MyUserList extends StatefulWidget {
  const MyUserList({super.key});

  @override
  State<MyUserList> createState() => _MyUserListState();
}

class _MyUserListState extends State<MyUserList> {
  List<MyUserModel> users = [];

  @override
  void initState() {
    super.initState();
    getUserList();
  }

  @override
  Widget build(BuildContext context) {
    return _mainBody();
  }

  void getUserList() async {
    FirebaseFirestore.instance.collection("myusers").get().then((value) {
      List<DocumentSnapshot> docs = value.docs;
      users.clear();

      MyUserModel currentUser =
          Provider.of<MyProvider>(context, listen: false).usermodel!;

      print("current user : ${currentUser.uid}");

      for (int i = 0; i < docs.length; i++) {
        Map<dynamic, dynamic>? data = docs[i].data() as Map<dynamic, dynamic>?;

        if (data != null) {
          // Check if data is not null
          MyUserModel model = MyUserModel(
            name:
                data["name"] ?? "", // Use default value if data["name"] is null
            email: data["email"] ?? "",
            imgurl: data["imgurl"] ?? "",
            status: data["status"] ?? "",
            uid: data["uid"] ?? "",
          );

          if (model.uid != currentUser.uid) {
            users.add(model);
          }
        }
      }

      setState(() {});
    });
  }

  Future<void> updateUserStatus(String status, String uid) async {
    try {
      await FirebaseFirestore.instance.collection("myusers").doc(uid).update({
        "status": status,
      });
      print("User status updated successfully to $status");
    } catch (e) {
      print("Error updating user status: $e");
    }
  }

  Future<void> doLogout() async {
    try {

      await updateUserStatus("offline", FirebaseAuth.instance.currentUser!.uid);

      await GoogleSignIn().disconnect();
      await FirebaseAuth.instance.signOut();

      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (ctx) => MySplashScreen()));
    } catch (e) {
      print("Error : $e");
    }
  }

  Widget myListView() {
    return ListView.builder(
        itemCount: users.length,
        itemBuilder: (ctx, index) {
          return userItem(users[index]);
        });
  }



  Widget userItem(MyUserModel user) {
    return InkWell(
      onTap: () {
        Navigator.push(context,
            MaterialPageRoute(builder: (ctx) => MyChatPage(userModel: user)));
      },
      child: Container(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              width: double.maxFinite,
              child: Row(
                children: [
                  Container(
                    height: 70,
                    width: 70,
                    child: ClipOval(
                      child: Image.network(user.imgurl),
                    ),
                  ),
                  SizedBox(
                    width: 20,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 20),
                      ),
                      Text(
                        user.status == "online" ? "Online" : "Offline",
                        style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            color: user.status == "online"
                                ? Colors.green
                                : Colors.red),
                      ), // Display online or offline status
                    ],
                  )
                ],
              ),
            ),
            Container(
              width: double.maxFinite,
              height: 1,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _mainBody() {
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: InkWell(
            onTap: () {
              Navigator.pop(context);
            },
            ),
        title: Text(
          "Chat Room",
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          InkWell(
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (ctx) => MyGroupChatPage()));
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Icon(
                  Icons.groups,
                  color: Colors.white,
                ),
              )),
          InkWell(
              onTap: () {
                doLogout();
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 20),
                child: Icon(
                  Icons.logout,
                  color: Colors.white,
                ),
              ))
        ],
      ),
      body: Container(
          child: Column(
        children: [Expanded(child: myListView())],
      )),
    ));
  }
}
