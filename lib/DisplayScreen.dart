import 'package:employee_attendance/Animation/FadeAnimation.dart';
import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

import 'dart:async';

class DisplayScreen extends StatefulWidget {
  final businessValue;
  final employeeNumber;

  DisplayScreen({Key key, @required this.businessValue, @required this.employeeNumber}) : super(key: key);
  
  @override
  _DisplayState createState() => _DisplayState(businessValue: businessValue, employeeNumber: employeeNumber);
}

class _DisplayState extends State<DisplayScreen> with TickerProviderStateMixin{
  final businessValue;
  final employeeNumber;
  _DisplayState({@required this.businessValue, @required this.employeeNumber});

  @override
  void initState() {
    // print("---------- EMPLOYEE: $employeeNumber ----------");
    // print("First Name: ${employeeData.data["firstName"]}");
    // print("First Name: ${employeeData.data["lastName"]}");

    // var attendanceData = await value.reference.collection("days").getDocuments();

    // for (int i = 0; i < attendanceData.documents.length; i++) {
    //   print("Date: ${attendanceData.documents[i].documentID}");
    //   var dateData = await attendanceData.documents[i].reference.collection("attendees").getDocuments();
    //   print("Slots Left: ${attendanceData.documents[i].data["initalSlots"] - dateData.documents.length}");
    //   for (int i = 0; i < dateData.documents.length; i++) {
    //     print("Employee: ${dateData.documents[i].documentID}");
    //     print("Confirmed: ${(dateData.documents[i].data["confirmed"]) ? "Yes" : "No"}");
    //   }
    // }
    super.initState();
  }

  Future getEmployeeName(businessValue, employeeNumber) async {
    var employeeData = await businessValue.reference.collection("employees").document(employeeNumber).get();
    return [employeeData.data["firstName"], employeeData.data["lastName"]];
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Column(
        children: <Widget>[
          FutureBuilder(
            future: getEmployeeName(businessValue, employeeNumber),
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              if (!snapshot.hasData) {
                return Center(
                  child: CircularProgressIndicator()
                );
              } else {
                return Column(
                  children: <Widget>[
                    SizedBox(height: 100),
                    Text("Welcome:"),
                    SizedBox(height: 10),
                    Text(snapshot.data[0]),
                    Text(snapshot.data[1]),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }
}