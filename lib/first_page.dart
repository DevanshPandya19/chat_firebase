import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
class FirstPage extends StatefulWidget {
  const FirstPage({Key? key}) : super(key: key);

  @override
  State<FirstPage> createState() => _FirstPageState();
}
TextEditingController txtname=TextEditingController();
TextEditingController txtsem=TextEditingController();
TextEditingController txtfield=TextEditingController();

class _FirstPageState extends State<FirstPage> {
  @override
  Widget build(BuildContext context) {
    return mainBody();
  }
  void saveData()async{
    print("Saving...");
    //data levana textfield maa thi and textfield nu badu handle controller karsai

    String nm=txtname.text;
    String sm=txtsem.text;
    String fd=txtfield.text;

    Map<String,dynamic>data=new HashMap();
    //name is key and value is nm je user nakhsai ee
    data["name"]=nm;
    data["sem"]=sm;
    data["field"]=fd;
    //data["createdAt"]=FieldValue.serverTimestamp();
    data['LastUpdateAt']=FieldValue.serverTimestamp();

    //print("Data to be saved: $data");

    // aaave firestore maa data nakhva che so firestore no object banao padsai
    FirebaseFirestore firestore=FirebaseFirestore.instance;
    await firestore.collection("students").doc("QpVhsVmSjdPJSezPLLUP").update(data);
    // await firestore.collection("students").add(data);
    print("Saved...");

  }

  Widget mainBody(){
    return SafeArea(child: Scaffold(
      body: Container(
        width: double.maxFinite,
        child: Column(children: [
          Text("Enter name"),
          TextField(controller: txtname),
          Text("Enter sem"),
          TextField(controller: txtsem),
          Text("Enter field"),
          TextField(controller: txtfield),
          SizedBox(height: 30,),

          InkWell(
            onTap: (){
              saveData();
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 40,vertical: 20),
              color: Colors.blue,
              child: Text("Add Data"),
            ),
          )
        ],),
      ),

    ));

  }
}

