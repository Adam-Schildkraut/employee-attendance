import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

import 'calendar/table_calendar.dart';

import 'package:jiffy/jiffy.dart';

import 'dart:async';
import 'dart:math';

class LoginScreen extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<LoginScreen> with TickerProviderStateMixin {

  final FirebaseAnalytics analytics = FirebaseAnalytics();
  final db = Firestore.instance;
  final ref = FirebaseStorage.instance;

  String _businessID = "";
  String _employeeNumber = "";
  String _businessName = "";
  String _logoURL;
  String _employeeAttendingTodayLocation;
  String _employeeSeatLocation;

  bool _enterEmployeeNumberData = false;
  bool _onMainDataScreen = false;
  bool _isEmployeeAttendingToday = false;

  int _animationLength = 300;
  int _initalSlots;

  List<String> _employeeName;
  List _date;

  var _businessValue;

  TextEditingController _textFieldController;

  CalendarController _calendarController;

  AnimationController _loginWidgetTranslationController;
  Animation _loginWidgetTranslationAnimation;

  AnimationController _businessIDTranslationController;
  AnimationController _employeeNumberTranslationController;
  Animation _businessIDTranslationAnimation;
  Animation _employeeNumberTranslationAnimation;

  AnimationController _businessIDTitleColorController;
  AnimationController _employeeNumberTitleColorController;
  Animation _businessIDTitleColorAnimation;
  Animation _employeeNumberTitleColorAnimation;

  AnimationController _textFieldColorController;
  Animation _textFieldColorAnimation;

  AnimationController _backButtonOpacityController;
  Animation _backButtonOpacityAnimation;

  AnimationController _companyLogoMarginController;
  Animation _companyLogoMarginAnimation;

  AnimationController _upButtonOpacityController;
  Animation _upButtonOpacityAnimation;

  @override
  void initState() {

    _textFieldController = TextEditingController();

    _calendarController = CalendarController();

    _textFieldColorController = AnimationController(vsync: this, duration: Duration(milliseconds: 150));
    _textFieldColorAnimation = ColorTween(begin: Colors.grey[600], end: Colors.red[500]).animate(_textFieldColorController);

    _loginWidgetTranslationController = AnimationController(vsync: this, duration: Duration(milliseconds: 750));
    _loginWidgetTranslationAnimation = Tween<double>(begin: 0, end: -650).animate(_loginWidgetTranslationController);

    _backButtonOpacityController = AnimationController(vsync: this, duration: Duration(milliseconds: _animationLength));
    _backButtonOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_backButtonOpacityController);

    _businessIDTranslationController = AnimationController(vsync: this, duration: Duration(milliseconds: _animationLength));
    _businessIDTranslationAnimation = Tween<double>(begin: 90.0, end: -130.0).animate(_businessIDTranslationController);

    _businessIDTitleColorController = AnimationController(vsync: this, duration: Duration(milliseconds: _animationLength));
    _businessIDTitleColorAnimation = ColorTween(begin: Colors.grey[600], end: Colors.grey[300]).animate(_businessIDTitleColorController);

    _employeeNumberTranslationController = AnimationController(vsync: this, duration: Duration(milliseconds: _animationLength));
    _employeeNumberTranslationAnimation = Tween<double>(begin: 30.0, end: -190.0).animate(_employeeNumberTranslationController);

    _employeeNumberTitleColorController = AnimationController(vsync: this, duration: Duration(milliseconds: _animationLength));
    _employeeNumberTitleColorAnimation = ColorTween(begin: Colors.grey[300], end: Colors.grey[600]).animate(_employeeNumberTitleColorController);

    _companyLogoMarginController = AnimationController(vsync: this, duration: Duration(milliseconds: 500));
    _companyLogoMarginAnimation = Tween<double>(begin: 0, end: 0.4).animate(_companyLogoMarginController);

    _upButtonOpacityController = AnimationController(vsync: this, duration: Duration(milliseconds: 500));
    _upButtonOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_upButtonOpacityController);

    super.initState();
  }

    void errorAnimation() {
    if (_textFieldColorController.status == AnimationStatus.completed) {
      _textFieldColorController.reverse();
    } else {
      print("Animating");
      _textFieldColorController.forward();
      Timer(Duration(seconds: 3), () {
        _textFieldColorController.reverse();
        print("Animation Reversing");
      });
    }
  }
  
  void checkBusinessID() async {
    String businessID = _textFieldController.text;

    if (businessID == "") {
      errorAnimation();
      return;
    } else {
      //Text Field has a numerical input.
      await db
      .collection("businessID")
      .document(businessID)
      .get()
      .then((value){
        if (!value.exists) {
          errorAnimation();
          return;
        } else {
          //Business Exists
          animateTitle();
          sendAnalyticsEvent("businessEvent");
          getCompanyLogo(businessID);

          _businessID = businessID;
          _businessName = value.data["businessName"];
          _textFieldController.clear();
          setState(() {
            _enterEmployeeNumberData = true;
          });
        }
      });
    }
  }

    void checkEmployeeNumber() async {
    String employeeNumber = _textFieldController.text;
    if (employeeNumber == "") {
      //errorAnimation();
      return;
    } else {
      //employeeNumber has a numerical input.
      await db
      .collection("businessID")
      .document(_businessID)
      .get()
      .then((value) async {
        var employeeData = await value.reference.collection("employees").document(employeeNumber).get();
        if (employeeData.exists) {
          //Employee exists.
          _employeeNumber = employeeNumber;
          sendAnalyticsEvent("employeeEvent");
          //Navigator.push(context,MaterialPageRoute(builder: (context) => DisplayScreen(businessValue: value, employeeNumber: employeeNumber,)));
          _loginWidgetTranslationController.forward();
          _backButtonOpacityController.reverse();
          _companyLogoMarginController.forward();
          _upButtonOpacityController.forward();
          _onMainDataScreen = true;
          _businessValue = value;

          getDate();
          getEmployeeName();
          getAttendingToday();
        } else {
          errorAnimation();
        }
      });
    }
    return;
  }

  void sendAnalyticsEvent(String event) async {
    FirebaseAnalytics analytics = FirebaseAnalytics();
    if (event == "businessEvent") {
      await analytics.logEvent(
        name: "business_accessed",
      );
    } else if (event == "employeeEvent") {
      await analytics.logEvent(
        name: "employee_login",
        parameters: <String, dynamic>{
          'business_id': _businessID,
          'employee_number': _employeeNumber,
        }
      );
    }
  }

  void getCompanyLogo(String businessID) async {
    StorageReference ref = FirebaseStorage.instance.ref().child("Logos/$businessID.png");
    String url = (await ref.getDownloadURL()).toString();
    setState(() {
      _logoURL = url;
    });
  }

  void animateTitle() {
    if (_businessIDTranslationController.status == AnimationStatus.completed) {
      _businessIDTranslationController.reverse();
      _employeeNumberTranslationController.reverse();
      _businessIDTitleColorController.reverse();
      _employeeNumberTitleColorController.reverse();
      _backButtonOpacityController.reverse();

      _enterEmployeeNumberData = false;
    } else {
      _businessIDTranslationController.forward();
      _employeeNumberTranslationController.forward();
      _businessIDTitleColorController.forward();
      _employeeNumberTitleColorController.forward();
      _backButtonOpacityController.forward();

      _enterEmployeeNumberData = true;
    }
  }

  void forgotInfoDialog() {
    Dialog forgotInformationDialog = Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      child: Container(
        height: 300.0,
        width: 300.0,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding:  EdgeInsets.all(15.0),
              child: Text(
                "Oops!",
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 25,
                  fontFamily: "Futura",
                  fontWeight: FontWeight.w300
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(15.0),
              child: Text(
                "If you have forgotten your ${(_enterEmployeeNumberData) ?"Employee Number, Please Remember It Is Identical To The Employee Number Provided To You By Your Company!" : "Business ID, Please Contact Your IT Support Department In Order To Recieve A Copy Of The 3 Digit Code!"}",
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 15,
                  fontFamily: "Futura",
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Padding(padding: EdgeInsets.only(top: 10.0)),
            MaterialButton(
              shape: UnderlineInputBorder(),
              child: Container(
                padding: EdgeInsets.only(top: 2),
                height: 20,
                width: 60,
                child: Center(
                  child: Text(
                    "Got It!",
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 18.0,
                      fontFamily: "Futura",
                        fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              onPressed: (){
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
    showDialog(barrierDismissible: false, context: context, builder: (BuildContext context) => forgotInformationDialog);
  }

  void getDate() {
    DateTime now = new DateTime.now();
    setState(() {
      _date = [now.year, now.month, now.day];
    });
  }

  String getFirebaseDate(DateTime date) {
    return "${(date.day < 10) ? "0"+date.day.toString() : date.day.toString()}"
            + "-${(date.month < 10) ? "0"+date.month.toString() : date.month.toString()}"
            + "-${date.year.toString()}";
  }

  void getEmployeeName() async {
    var employeeData = await _businessValue.reference.collection("employees").document(_employeeNumber).get();
    setState(() {
      _employeeName = [employeeData.data["firstName"], employeeData.data["lastName"]];
    });
  }

  void getAttendingToday() async {
    String dateAsString = "";
    dateAsString += ((_date[2] < 10) ? "0" + _date[2].toString() : _date[2].toString()) + "-";
    dateAsString += ((_date[1] < 10) ? "0" + _date[1].toString() : _date[1].toString()) + "-";
    dateAsString += _date[0].toString();
    var isEmployeeAttendingToday = await _businessValue.reference.collection("days").document(dateAsString).get();
    if (isEmployeeAttendingToday.exists) {
      isEmployeeAttendingToday.reference.collection("locations").getDocuments()
      .then((locationList) {
        //For each location
        for (int i = 0; i < locationList.documents.length; i++) {
          //For each attendee in the location
          isEmployeeAttendingToday.reference.collection("locations").document(locationList.documents[i].documentID).collection("attendees").getDocuments()
          .then((attendeeList) {
            for (int j = 0; j < attendeeList.documents.length; j++) {
              if (attendeeList.documents[j].documentID == _employeeNumber) {
                setState(() {
                  _isEmployeeAttendingToday = true;
                  _employeeAttendingTodayLocation = locationList.documents[i].documentID;
                  _employeeSeatLocation = locationList.documents[i].data["seat"];
                });
                return;
              }
            }
          });
        }
      });
    } else {
      setState(() {
        _isEmployeeAttendingToday = false;
      });
      _businessValue
      .reference
      .collection("days")
      .document(dateAsString)
      .then((onValue) {
        _businessValue
        .reference
        .collection("days")
        .document(dateAsString)
        .collection("locations")
        .document("inital")
        .setData({"placeholder":false});
      });
    }
  }

  dynamic getLocationDocuments() async {
    return await _businessValue.reference
    .collection('days')
    .document(getFirebaseDate(_selectedDate))
    .collection('locations')
    .getDocuments();
  }

  dynamic getAttendanceFromSnapshot(snapshot, index) async {
    return await _businessValue.reference
      .collection("days")
      .document(getFirebaseDate(_selectedDate))
      .collection("locations")
      .document(snapshot.data.documents[index].documentID)
      .collection("attendees")
      .getDocuments();
  }
  
  DateTime _selectedDate = DateTime.now();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Wrap(
        children: <Widget>[
          AnimatedBuilder(
          animation: _loginWidgetTranslationAnimation,
          builder: (context, child) => Container(
            transform: Matrix4.translationValues(0, _loginWidgetTranslationAnimation.value, 0),
            child: Stack(
              children: <Widget>[
                //Background
                Background(),
                LoginUI(),
                Container(
                  transform: Matrix4.translationValues(0, 880, 0),
                  margin: EdgeInsets.only(left: 25, right: 25),
                  width: MediaQuery.of(context).size.height,
                  child: Column(
                    children: <Widget>[
                      Container(
                        height: 310,
                        child: TableCalendar(
                          calendarController: _calendarController,
                          onDaySelected: (DateTime date, List events) {setState(() {_selectedDate = date;});},
                          initialCalendarFormat: CalendarFormat.month,
                          availableCalendarFormats: const{CalendarFormat.month:""},
                          startingDayOfWeek: StartingDayOfWeek.monday,
                          calendarStyle: CalendarStyle(
                            outsideDaysVisible: true,
                            weekendStyle: TextStyle(color: Colors.grey[800]).copyWith(),
                            weekdayStyle: TextStyle(color: Colors.grey[800]).copyWith(),
                          ),
                          headerStyle: HeaderStyle(
                            headerPadding: EdgeInsets.only(top: 10, bottom: 10, left: 18),
                            titleTextStyle: TextStyle(
                              fontFamily: "Futura Bold",
                              color: Colors.grey[700],
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      (_onMainDataScreen) ? Container(
                        height: 240,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Color.fromRGBO(240, 245, 250, 0.8),
                            borderRadius: BorderRadius.only(topLeft:  Radius.circular(35), bottomLeft: Radius.circular(25), bottomRight: Radius.circular(30)),
                          ),
                          child: Stack(
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Container(
                                    margin: EdgeInsets.only(top: 15, left: 25),
                                    child: Text(
                                      "Dates",
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontFamily: "Futura",
                                        fontWeight: FontWeight.w800
                                      ),
                                    ),
                                  ),
                                  Container(
                                    margin: EdgeInsets.only(top: 10, left: 20),
                                    width: 1,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300]
                                    ),
                                  ),
                                  Container(
                                    margin: EdgeInsets.only(top: 15, left: 20),
                                    child: Text(
                                      "Offices",
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontFamily: "Futura",
                                        fontWeight: FontWeight.w800
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                margin: EdgeInsets.only(top: 40, bottom: 35),
                                child: FutureBuilder(
                                  future: getLocationDocuments(),
                                  builder: (context, snapshot) {
                                    if (snapshot.data.documents.length == 0) {
                                      return Container(
                                        child: Center(
                                          child: Text(
                                            "Oops!\nNo Offices Are Open Today!",
                                            textAlign: TextAlign.center,
                                          ),
                                        )
                                      );
                                    }
                                    return (snapshot.connectionState == ConnectionState.waiting) ? Container() : ScrollConfiguration(
                                      behavior: MyBehavior(),
                                      child: ListView.builder(
                                        padding: EdgeInsets.only(left: 8, right: 8, bottom: 20),
                                        reverse: false,
                                        itemCount: snapshot.data.documents.length,
                                        itemBuilder: (_, int index) {
                                          return FutureBuilder(
                                            future: getAttendanceFromSnapshot(snapshot, index),
                                            builder: (context, employeeSnapshots) {
                                              if (employeeSnapshots.connectionState == ConnectionState.waiting) {
                                                return Container();
                                              } else {
                                                bool isEmployeeAttendingEvent = false;
                                                for(int i = 0; i < employeeSnapshots.data.documents.length; i++) {
                                                  if (employeeSnapshots.data.documents[i].documentID == _employeeNumber) {
                                                    isEmployeeAttendingEvent = true;
                                                  }
                                                }
                                                return Container(
                                                  margin: EdgeInsets.only(left: 10, right: 10),
                                                  height: 80,
                                                  child: Stack(
                                                    children: <Widget>[
                                                      Container(
                                                        alignment: Alignment(-1, 0.15),
                                                        child: Text(
                                                          Jiffy(_selectedDate).format("d.MM.yy"),
                                                          style: TextStyle(
                                                            color: Colors.grey[700],
                                                            fontFamily: "Futura",
                                                            fontWeight: FontWeight.w600,
                                                            fontSize: 13,
                                                          ),
                                                        ),
                                                      ),
                                                      Align(
                                                        alignment: Alignment(-0.59, 0),
                                                        child: Container(
                                                          height: 80,
                                                          width: 1,
                                                          color: Colors.grey[300]
                                                        ),
                                                      ),
                                                      Align(
                                                        alignment: Alignment(-0.62, 0.1),
                                                          child: Container(
                                                          width: 15,
                                                          height: 15,
                                                          decoration: BoxDecoration(
                                                            shape: BoxShape.circle,
                                                            gradient: LinearGradient(
                                                              begin: Alignment.topRight,
                                                              end: Alignment.bottomLeft,
                                                              colors: [Colors.pink[300] , Colors.orange[200]],
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      Align(
                                                        alignment: Alignment(1, -1),
                                                        child: Container(
                                                          margin: EdgeInsets.only(top: 10, left: 5, right: 5, bottom: 5),
                                                          width: 200,
                                                          decoration: BoxDecoration(
                                                            borderRadius: BorderRadius.circular(10),
                                                            color: Colors.white,
                                                            boxShadow: [
                                                              BoxShadow(
                                                                blurRadius: 8,
                                                                spreadRadius: 1,
                                                                color: Colors.grey[300].withOpacity(0.7),
                                                                offset: Offset(0, 3)
                                                              )
                                                            ]
                                                          ),
                                                          child: Row(
                                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                            children: <Widget>[
                                                              Column(
                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                children: <Widget>[
                                                                  Container(
                                                                    margin: EdgeInsets.only(top: 15, left: 10),
                                                                    child: Text(
                                                                      "${snapshot.data.documents[index].documentID[0].toUpperCase()}${snapshot.data.documents[index].documentID.substring(1)}",
                                                                      style: TextStyle(
                                                                        fontFamily: "FuturaBold",
                                                                        fontWeight: FontWeight.w100,
                                                                        color: Colors.grey[700],
                                                                        fontSize: 12,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  Container(
                                                                    margin: EdgeInsets.only(top: 3, left: 10),
                                                                    child: Row(
                                                                      children: <Widget>[
                                                                        Icon(
                                                                          Icons.business,
                                                                          size: 18,
                                                                        ),
                                                                        Container(
                                                                          margin: EdgeInsets.only(top: 2, left: 5),
                                                                          child: Text(
                                                                            "${(snapshot.data.documents[index]["maxSlots"] - snapshot.data.documents[index]["slotsLeft"]).toString()} / ${snapshot.data.documents[index]["maxSlots"]}",
                                                                            style: TextStyle(
                                                                              fontFamily: "Futura",
                                                                              fontWeight: FontWeight.w800,
                                                                              color: Colors.grey[600],
                                                                              fontSize: 12,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                              Align(
                                                                alignment: Alignment(1, 0.3),
                                                                child: Row(
                                                                  children: <Widget>[
                                                                    Container(
                                                                      margin: EdgeInsets.only(right: 5),
                                                                      height: 10,
                                                                      width: 10,
                                                                      decoration: BoxDecoration(
                                                                        shape: BoxShape.circle,
                                                                        color: (isEmployeeAttendingEvent && snapshot.data.documents[index]["slotsLeft"] > 0) ? Colors.green : Colors.red
                                                                      ),
                                                                    ),
                                                                    Container(
                                                                      margin: EdgeInsets.only(right: 5),
                                                                      child: Text((isEmployeeAttendingEvent) ? "Attending" : "Not\nAttending")
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              }
                                            }
                                          );
                                        }
                                      ),
                                    );
                                  }
                                )
                              ),
                            ]
                          ),
                        ),
                      ) : Container(),
                    ],
                  )
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget LoginUI() {
    return Stack(
      children: <Widget>[
        AnimatedBuilder(
          animation: _companyLogoMarginAnimation,
          builder: (context, child) => Container(
            height: 220,
            width: 400,
            margin: EdgeInsets.only(top: 630, left: 25, right: 25),
            child: CustomPaint(
              painter: MainInfoPainter(),
              child: Stack(
                children: <Widget>[
                  (_logoURL != null && _enterEmployeeNumberData) ? Align(
                    alignment: Alignment(-1, -0.4 + _companyLogoMarginAnimation.value),
                    child: Container(
                      margin: EdgeInsets.only(left: 15),
                      height: 100,
                      width: 100,
                      child: Image.network(_logoURL)
                    ),
                  ) : Container(),
                  (_onMainDataScreen) ? Align(
                    alignment: Alignment(-0.85, _companyLogoMarginAnimation.value * 1.1),
                    child: Container(
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
                  ) : Container(),
                  Align(
                    alignment: Alignment(-1, 0.25 + (_companyLogoMarginAnimation.value * 1)),
                    child: Container(
                      margin: EdgeInsets.only(left: 15),
                      child: Row(
                        children: <Widget>[
                          Text(
                            (_onMainDataScreen) ? "Good ${(DateTime.now().hour >= 12) ? "Afternoon" : "Morning"}," : "Designed By",
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontFamily: "Futura",
                              fontWeight: FontWeight.w300
                            ),
                          ),
                          Container(
                            margin: EdgeInsets.only(left: 5),
                            child: Text(
                              (_employeeName != null && _onMainDataScreen) ? "${_employeeName[0]} ${_employeeName[1]} !" : "Adam Schildkraut",
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontFamily: "Futura",
                                fontWeight: FontWeight.w700
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _upButtonOpacityAnimation,
                    builder: (context, child) => Opacity(
                      opacity: _upButtonOpacityAnimation.value,
                      child: Align(
                        alignment: Alignment(1.15, 0.85),
                        child: MaterialButton(
                          color: Colors.pink[400].withOpacity(0.75),
                          shape: CircleBorder(),
                          child: Container(
                              child: Icon(Icons.keyboard_arrow_up, size: 35, color: Colors.white),
                            ),
                          onPressed: (() {
                            setState(() {
                              _loginWidgetTranslationController.reverse();
                              _companyLogoMarginController.reverse();
                              _upButtonOpacityController.reverse();
                              _backButtonOpacityController.forward();
                              _onMainDataScreen = false;
                            });
                          }),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(top: 90),
                    height: 250,
                    child: AnimatedBuilder(
                      animation: _upButtonOpacityAnimation,
                      builder: (context, child) => Opacity(
                        opacity: _upButtonOpacityAnimation.value,
                        child: Column(
                          children: <Widget>[
                            Container(
                              margin: EdgeInsets.only(top: 100, left: 15, right: 55),
                              height: 1,
                              decoration: BoxDecoration(
                                color: Colors.grey[300]
                              ),
                            ),
                            Container(
                              alignment: Alignment(-1, 0),
                              margin: EdgeInsets.only(top: 8, left: 15, bottom: 5),
                              child: (_isEmployeeAttendingToday != null && _employeeAttendingTodayLocation != null) ? Text(
                                "You Are ${(_isEmployeeAttendingToday) ? "" : "Not"} Going Into The ${_employeeAttendingTodayLocation[0].toUpperCase() + _employeeAttendingTodayLocation.substring(1)} Office Today.",
                                style: TextStyle(
                                  color: (_isEmployeeAttendingToday) ? Color.fromRGBO(247, 185, 123, 1) : Color.fromRGBO(255, 114, 140, 1),
                                  fontFamily: "Futura",
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ) : Container(),
                            ),
                            Container(
                              margin: EdgeInsets.only(left: 15, right: 55),
                              height: 1,
                              decoration: BoxDecoration(
                                color: Colors.grey[300]
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              )
            ),
          ),
        ),
        //Foreground
        Center(
          child: Container(
            margin: EdgeInsets.only(top: 50),
            child: Center(
              child: CustomPaint(
                painter: LoginContainerPainter(),
                child: Container(
                  height: 660,
                  width: 350,
                  child: Column(
                    children: <Widget>[
                      //Top Padding
                      SizedBox(height: 80),
                      //Top Text
                      SizedBox(
                        height: 110,
                        child: Wrap(
                          direction: Axis.vertical,
                          children: <Widget>[
                            AnimatedBuilder(
                              animation: _businessIDTranslationAnimation,
                              builder: (context, child) => Container(
                                transform: Matrix4.translationValues(_businessIDTranslationAnimation.value, 0, 0),
                                child: AnimatedBuilder(
                                  animation: _businessIDTitleColorAnimation,
                                  builder: (context, child) => Text(
                                    "BUSINESS\nID",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.w300,
                                      fontFamily: "Futura",
                                      color: _businessIDTitleColorAnimation.value,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Container(width: 80),
                            AnimatedBuilder(
                              animation: _employeeNumberTranslationAnimation,
                              builder: (context, child) => Container(
                                transform: Matrix4.translationValues(_employeeNumberTranslationAnimation.value, 0, 0),
                                child: AnimatedBuilder(
                                  animation: _employeeNumberTitleColorAnimation,
                                  builder: (context, child) => Stack(
                                    children: <Widget>[
                                      Text(
                                        "EMPLOYEE\nNUMBER",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 40,
                                          fontWeight: FontWeight.w300,
                                          fontFamily: "Futura",
                                          color: _employeeNumberTitleColorAnimation.value,
                                        ),
                                      ),
                                      (_enterEmployeeNumberData) ? Padding(
                                        padding: EdgeInsets.only(top: 85, left: 60),
                                        child: Text(
                                          "$_businessName",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w300,
                                            fontFamily: "Futura",
                                            color: _employeeNumberTitleColorAnimation.value,
                                          ),
                                        )
                                      ) : Container(),
                                    ]
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 90),
                      Container(
                        width: 300,
                        child: AnimatedBuilder(
                          animation: _textFieldColorAnimation,
                          builder: (context, child) => Theme(
                            data: Theme.of(context).copyWith(primaryColor: Colors.grey[700]),
                            child: TextField(
                              controller: _textFieldController,
                              keyboardType: TextInputType.number,
                              autocorrect: false,
                              decoration: InputDecoration(
                                hintText: (_enterEmployeeNumberData) ? "Employee Number" : "Business ID",
                                hintStyle: TextStyle(
                                  color: _textFieldColorAnimation.value
                                ),
                                suffixIcon: (_enterEmployeeNumberData) ? Icon(Icons.assignment_ind) : Icon(Icons.business),
                                enabledBorder: UnderlineInputBorder(      
                                  borderSide: BorderSide(color: Colors.grey[300]),   
                                ),  
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.grey[500]),
                                ),
                              ),
                              style: TextStyle(
                                color: _textFieldColorAnimation.value,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      Container(
                        alignment: Alignment(-0.9, 0),
                        child: MaterialButton(
                          child: Text(
                            (_enterEmployeeNumberData) ? "Forgot Employee Number?" : "Forgot Business ID?",
                            style: TextStyle(
                              color: Colors.grey[400]
                            ),
                          ),
                          onPressed: forgotInfoDialog,
                        ),
                      ),
                      SizedBox(height: 30),
                      Align(
                        alignment: Alignment(1, 0),
                        child: Container(
                          margin: EdgeInsets.only(right: 20),
                          width: 250,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            gradient: LinearGradient(begin: Alignment.bottomLeft, end: Alignment.topRight, colors: [Colors.pink[300].withOpacity(0.75), Colors.orange[300].withOpacity(0.75)])
                          ),
                          child: MaterialButton(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30.0),
                            ),
                            splashColor: Colors.pink.withOpacity(0.7),
                            child: Text(
                              (_enterEmployeeNumberData) ? "Submit" : "Login",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w300,
                                fontFamily: "Futura",
                                color: Colors.white
                              ),
                            ),
                            onPressed: (_enterEmployeeNumberData) ? checkEmployeeNumber : checkBusinessID
                          ),
                        ),
                      ),
                      SizedBox(height: 130),
                      AnimatedBuilder(
                        animation: _backButtonOpacityAnimation,
                        builder: (context, child) => Opacity(
                          opacity: _backButtonOpacityAnimation.value,
                          child: Align(
                            alignment: Alignment(1.1, 0),
                            child: MaterialButton(
                              color: Colors.pink[400].withOpacity(0.75),
                              shape: CircleBorder(),
                              child: Container(
                                  child: Icon(Icons.chevron_left, size: 45, color: Colors.white),
                                ),
                              onPressed: (() {
                                setState(() {
                                  _textFieldController.clear();
                                  _enterEmployeeNumberData = false;
                                  animateTitle();
                                });
                              }),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _textFieldController.dispose();
    _calendarController.dispose();
    _textFieldColorController.dispose();
    _backButtonOpacityController.dispose();
    _businessIDTitleColorController.dispose();
    _businessIDTranslationController.dispose();
    _employeeNumberTitleColorController.dispose();
    _employeeNumberTranslationController.dispose();
    _loginWidgetTranslationController.dispose();
    _companyLogoMarginController.dispose();
    _upButtonOpacityController.dispose();
    super.dispose();
  }
}

class Background extends StatelessWidget{

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[100],
      child: Column(
        children: <Widget>[
          //Top Circle
          Align(
            alignment: Alignment.topLeft,
            child: Transform.scale(
              scale: 1.4,
              child: Container(
                height: 800,
                transform: Matrix4.translationValues(-40, -250, 0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                    colors: [Colors.pink[300] , Colors.orange[200]],
                  ),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          //Top Gradient Circles
          Align(
            alignment: Alignment.topRight,
            child: Transform.scale(
              scale: 1.4,
              child: Container(
                height: 300,
                transform: Matrix4.translationValues(200, -470, 0),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.topRight,
            child: Transform.scale(
              scale: 1.7,
              child: Container(
                height: 300,
                transform: Matrix4.translationValues(-50, -450, 0),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.topRight,
            child: Transform.scale(
              scale: 3,
              child: Container(
                height: 300,
                transform: Matrix4.translationValues(-110, -460, 0),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.topRight,
            child: Transform.scale(
              scale: 1,
              child: Container(
                height: 300,
                transform: Matrix4.translationValues(-200, -1500, 0),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.topLeft,
            child: Transform.scale(
              scale: 1.5,
              child: Container(
                height: 400,
                transform: Matrix4.translationValues(260, -1065, 0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomLeft,
                    end: Alignment.topLeft,
                    colors: [Colors.pink[300] , Colors.orange[200]],
                  ),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.topRight,
            child: Transform.scale(
              scale: 1.7,
              child: Container(
                height: 250,
                transform: Matrix4.translationValues(195, -1010, 0),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.topRight,
            child: Transform.scale(
              scale: 1.1,
              child: Container(
                height: 250,
                transform: Matrix4.translationValues(260, -1850, 0),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          Transform.scale(
            scale: 1.4,
            child: Container(
              height: 300,
              transform: Matrix4.translationValues(-200, -1400, 0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                  colors: [Colors.pink[300] , Colors.orange[200]],
                ),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Transform.scale(
            scale: 1.4,
            child: Container(
              height: 300,
              transform: Matrix4.translationValues(150, -1300, 0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                  colors: [Colors.pink[300] , Colors.orange[200]],
                ),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LoginContainerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = new Paint()
      ..color = Colors.white;

    final topLeftCircleBounds = Rect.fromCircle(center: Offset(30, 30), radius: 30);
    final bottomLeftCircleBounds = Rect.fromCircle(center: Offset(30, 470), radius: 30);
    final bottomRightCircleBounds = Rect.fromCircle(center: Offset(size.width - 30, size.height - 30), radius: 30);
    final topRightCircleBounds = Rect.fromCircle(center: Offset(size.width - 30, 30), radius: 30);

    Path path = Path()
    ..moveTo(30, 0)
    ..arcTo(topLeftCircleBounds, -pi / 2, -pi / 2, false)
    ..lineTo(0, 470)
    ..arcTo(bottomLeftCircleBounds, pi, -pi / 4, false)
    ..lineTo(size.width - 40, size.height - 1)
    ..arcTo(bottomRightCircleBounds, pi / 1.5, -pi / 1.5, false)
    ..lineTo(size.width, 30)
    ..arcTo(topRightCircleBounds, 0, -pi / 2, false)
    ..close();

    canvas.drawShadow(path, Colors.grey.withAlpha(70), 5.0, false);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class MainInfoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = new Paint()
      ..color = Colors.white;

    final Paint shadowPaint = Paint()
      ..color = Colors.grey.withAlpha(210)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10);

    final topCircleBounds = Rect.fromCircle(center: Offset(23, 10), radius: 23);
    final bottomLeftCircleBounds = Rect.fromCircle(center: Offset(30, size.height * 3.5), radius: 30);
    final bottomRightCircleBounds = Rect.fromCircle(center: Offset(size.width - 30, size.height * 3.5), radius: 30);
    final topLeftCircleBounds = Rect.fromCircle(center: Offset(size.width - 30, size.height * 0.85), radius: 30);

    Path path = Path()
    ..moveTo(25, 30)
    ..arcTo(topCircleBounds, -pi / 5, -pi / 1.2, false)
    ..lineTo(0, size.height * 5)
    ..arcTo(bottomLeftCircleBounds, pi, -pi / 2 , false)
    ..lineTo(size.width - 30, size.height * 3.635)
    ..arcTo(bottomRightCircleBounds, pi / 2, -pi / 2 , false)
    ..lineTo(size.width, size.height * 0.85)
    ..arcTo(topLeftCircleBounds, 0, -pi / 3.5, false)
    ..lineTo(32, -11)
    ..close();

    Path shadowPath = Path()
    ..moveTo(25, 30)
    ..arcTo(topCircleBounds, -pi / 5, -pi / 1.2, false)
    ..lineTo(0, size.height * 5)
    ..arcTo(bottomLeftCircleBounds, pi, -pi / 2 , false)
    ..lineTo(size.width - 30, size.height * 3.635)
    ..arcTo(bottomRightCircleBounds, pi / 2, -pi / 2 , false)
    ..lineTo(size.width, size.height * 0.85)
    ..arcTo(topLeftCircleBounds, 0, -pi / 3.5, false)
    ..lineTo(30, 7)
    ..close();

    canvas.drawPath(shadowPath, shadowPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class MyBehavior extends ScrollBehavior {
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) => ClampingScrollPhysics();
}