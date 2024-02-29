import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/cupertino.dart';

import 'MyUserModel.dart';



class MyProvider extends ChangeNotifier{



  MyUserModel? _usermodel;


  void setUserModel(MyUserModel userModel,{bool isRefresh=true})
  {
    _usermodel=userModel;

    if(isRefresh)notifyListeners();
  }



  MyUserModel? get usermodel => _usermodel;
}