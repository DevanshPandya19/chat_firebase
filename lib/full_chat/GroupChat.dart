import 'dart:collection';
import 'dart:io';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_firebase/full_chat/MyProvider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

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
  bool _showEmoji = false;
  String laststatus="online";
  String?  downloadUrl;
  File?  ImgFile;
  String Imagelabel="";

  Future<void> getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      double latitude = position.latitude;
      double longitude = position.longitude;

      String mapUrl =
          'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';

      if (await canLaunchUrl(Uri.parse(mapUrl))) {
        await launchUrl(Uri.parse(mapUrl));
      } else {
        throw 'Could not launch $mapUrl';
      }
    } catch (e) {
      print('Error getting location: $e');
    }
  }
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
        .isNotEmpty||ImgFile!=null) {
      Map<String, dynamic> data = new HashMap();
      data["msg"] = m;
      data["Img"]=await uploadImage();
      data["createdAt"] = FieldValue.serverTimestamp();
      data["sender"] = provider.usermodel!.uid;
      data["senderName"] = provider.usermodel!.name;
      data["senderImage"]=provider.usermodel!.imgurl;


      await firestore.collection(msgcollectionId).doc().set(data);
      txtmsg.clear();
      ImgFile=null;
      setState(() {

      });
      setStatus("online");

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
     // scrollToBottom();

      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
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
  Future<void> pickImage(BuildContext context) async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      PlatformFile platformFile = result.files.first;
      print("FileName:${platformFile.name}");
      print("FilePath:${platformFile.path}");
      ImgFile = File(platformFile.path!);
      Imagelabel = result.files.first.name;
      setState(() {});
    }
  }

  Future<String>uploadImage()async{
    if (ImgFile != null) {

      setState(() {});

      FirebaseStorage firebaseStorage = FirebaseStorage.instance;



      UploadTask uploadTask =
      firebaseStorage.ref("profile").child(Imagelabel).putFile(ImgFile!, SettableMetadata());

      TaskSnapshot taskSnapshot = await uploadTask.then((snap) => snap);

      if (taskSnapshot.state == TaskState.success) {
        print("Image uploaded successfully");
        downloadUrl = await taskSnapshot.ref.getDownloadURL();
        print("downloadUrl:$downloadUrl");

        setState(() {});
        return downloadUrl!;
      } else {
        print("can't upload");
        return "";
      }
    } else {
      print("Image null");
      return "";
    }
  }
  Future<void> uploadDocument(File documentFile, String documentName) async {
    try {
      FirebaseStorage firebaseStorage = FirebaseStorage.instance;

      UploadTask uploadTask = firebaseStorage
          .ref("documents")
          .child(documentName)
          .putFile(documentFile);

      TaskSnapshot taskSnapshot = await uploadTask.then((snap) => snap);

      if (taskSnapshot.state == TaskState.success) {
        print("Document uploaded successfully");
        String downloadUrl = await taskSnapshot.ref.getDownloadURL();
        print("Download URL: $downloadUrl");

        Map<String, dynamic> data = {
          "msg": "Document: $documentName",
          "documentUrl": downloadUrl,
          "createdAt": FieldValue.serverTimestamp(),
          "sender": provider.usermodel!.uid,
          "senderName": provider.usermodel!.name,
          "senderImage": provider.usermodel!.imgurl,
        };

        await firestore.collection(msgcollectionId).doc().set(data);
      } else {
        print("Failed to upload document");
      }
    } catch (e) {
      print("Error uploading document: $e");
    }
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
            reverse: true,
            itemBuilder: (ctx, index) {
              return myItem(mylist[index]);
            }));
  }


  Widget _chatInput() {
    return Container(
      padding: EdgeInsets.all(8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white70,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: _showEmoji
                            ? Icon(Icons.keyboard, color: Colors.grey)
                            : Icon(Icons.emoji_emotions, color: Colors.grey),
                        onPressed: () {
                          setState(() {
                            _showEmoji = !_showEmoji;
                          });
                        },
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: txtmsg,
                          onChanged: (text) {
                            setState(() {});
                          },
                          decoration: InputDecoration.collapsed(
                            hintText: 'Type a message...',
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.attach_file, color: Colors.grey),
                        onPressed: () {
                          _showAttachmentOptions(context);
                        },
                      ),
                      SizedBox(width: 6),
                      Icon(Icons.camera_alt, color: Colors.grey),

                    ],
                  ),
                ),
              ),
              
              SizedBox(width: 8),
              if (!_showEmoji &&
                  (txtmsg.text.trim().isNotEmpty || ImgFile != null))
                InkWell(
                  onTap: () {
                    if (txtmsg.text.trim().isNotEmpty || ImgFile != null) {
                      sentMsg();
                    }
                  },

                  child: Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.send,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              if (!_showEmoji && txtmsg.text.trim().isEmpty && ImgFile == null)
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: InkWell(
                    child: Icon(Icons.mic, color: Colors.white),
                  ),
                ),
            ],
          ),
          Offstage(
            offstage: !_showEmoji,
            child: SizedBox(
              height: 300,
              child: EmojiPicker(
                textEditingController: txtmsg,
                config: Config(),
              ),
            ),
          ),
        ],
      ),
    );
  }
  void _showAttachmentOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.location_on),
                title: Text('Location'),
                onTap: () {
                  getCurrentLocation();
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.insert_drive_file),
                title: Text('Document'),
                onTap: () async {
                  final FilePickerResult? result =
                  await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['pdf'],
                    allowMultiple: false,
                  );

                  if (result != null && result.files.isNotEmpty) {
                    PlatformFile platformFile = result.files.first;
                    print("FileName: ${platformFile.name}");
                    print("FilePath: ${platformFile.path}");
                    File pdfFile = File(platformFile.path!);
                    await uploadDocument(pdfFile, platformFile.name!);
                  }
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.image),
                title: Text('Photos'),
                onTap: () {
                  pickImage(context);
                  //Navigator.pop(context);
                },
              ),

            ],
          ),
        );
      },
    );
  }











  Widget myItem(Map<String, dynamic> map) {
    DateTime? dateTime = map['createdAt'] != null
        ? (map['createdAt'] as Timestamp).toDate()
        : null;
    String formattedTime = dateTime != null
        ? _formatTime(dateTime)
        : '';

    String senderImage = map['senderImage'] ?? '';
    String messageImage = map['Img'] ?? '';



    return Container(
      margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        // color: map['sender'] != provider.usermodel!.uid ? Colors.blue : Colors.grey, // Change the color based on sender
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
              child: ClipOval(child: Image.network(senderImage)),
            ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: map['sender'] == provider.usermodel!.uid
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(bottom: 4), // Adjust the bottom padding of the sender name
                  child: Text(
                    map["senderName"] ?? '', // Provide a default value if senderName is null
                    style: TextStyle(fontSize: 14, color: Colors.black,fontWeight: FontWeight.bold),
                  ),
                ),
                if(messageImage.isNotEmpty) CachedNetworkImage(
                  imageUrl: messageImage,
                ),
                Container(
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: map['sender'] != provider.usermodel!.uid ? Colors.grey.shade300 : Colors.blue.shade200, // Change the color based on sender
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        map["msg"] ?? '',
                        style: TextStyle(fontSize: 14, color: Colors.black),
                      ),

                      Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                          formattedTime,
                          style: TextStyle(fontSize: 10, color: Colors.black,),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (map['sender'] == provider.usermodel!.uid)
            Container(
              margin: EdgeInsets.only(left: 10),
              width: 30,
              height: 30,
              child: ClipOval(child: Image.network(provider.usermodel!.imgurl)),
            )
        ],
      ),
    );
  }
  String _formatTime(DateTime dateTime) {
    DateTime now = DateTime.now();
    Duration difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return 'last sent ${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return 'last sent ${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return 'last sent ${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
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
