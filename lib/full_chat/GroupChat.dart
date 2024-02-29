import 'dart:collection';

import 'package:chat_firebase/full_chat/MyProvider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'MyUserModel.dart';
class MyGroupChatPage extends StatefulWidget {
  const MyGroupChatPage({Key? key}) : super(key: key);

  @override
  State<MyGroupChatPage> createState() => _MyGroupChatPageState();
}

class _MyGroupChatPageState extends State<MyGroupChatPage> {

  TextEditingController txtmsg = TextEditingController();
  late FirebaseFirestore firestore;
  late MyProvider provider;
  String groupName="--";
  String groupImg="";

  List<Map<String, dynamic>> mylist = [];
  String msgcollectionId="mygroupchat";
  ScrollController _scrollController=ScrollController();


  List<MyUserModel> users=[];
  String laststatus="online";
  Future<void>getUserList()async {
    firestore.collection("myusers").orderBy("createdAt",descending: true).snapshots(includeMetadataChanges: true).listen((value) {
      List<DocumentSnapshot> docs = value.docs;
      users.clear();

      MyUserModel currentUser = Provider.of<MyProvider>(context, listen: false).usermodel!;

      print("current user : ${currentUser.uid}");

      for (int i = 0; i < docs.length; i++) {
        Map<dynamic, dynamic>? data = docs[i].data() as Map<dynamic, dynamic>?;

        if (data != null) { // Check if data is not null
          MyUserModel model = MyUserModel(
            name: data["name"] ?? "", // Use default value if data["name"] is null
            email: data["email"] ?? "",
            imgurl: data["imgurl"] ?? "",
            status: data["status"] ?? "",
            uid: data["uid"] ?? "",
          );

          // if (model.uid != currentUser.uid) {
          users.add(model);
          //}
        }
      }
      setState(() {});
    });




  }
  Future<void> sentMsg() async {
    String m = txtmsg.text;
    if (m
        .trim()
        .isNotEmpty) {
      Map<String, dynamic> data = new HashMap();
      data["msg"] = m;
      data["createdAt"] = FieldValue.serverTimestamp();
      data["sender"] = provider.usermodel!.uid;
      data["senderName"] = provider.usermodel!.name;
      data["senderImage"]=provider.usermodel!.imgurl;

      await firestore.collection(msgcollectionId).doc().set(data);
      txtmsg.clear();
      setStatus("online");
      scrollToBottom();
    }
  }
  void getGroupInfo()async {
    DocumentSnapshot snapshot=await firestore.collection("mygroups").doc(msgcollectionId).get();
    if(snapshot.exists){
      Map<String,dynamic>data=snapshot.data() as Map<String,dynamic> ;

      groupName=data["name"];
      groupImg=data["imgurl"];

      setState(() {

      });
    }


  }
  Future<void> setStatus(String status)async{
    laststatus=status;
    Map<String,dynamic>data=HashMap();
    data["status"]=status;
    data["createdAt"]=FieldValue.serverTimestamp();
    firestore.collection("myusers").doc(provider.usermodel!.uid).update(data);


  }
  void getMsg() {
    firestore
        .collection(msgcollectionId).orderBy("createdAt", descending: true)
        .snapshots(includeMetadataChanges: true)
        .listen((data) {
      mylist.clear();
      for (int i = 0; i < data.docs.length; i++) {
        QueryDocumentSnapshot d = data.docs[i];

        Map<String, dynamic> mydata = d.data() as Map<String, dynamic>;
        mylist.add(mydata);
      }
      setState(() {});
    });
  }
  void scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  void initState() {
    super.initState();

    firestore = FirebaseFirestore.instance;
    getGroupInfo();
    getUserList();
    Future.delayed(Duration(microseconds: 500), () {
      getMsg();

    });
  }
  @override




  @override
  Widget build(BuildContext context) {
    provider = Provider.of<MyProvider>(context, listen: false);

    return SafeArea(
      child: Scaffold(
        body: _mainBody(),
      ),
    );
  }

  Widget _mainBody() {
    return Column(
      children: [_appBar(),usersList(), _msgBody(), _chatInput()],
    );
  }
  Widget usersList(){
    return Container(
      height: 70,
      padding: EdgeInsets.all(5),
      width: MediaQuery.of(context).size.width,
      color: Colors.black,
      child: ListView.builder(
          itemCount: users.length,
          scrollDirection: Axis.horizontal,
          itemBuilder: (ctx,index){

            return Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50),
                        color: users[index].status=="typing"?Colors.blue: Colors.green),
                    height: 40,
                    width: 40,
                    margin: EdgeInsets.only(left: 5),
                    padding: EdgeInsets.all(2),
                    child: ClipOval(
                      child: groupImg.isEmpty?Icon(Icons.ac_unit):Image.network(
                        users[index].imgurl,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 4,
                  ),
                  Text(
                    users[index].status,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                        color: Colors.white),
                  )
                ]
            );
          }
      ),
    );
  }

  Widget _msgBody() {
    return Expanded(
        child: ListView.builder(
          controller: _scrollController,
            itemCount: mylist.length,
            itemBuilder: (ctx, index) {
              return myItem(mylist[index]);
            }));
  }

  Widget _chatInput() {
    return Column(
      children: [
        Container(
          width: double.maxFinite,
          height: 1,
          color: Colors.grey,
        ),
        Container(
          padding: EdgeInsets.only(bottom: 20, left: 15, right: 15, top: 10),
          child: Row(
            children: [
              Expanded(
                  child: TextField(
                    onChanged: (val) {

                      if(val.isEmpty){
                        if(laststatus!="online")
                          setStatus("online");
                      }
                      else{
                        if(laststatus!="typing")
                          setStatus("typing");
                      }
                    },
                    controller: txtmsg,
                  )),
              InkWell(
                onTap: () {
                  sentMsg();
                },
                child: Container(
                  height: 50,
                  width: 50,
                  child: Icon(
                    Icons.send,
                    color: Colors.white,
                  ),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      color: Colors.blueGrey),
                ),
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget myItem(Map<String, dynamic> map) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        // color: map['sender']==Constants.userid?Colors.blue:Colors.grey,
      ),
      child: Row(
        mainAxisAlignment: map['sender'] != provider.usermodel!.uid
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        children: [
          if (map['sender'] != provider.usermodel!.uid)
            Container(
                margin: EdgeInsets.only(right: 10),
                width: 30,
                height: 30,
                child: ClipOval(child: Image.network(map["senderImage"]))),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: map['sender'] == provider.usermodel!.uid
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Text(
                map["senderName"],
                style: TextStyle(fontSize: 15),
              ),
              Text(
                map["msg"],
                style: TextStyle(fontSize: 20),
              ),
            ],
          ),
          if (map['sender'] == provider.usermodel!.uid)
            Container(
                margin: EdgeInsets.only(left: 10),
                width: 30,
                height: 30,
                child:
                ClipOval(child: Image.network(provider.usermodel!.imgurl)))
        ],
      ),
    );
  }

  Widget _appBar() {
    return Container(
        padding: EdgeInsets.all(10),
        color: Colors.black,
        child: Row(
          children: [
            SizedBox(
              width: 5,
            ),
            InkWell(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                )),
            SizedBox(
              width: 15,
            ),
            Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50), color: Colors.white),
              height: 45,
              width: 45,
              padding: EdgeInsets.all(1),
              child: ClipOval(
                child: groupImg.isEmpty?Icon(Icons.ac_unit):Image.network(
                  groupImg ,
                ),
              ),
            ),
            SizedBox(
              width: 10,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  groupName,
                  style: TextStyle(fontSize: 20, color: Colors.white),
                ),
                // Text(provider.usermodel!.status,
                //  style: TextStyle(fontSize: 16, color: Colors.white))
              ],
            ),
          ],
        ));
  }
}
