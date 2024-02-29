import 'dart:collection';
import 'dart:io';
import 'package:chat_firebase/full_chat/MyUserModel.dart';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'MyProvider.dart';
import 'constantsdata.dart';
class MyChatPage extends StatefulWidget {
  final MyUserModel userModel;
  const MyChatPage({required this.userModel});
  //const MyChatPage({Key? key, required MyUserModel userModel}) : super(key: key);

  @override
  State<MyChatPage> createState() => _MyChatPageState();
}

class _MyChatPageState extends State<MyChatPage> {
  //je user lakhsai ena maate
  TextEditingController txtmsg = TextEditingController();
  late FirebaseFirestore firestore;
  late MyProvider provider;

  List<Map<String, dynamic>> mylist = [];
  ScrollController _scrollController=ScrollController();
  bool _showEmoji=false;
  late FileType _fileType;
  late Reference _storageRef;

  // Storage reference for uploading files

  void _makePhoneCall() async {
    const url = 'tel:9724334152';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw 'Could not launch $url';
    }
  }

  Future<void> getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      double latitude = position.latitude;
      double longitude = position.longitude;

      String mapUrl = 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';

      if (await canLaunchUrl(Uri.parse(mapUrl))) {
        await launchUrl(Uri.parse(mapUrl));
      } else {
        throw 'Could not launch $mapUrl';
      }
    } catch (e) {
      print('Error getting location: $e');
    }
  }
  Future<void> _openFilePicker(BuildContext context) async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any, // Allow selection of any file type
      );

      if (result != null) {
        final PlatformFile file = result.files.single;
        if (file.path != null) {
          await _handleFileSelection(File(file.path!));
        } else {
          print('Error: File not found.');
        }
      } else {
        // User canceled the picker
      }
    } catch (e) {
      print('Error picking file: $e');
    }
  }
  Future<void> _handleFileSelection(File file) async {
    try {
      final String fileName = DateTime
          .now()
          .millisecondsSinceEpoch
          .toString();
      final uploadTask = _storageRef.child('chats/$fileName').putFile(file);

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();


      sentMsg(msg: downloadUrl, fileType: _fileType);
    } catch (e) {
      print('Error uploading file: $e');
    }
  }

  Future<void> sentMsg({String? msg, FileType? fileType}) async {
    String m = txtmsg.text;
    if (m
        .trim()
        .isNotEmpty) {
      Map<String, dynamic> data = new HashMap();
      data["msg"] = m;
      data["createdAt"] = FieldValue.serverTimestamp();
      data["sender"] = Constants.userid;
      data["senderName"] = Constants.username;
      data["deleted"] = false;
      data["fileType"] = fileType?.toString();

      await firestore.collection("chats").doc().set(data);
      txtmsg.clear();
      scrollToBottom();

    }
  }
  void scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void getMsg() {
    firestore
        .collection("chats").orderBy("createdAt", descending: true)
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



  @override
  void initState() {
    super.initState();
    _fileType = FileType.any;
    _storageRef = FirebaseStorage.instance.ref();

    firestore = FirebaseFirestore.instance;
    Future.delayed(Duration(microseconds: 500), () {
      getMsg();
    });
  }

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
      children: [
        _appbar(),
        _msgBody(),
        _chatInput(),
      ],
    );
  }

  Widget _appbar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Color(0xFF075E54),
      child: Row(
        children: [
          InkWell(
            onTap: () {
              if (_showEmoji) {
                setState(() {
                  _showEmoji = false;
                });
              } else {
                Navigator.of(context).pop();
              }
            },
            child: Icon(
              Icons.arrow_back_ios,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 16),
          ClipOval(
            child: CircleAvatar(
              radius: 20,
              child: Image.network(
                widget.userModel.imgurl,
              ),
            ),
          ),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.userModel.name,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

            ],
          ),
          Spacer(),
          Spacer(),
          Spacer(),
          Spacer(),
          IconButton(
            icon: Icon(Icons.phone_callback_rounded, color: Colors.white),
            onPressed: () {
              _makePhoneCall();
            },
          ),
          Spacer(),
          Icon(Icons.more_vert, color: Colors.white),
        ],
      ),
    );
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
                    color: Colors.white,
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
                      SizedBox(width: 8),
                      Icon(Icons.camera_alt, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 8),
              if (!_showEmoji && txtmsg.text.trim().isNotEmpty)
                InkWell(
                  onTap: () {
                    if (txtmsg.text.trim().isNotEmpty) {
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
              if (!_showEmoji && txtmsg.text.trim().isEmpty)
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
                leading: Icon(Icons.contact_phone),
                title: Text('Contact'),
                onTap: () {

                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.insert_drive_file),
                title: Text('Document'),
                onTap: () {
                  _openFilePicker(context);
                  //Navigator.pop(context);
                },
              ),

            ],
          ),
        );
      },
    );
  }

  Widget _msgBody() {
    return Expanded(
      child: ListView.builder(
        itemCount: mylist.length,
        itemBuilder: (ctx, index) {
          return myItem(mylist[index]);
        },
      ),
    );
  }

  Widget myItem(Map<String, dynamic> map) {
    DateTime? dateTime = map['createdAt'] != null
        ? (map['createdAt'] as Timestamp).toDate()
        : null;
    String formattedTime = dateTime != null
        ? _formatTime(dateTime)
        : '';

    return Container(
      margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: map['sender'] == Constants.userid
                  ? Colors.blue
                  : Colors.grey,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  map["senderName"].toString(),
                  style: TextStyle(
                    fontSize: 14,
                    color: map['sender'] == Constants.userid
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  map["msg"].toString(),
                  style: TextStyle(
                    fontSize: 16,
                    color: map['sender'] == Constants.userid
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 5),
          Text(
            formattedTime,
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
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
}