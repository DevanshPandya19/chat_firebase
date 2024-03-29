import 'dart:collection';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';


import '../full_chat/constantsdata.dart';


class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  //je user lakhsai ena maate
  TextEditingController txtmsg = TextEditingController();
  late FirebaseFirestore firestore;
  List<Map<String, dynamic>> mylist = [];
  bool _showEmoji=false;
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



  Future<void> sentMsg() async {
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

      await firestore.collection("chats").doc().set(data);
      txtmsg.clear();
    }
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
  void deleteMsg(String messageId) async {
    await firestore.collection("chats").doc(messageId).update({
      "deleted": true,
    });
  }


  @override
  void initState() {
    super.initState();

    firestore = FirebaseFirestore.instance;
    Future.delayed(Duration(microseconds: 500), () {
      getMsg();
    });
  }

  Widget build(BuildContext context) {
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
          CircleAvatar(
            radius: 20,
            backgroundImage: AssetImage('assests/images/my_image.png'),
          ),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                Constants.username,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                Constants.userid,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
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
                    onTap: getCurrentLocation,
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

                  Navigator.pop(context);
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