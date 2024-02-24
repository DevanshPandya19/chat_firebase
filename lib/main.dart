
import 'dart:io';

import 'package:chat_firebase/chats/chat.dart';
import 'package:chat_firebase/chats/login.dart';
import 'package:chat_firebase/full_chat/Splash_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'chats/google_login.dart';
import 'firebase_options.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';

import 'full_chat/MyProvider.dart';
import 'full_chat/chatscreen.dart';



void main()async {

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  if (Platform.isAndroid) {
    await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
  }


  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MyProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Flutter Demo1',
        theme: ThemeData(),
        home: const MySplashScreen(),
      ),
    ),
  );
}


