import 'dart:collection';
import 'dart:io';
import 'package:chat_firebase/full_chat/MyUserModel.dart';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  String chatId="";

  List<Map<String, dynamic>> mylist = [];
  ScrollController _scrollController=ScrollController();
  bool _showEmoji=false;
  late FileType _fileType;
  late Reference _storageRef;
  String msgCollectionId="mypersonalchat";
  Future<String> getChatId() async {
    String otherUserId = widget.userModel.uid;
    String myUserId = FirebaseAuth.instance.currentUser!.uid;

    String AB = myUserId + otherUserId;
    String BA = otherUserId + myUserId;

    DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection(msgCollectionId)
        .doc(AB)
        .get();

    if (snapshot.exists) {
      return AB;
    } else {
      DocumentSnapshot snapshot1 = await FirebaseFirestore.instance
          .collection(msgCollectionId)
          .doc(BA)
          .get();

      if (snapshot1.exists) {
        return BA;
      } else {
        return AB;
      }
    }
  }

  void _makePhoneCall() async {
    const url = 'tel:';
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
      final String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final uploadTask = _storageRef.child('chats/$fileName').putFile(file);

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      // Ensure _fileType is set properly
      _fileType = FileType.any;

      // Call sentMsg with the file URL
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
      data["sender"] = provider.usermodel!.uid;
      data["senderName"] = provider.usermodel!.name;
      data["senderImage"]=provider.usermodel!.imgurl;
    //  data["fileType"] = fileType?.toString();

      await firestore.collection(msgCollectionId).doc().set(data);
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

  Future<void> getMsg() async{
    chatId=await getChatId();
    firestore
        .collection(msgCollectionId).orderBy("createdAt", descending: true)
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
    _scrollController = ScrollController();
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
        body: Container(
          color: Colors.white10.withOpacity(0.8),
          child: _mainBody(),
        ),
      ),
    );
  }


  Widget _mainBody() {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assests/images/background_image.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Column(
        children: [
          _appbar(),
          _msgBody(),
          _chatInput(),
        ],
      ),
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
        controller: _scrollController,
        itemCount: mylist.length,

        itemBuilder: (ctx, index) {

          if (index == 0 || !_isSameDay(mylist[index]['createdAt'], mylist[index - 1]['createdAt'])) {

            return Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildDateHeader(mylist[index]['createdAt']),
                myItem(mylist[index]),
              ],
            );
          } else {
            //
            return myItem(mylist[index]);
          }
        },
      ),
    );
  }

  Widget _buildDateHeader(Timestamp? timestamp) {
    if (timestamp == null) {
      return SizedBox();
    }

    DateTime? dateTime = timestamp != null ? timestamp.toDate() : null;
    String formattedDate = _formatDate(dateTime);
    String headerText;

    if (isToday(dateTime!)) {
      headerText = 'Today';
    } else if (isYesterday(dateTime)) {
      headerText = 'Yesterday';
    } else {
      headerText = formattedDate;
    }

    return Container(
      padding: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
      ),
      child: Text(
        headerText,
        style: TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  bool _isSameDay(Timestamp? timestamp1, Timestamp? timestamp2) {
    if (timestamp1 == null || timestamp2 == null) return false;
    DateTime date1 = timestamp1.toDate();
    DateTime date2 = timestamp2.toDate();
    return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
  }

  String _formatDate(DateTime? dateTime) {
    if (dateTime == null) return '';
    return '${dateTime.day}${_getDaySuffix(dateTime.day)} ${_getMonthName(dateTime.month)} ${dateTime.year}';
  }

  String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) {
      return 'th';
    }
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  String _getMonthName(int month) {
    switch (month) {
      case 1:
        return 'January';
      case 2:
        return 'February';
      case 3:
        return 'March';
      case 4:
        return 'April';
      case 5:
        return 'May';
      case 6:
        return 'June';
      case 7:
        return 'July';
      case 8:
        return 'August';
      case 9:
        return 'September';
      case 10:
        return 'October';
      case 11:
        return 'November';
      case 12:
        return 'December';
      default:
        return '';
    }
  }

  bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  bool isYesterday(DateTime date) {
    final now = DateTime.now();
    final yesterday = now.subtract(Duration(days: 1));
    return date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day;
  }



  Widget myItem(Map<String, dynamic> map) {
    DateTime? dateTime = map['createdAt'] != null
        ? (map['createdAt'] as Timestamp).toDate()
        : null;
    String formattedTime = dateTime != null
        ? _formatTime(dateTime)
        : '';

    String senderImage = map['senderImage'] ?? ''; // Provide a default value if senderImage is null

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
}