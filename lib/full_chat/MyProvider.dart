import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/cupertino.dart';


import 'MyuserModal.dart';

class MyProvider extends ChangeNotifier{



  MyUserModal? _usermodal;


  void setUserModal(MyUserModal userModal,{bool isRefresh=true})
  {
    _usermodal=userModal;

    if(isRefresh)notifyListeners();
  }



  MyUserModal? get usermodal => _usermodal;
}