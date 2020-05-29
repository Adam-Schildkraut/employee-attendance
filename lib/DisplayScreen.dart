import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

import 'package:jiffy/jiffy.dart';

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

  String _logoURL;
  String _employeeSeatLocation;
  List<String> _employeeName;
  List _date;

  bool _isEmployeeAttendingToday;

  int _initalSlots;

  @override
  void initState() {
    getDate();
    getInitalSlots();
    getEmployeeName();
    getAttendingToday();
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

  void getInitalSlots() async {
    int initalSlots;
    await businessValue.reference.get().then((value) {initalSlots = value.data["initalSlots"];});
    setState(() {
      _initalSlots = initalSlots;
    });
  }

  void getDate() {
    DateTime now = new DateTime.now();
    setState(() {
      _date = [now.year, now.month, now.day];
    });
  }

  void getCompanyLogo(String businessID) async {
    StorageReference ref = FirebaseStorage.instance.ref().child("Logos/$businessID.png");
    String url = (await ref.getDownloadURL()).toString();
    setState(() {
      _logoURL = url;
    });
  }

  void getEmployeeName() async {
    var employeeData = await businessValue.reference.collection("employees").document(employeeNumber).get();
    setState(() {
      _employeeName = [employeeData.data["firstName"], employeeData.data["lastName"]];
    });
  }

  void getAttendingToday() async {
    String dateAsString = "";
    dateAsString += ((_date[2] < 10) ? "0" + _date[2].toString() : _date[2].toString()) + "-";
    dateAsString += ((_date[1] < 10) ? "0" + _date[1].toString() : _date[1].toString()) + "-";
    dateAsString += _date[0].toString();
    var isEmployeeAttendingToday = await businessValue.reference.collection("days").document(dateAsString).get();
    if (isEmployeeAttendingToday.exists) {
      isEmployeeAttendingToday.reference.collection("attending").getDocuments()
      .then((documents) {
        for (int i = 0; i < documents.documents.length; i++) {
          if (documents.documents[i].documentID == employeeNumber) {
            setState(() {
            _isEmployeeAttendingToday = true;
            _employeeSeatLocation = documents.documents[i].data["seat"];
          });
          return;
          }
        }
      });
      //No documents with their employee ID, not attending.
      setState(() {
        _isEmployeeAttendingToday = false;
      });
    } else {
      setState(() {
        _isEmployeeAttendingToday = false;
      });
      businessValue
      .reference
      .collection("days")
      .document(dateAsString)
      .setData({"slotsLeft" : _initalSlots})
      .then((onValue) {
        businessValue
        .reference
        .collection("days")
        .document(dateAsString)
        .collection("attending")
        .document("inital")
        .setData({"placeholder":false});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Stack(
        children: <Widget>[
          //Background
          Background(),
          //Foreground
          Column(
            children: <Widget>[
              //Header Info Widget
              Container(
                height: 200,
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(60),
                    bottomRight: Radius.circular(60),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey[500].withOpacity(0.7),
                      spreadRadius: 3,
                      blurRadius: 7,
                      offset: Offset(7, 0)
                    ),
                  ],
                ),
                child: Column(
                  children: <Widget>[
                    Container(
                      height: 200,
                      width: MediaQuery.of(context).size.width,
                      child: Stack(
                        children: <Widget>[
                          Container(
                            alignment: Alignment(-0.85, -0.3),
                            width: width,
                            child: Text(
                              Jiffy(_date).format("EEEE, do MMMM").toUpperCase(),
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontFamily: "Futura",
                                fontWeight: FontWeight.w600,
                                fontSize: 15
                              ),
                            ),
                          ),
                          Container(
                            alignment: Alignment(-0.87, -0.05),
                            width: width,
                            child: Container(
                              child: Text(
                                "Good ${(DateTime.now().hour >= 12) ? "Afternoon" : "Morning"},",
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontFamily: "Futura",
                                  fontWeight: FontWeight.w900,
                                  fontSize: 17
                                ),
                              ),
                            ),
                          ),
                          Container(
                            alignment: Alignment(0.18, -0.05),
                            width: width,
                            child: (_employeeName != null) ? Text(
                              "${_employeeName[0]} ${_employeeName[1]} !",
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontFamily: "Futura",
                                fontWeight: FontWeight.w900,
                                fontSize: 17
                              ),
                            ) : Container(),
                          ),
                          Container(
                            alignment: Alignment(-0.87, 0.45),
                            width: width,
                            child: Text(
                              "You Are: ",
                              style: TextStyle(
                                color: Colors.grey[800],
                                fontFamily: "FuturaBold",
                                fontSize: 17,
                                height: 1.1,
                              )
                            ),
                          ),
                          Container(
                            alignment: (_isEmployeeAttendingToday) ? Alignment(0.25, 0.48) : Alignment(0.1, 0.75),
                            width: width,
                            child: (_isEmployeeAttendingToday != null) ? Text(
                              "${(_isEmployeeAttendingToday) ? "" : "Not "} Going Into The Office Today.",
                              style: TextStyle(
                                color: (_isEmployeeAttendingToday) ? Color.fromRGBO(247, 185, 123, 1) : Color.fromRGBO(255, 114, 140, 1),
                                fontFamily: "Futura",
                                fontWeight: FontWeight.w700,
                                fontSize: 17,
                              ),
                            ) : Container(),
                          ),
                          Container(
                            alignment: Alignment(-0.68, 0.8),
                            width: width,
                            child: (_isEmployeeAttendingToday == true) ? Text(
                              "Seat: ",
                              style: TextStyle(
                                color: Colors.grey[800],
                                fontFamily: "FuturaBold",
                                fontSize: 17,
                                height: 1.1,
                              )
                            ) : Container(),
                          ),
                          Container(
                            alignment: Alignment(-0.42, 0.81),
                            width: width,
                            child: (_isEmployeeAttendingToday == true) ? Text(
                              "$_employeeSeatLocation",
                              style: TextStyle(
                                color: (_isEmployeeAttendingToday) ? Color.fromRGBO(247, 185, 123, 1) : Color.fromRGBO(255, 114, 140, 1),
                                fontFamily: "Futura",
                                fontWeight: FontWeight.w700,
                                fontSize: 17
                              ),
                            ) : Container(),
                          ),
                          Align(
                            alignment: Alignment(0.97, -0.12),
                            child: Container(
                              width: 75,
                              height: 75,
                              decoration: BoxDecoration(
                                color: Colors.grey[800],
                                shape: BoxShape.circle,
                              ),
                              child: Container(
                                child: Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 50,
                                ),
                              ),
                            ),
                          ),
                        ]
                      ),
                    ),
                  ],
                ),
              ),
              //Attending Title Widget
              Align(
                alignment: Alignment(-1, 0),
                child: Container(
                  transform: Matrix4.translationValues(-60, 0, 0),
                  alignment: Alignment(0, 0),
                  width: 250,
                  height: 50,
                  margin: EdgeInsets.only(top: 20),
                  padding: EdgeInsets.only(left: 50),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 7,
                        spreadRadius: 5,
                        color: Colors.grey[400].withOpacity(0.5),
                        offset: Offset(-5, 3)
                      )
                    ]
                  ),
                  child: Text(
                    "You Are Attending",
                    style: TextStyle(
                      fontFamily: "FuturaBold",
                      fontWeight: FontWeight.w400,
                      fontSize: 15,
                      color: Colors.grey[800]
                    ),
                  ),
                ),
              ),
              //Attending Card List Widget
              Container(
                margin: EdgeInsets.only(top: 15),
                height: 200,
                width: width - 20,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        blurRadius: 7,
                        spreadRadius: 5,
                        color: Colors.grey[400].withOpacity(0.5),
                        offset: Offset(0, 3)
                      ),
                  ],
                ),
                //TODO: Attendance List Here
                child: Container(
                  margin: EdgeInsets.only(top: 20, bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.red,
                  ),
                  child: ListView(
                    
                  )
                ),
              ),
              //Calendar List Widget
              Align(
                alignment: Alignment(1, 0),
                child: Container(
                  transform: Matrix4.translationValues(90, 0, 0),
                  alignment: Alignment(0, 0),
                  width: 250,
                  height: 50,
                  margin: EdgeInsets.only(top: 15),
                  padding: EdgeInsets.only(right: 80),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 7,
                        spreadRadius: 5,
                        color: Colors.grey[400].withOpacity(0.5),
                        offset: Offset(5, 3)
                      )
                    ]
                  ),
                  child: Text(
                    "Browse Dates",
                    style: TextStyle(
                      fontFamily: "FuturaBold",
                      fontWeight: FontWeight.w400,
                      fontSize: 15,
                      color: Colors.grey[800]
                    ),
                  ),
                ),
              ),
              //Calendar Widget
              Container(
                margin: EdgeInsets.only(top: 15),
                height: 215,
                width: width - 20,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        blurRadius: 7,
                        spreadRadius: 5,
                        color: Colors.grey[400].withOpacity(0.5),
                        offset: Offset(0, 3)
                      )
                  ]
                ),
                //TODO Calendar HERE
                child: Container(
                  margin: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class Background extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: [Color.fromRGBO(247, 185, 123, 1), Color.fromRGBO(255, 114, 140, 1)]
        ),
      ),
      child: Stack(
        children: <Widget>[
          Transform.scale(
            scale: 5,
            child: Container(
              transform: Matrix4.translationValues(-20, 55, 0),
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1)
              ),
            ),
          ),
          Transform.scale(
            scale: 5,
            child: Container(
              transform: Matrix4.translationValues(-35, 70, 0),
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1)
              ),
            ),
          ),
          Transform.scale(
            scale: 5,
            child: Container(
              transform: Matrix4.translationValues(30, 150, 0),
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1)
              ),
            ),
          ),
        ],
      )
    );
  }
}