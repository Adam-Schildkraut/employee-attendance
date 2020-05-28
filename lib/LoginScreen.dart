import 'package:employee_attendance/Animation/FadeAnimation.dart';
import 'package:employee_attendance/DisplayScreen.dart';
import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

import 'dart:async';

class LoginScreen extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<LoginScreen> with TickerProviderStateMixin{

  final _textInputController = TextEditingController();

  final db = Firestore.instance;

  bool _validBusinessID = false;
  String _businessID = "";
  String _businessName = "";

  AnimationController _textFieldAnimationController;
  Animation _textFieldErrorAnimation;

  @override
  void initState() {
    _textFieldAnimationController = AnimationController(vsync: this, duration: Duration(milliseconds: 150));
    _textFieldErrorAnimation = ColorTween(begin: Colors.grey[600], end: Colors.red[300]).animate(_textFieldAnimationController);

    super.initState();
  }

  bool isNumeric(String s) {
    if (s == null) {
      return false;
    }
    return double.tryParse(s) != null;
  }

  void errorAnimation() {
    if (_textFieldAnimationController.status == AnimationStatus.completed) {
      _textFieldAnimationController.reverse();
    } else {
      _textFieldAnimationController.forward();
      Timer(Duration(seconds: 3), () {
        _textFieldAnimationController.reverse();
      });
    }
  }
  
  void checkBusinessID() async {
    String businessID = _textInputController.text;
    if (businessID == "" || !isNumeric(businessID)) {
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
          _businessID = businessID;
          _businessName = value.data["businessName"];
          print("ID Of $_businessName: $businessID");
          _textInputController.clear();
          setState(() {
            _validBusinessID = true;
          });
        }
      });
    }
  }

  void checkEmployeeNumber() async {
    String employeeNumber = _textInputController.text;
    if (employeeNumber == "" || !isNumeric(employeeNumber)) {
      errorAnimation();
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
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => DisplayScreen(businessValue: value, employeeNumber: employeeNumber,))
          );
        } else {
          errorAnimation();
        }
      });
    }
    return;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              height: 400,
              child: Stack(
                children: <Widget>[
                  Positioned(
                    top: -40,
                    height: 400,
                    width: width,
                    child: FadeAnimation(1, Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/images/background.png'),
                          fit: BoxFit.fill
                        )
                      ),
                    )),
                  ),
                  Positioned(
                    height: 400,
                    width: width+20,
                    child: FadeAnimation(1.3, Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/images/background-2.png'),
                          fit: BoxFit.fill
                        )
                      ),
                    )),
                  )
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(height: 20,),
                  FadeAnimation(1.3, Text(
                    (!_validBusinessID) ? "Welcome" : "Welcome To",
                    style: TextStyle(color: Color.fromRGBO(49, 39, 79, 0.5),
                        fontWeight: FontWeight.w400, fontSize: 20
                      ),
                    ),
                  ),
                  SizedBox(height: 5,),
                  FadeAnimation(1.5, Text(
                    (!_validBusinessID) ? "Enter ID" : _businessName,
                    style: TextStyle(color: Color.fromRGBO(49, 39, 79, 1),
                        fontWeight: FontWeight.bold, fontSize: 30
                      ),
                    ),
                  ),
                  SizedBox(height: 20,),
                  FadeAnimation(1.7, Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Color.fromRGBO(196, 135, 198, .3),
                          blurRadius: 20,
                          offset: Offset(0, 10),
                        )
                      ]
                    ),
                    child: Column(
                      children: <Widget>[
                        AnimatedBuilder(
                          animation: _textFieldErrorAnimation,
                          builder: (context, child) => Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(
                                color: Colors.grey[200]
                              ))
                            ),
                            child: TextField(
                              controller: _textInputController,
                              style: TextStyle(color: _textFieldErrorAnimation.value),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: (!_validBusinessID) ? "Business ID" : "Employee Number",
                                hintStyle: TextStyle(color: _textFieldErrorAnimation.value)
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                  SizedBox(height: 20,),
                  FadeAnimation(1.7, Center(child: Text("Forgot ${(!_validBusinessID) ? "Business ID" : "Employee Number"}?", style: TextStyle(color: Color.fromRGBO(196, 135, 198, 1)),))),
                  SizedBox(height: 30,),
                  FadeAnimation(1.9, Center(
                      child: ButtonTheme(
                        minWidth: 225,
                        height: 50,
                        child: FlatButton(
                          color: Color.fromRGBO(49, 39, 79, 1),
                          shape: RoundedRectangleBorder(borderRadius: new BorderRadius.circular(30.0)),
                          onPressed: (!_validBusinessID) ? checkBusinessID : checkEmployeeNumber,
                          child: Text("Login", style: TextStyle(color: Colors.white),),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 30,),
                  FadeAnimation(2, Center(child: Text("Create Account", style: TextStyle(color: Color.fromRGBO(49, 39, 79, .6)),))),
                ],
              ),
            ),
            (_validBusinessID) ? FadeAnimation(0, ButtonTheme(
              height: 50,
              child: FlatButton(
                color: Color.fromRGBO(49, 39, 79, 1),
                shape: CircleBorder(),
                child: Container(
                  child: Icon(Icons.chevron_left, color: Colors.white),
                ),
                onPressed: () {
                  setState(() {
                    _validBusinessID = false;
                  });
                },
              ),
            )) : Container(),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textInputController.dispose();
    _textFieldAnimationController.dispose();
    super.dispose();
  }
}
