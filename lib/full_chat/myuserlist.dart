import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import 'GroupChat.dart';
import 'MyProvider.dart';

import 'MyuserModal.dart';
import 'Splash_page.dart';
import 'chatscreen.dart';

class MyUserList extends StatefulWidget {
  const MyUserList({super.key});

  @override
  State<MyUserList> createState() => _MyUserListState();
}

class _MyUserListState extends State<MyUserList> {



  List<MyUserModal> users=[];

  @override
  void initState() {

    super.initState();
    getUserList();
  }


  @override
  Widget build(BuildContext context) {
    return _mainBody();
  }



  void getUserList()async{


    FirebaseFirestore.instance.collection("myusers").get().then((value) {


      List<DocumentSnapshot> docs=value.docs;

      users.clear();


     MyUserModal currentUser=Provider.of<MyProvider>(context,listen: false).usermodal!;

      print("current user : ${currentUser.uid}");

      for(int i=0;i<docs.length;i++)
      {

        Map<dynamic,dynamic> data=docs[i].data() as Map;


        MyUserModal modal=MyUserModal(name: data["name"], email: data["email"], imgurl:data["imgurl"], status: data["status"], uid: data["uid"]);

        if(modal.uid!=Provider.of<MyProvider>(context,listen: false).usermodal!.uid) {
          users.add(modal);
        }
      }


      setState(() {

      });




    });



  }


  Future<void> doLogout()async{
    try {

      await GoogleSignIn().disconnect();
      await FirebaseAuth.instance.signOut();

      Navigator.push(context, MaterialPageRoute(builder: (ctx) => MySplashScreen()));



    } catch (e) {

      print("Error : $e");
    }
  }


  Widget myListView(){
    return ListView.builder(

        itemCount: users.length,
        itemBuilder: (ctx,index){

          return userItem(users[index]);


        });
  }

  Widget userItem(MyUserModal user)
  {
    return InkWell(
      onTap: (){
        Navigator.push(context, MaterialPageRoute(builder: (ctx) => MyChatPage()));

      },
      child: Container(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              width: double.maxFinite,
              child:Row(
                children: [
                  Container(
                    height: 70,
                    width: 70,
                    child: ClipOval(
                      child: Image.network(user.imgurl),
                    ),
                  ),
                  SizedBox(width: 20,),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.name,style: TextStyle(fontWeight: FontWeight.w600,fontSize: 20),),
                      Text(user.status,style: TextStyle(fontWeight: FontWeight.w500,fontSize: 14),),
                    ],
                  )
                ],
              ),
            ),
            Container(width: double.maxFinite,height: 1,color: Colors.grey,),
          ],
        ),
      ),
    );
  }

  Widget _mainBody() {
    return SafeArea(
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.blue,
            leading: Icon(Icons.wechat),
            title:  Shimmer.fromColors(
              baseColor: Colors.white,
              highlightColor: Colors.grey,
              child: SizedBox(
                width: 100,
                height: 30,
                child: Text(
                  "Chat Room",
                  style: TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            actions: [InkWell(onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (ctx) => MyChatPage()));

            }, child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Icon(Icons.group),
            )),
              InkWell(onTap: () {

                doLogout();

              }, child: Padding(
                padding: const EdgeInsets.only(right: 20),
                child: Icon(Icons.logout),
              ))
            ],
          ),
          body: Container(
              child: Column(
                children: [

                  Expanded(child: myListView())

                ],
              )),
        ));
  }
}
