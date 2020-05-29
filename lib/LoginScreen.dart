import 'package:employee_attendance/DisplayScreen.dart';
import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

import 'dart:async';
import 'dart:math';

class LoginScreen extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<LoginScreen> with TickerProviderStateMixin{

  final FirebaseAnalytics analytics = FirebaseAnalytics();
  final db = Firestore.instance;
  final ref = FirebaseStorage.instance;

  String _businessID = "";
  String _employeeNumber = "";
  String _businessName = "";
  String _logoURL;

  bool _enterEmployeeNumberData = false;

  int _animationLength = 300;

  TextEditingController _textFieldController;

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

  @override
  void initState() {

    _textFieldController = TextEditingController();

    _textFieldColorController = AnimationController(vsync: this, duration: Duration(milliseconds: 150));
    _textFieldColorAnimation = ColorTween(begin: Colors.grey[600], end: Colors.red[500]).animate(_textFieldColorController);

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
          print("$value EXISTS");
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
          'Employee_Number': _employeeNumber,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Wrap(
        children: <Widget>[
          Stack(
            children: <Widget>[
              //Background
              Background(),
              //Bottom
              BottomInfoAndLogoWidget(
                logoURL: _logoURL,
                enterEmployeeNumberData: _enterEmployeeNumberData,
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
                              builder: (context, child) => Align(
                                alignment: Alignment(1.1, 0),
                                child:
                                MaterialButton(
                                  child: Opacity(
                                    opacity: _backButtonOpacityAnimation.value,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.pink[400].withOpacity(0.75),
                                        shape: BoxShape.circle
                                      ),
                                      child: Icon(Icons.chevron_left, size: 40, color: Colors.white),
                                    ),
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
                          ],
                        ),
                      ),
                    ),
                  )
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _textFieldController.dispose();
    _backButtonOpacityController.dispose();
    _businessIDTitleColorController.dispose();
    _businessIDTranslationController.dispose();
    _employeeNumberTitleColorController.dispose();
    _employeeNumberTranslationController.dispose();
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
              scale: 1.6,
              child: Container(
                height: 500,
                transform: Matrix4.translationValues(-40, -150, 0),
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
              scale: 1.2,
              child: Container(
                height: 500,
                transform: Matrix4.translationValues(300, -1100, 0),
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
    final bottomLeftCircleBounds = Rect.fromCircle(center: Offset(30, 450), radius: 30);
    final bottomRightCircleBounds = Rect.fromCircle(center: Offset(size.width - 30, size.height - 30), radius: 30);
    final topRightCircleBounds = Rect.fromCircle(center: Offset(size.width - 30, 30), radius: 30);

    Path path = Path()
    ..moveTo(30, 0)
    ..arcTo(topLeftCircleBounds, -pi / 2, -pi / 2, false)
    ..lineTo(0, 450)
    ..arcTo(bottomLeftCircleBounds, pi, -pi / 2.5, false)
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

class DesignedByPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = new Paint()
      ..color = Colors.white.withAlpha(220);

    final Paint shadowPaint = Paint()
      ..color = Colors.grey.withAlpha(120)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10);

    final topCircleBounds = Rect.fromCircle(center: Offset(23, 30), radius: 23);
    final topCircleShadowBounds = Rect.fromCircle(center: Offset(30, 30), radius: 30);

    Path path = Path()
    ..moveTo(25, 30)
    ..arcTo(topCircleBounds, -pi / 5, -pi / 1.2, false)
    ..lineTo(0, size.height)
    ..lineTo(size.width - 5, 210)
    ..lineTo(39, 13)
    ..close();

    Path shadowPath = Path()
    ..moveTo(30, 0)
    ..arcTo(topCircleShadowBounds, -pi / 2, -pi / 1.9, false)
    ..lineTo(0, 210)
    ..lineTo(size.width, 210)
    ..lineTo(45, 10)
    ..close();

    canvas.drawPath(shadowPath, shadowPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class BottomInfoAndLogoWidget extends StatelessWidget {
  final String logoURL;
  final bool enterEmployeeNumberData;

  BottomInfoAndLogoWidget({@required this.logoURL, @required this.enterEmployeeNumberData});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 170,
      width: 400,
      margin: EdgeInsets.only(top: 630, left: 25, right: 25),
      child: CustomPaint(
        painter: DesignedByPainter(),
        child: Stack(
          children: <Widget>[
            (logoURL != null && enterEmployeeNumberData) ? Align(
              alignment: Alignment(-1, -0.1),
              child: Container(
                margin: EdgeInsets.only(left: 15),
                height: 60,
                width: 80,
                child: Image.network(logoURL)
              ),
            ) : Container(),
            Align(
              alignment: Alignment(-1, 0.6),
              child: Container(
                margin: EdgeInsets.only(left: 15),
                child: Text(
                  "Designed By",
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontFamily: "Futura",
                    fontWeight: FontWeight.w300
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment(-1, 0.9),
              child: Container(
                margin: EdgeInsets.only(left: 15),
                child: Text(
                  "Adam Schildkraut",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontFamily: "Futura",
                    fontWeight: FontWeight.w700
                  ),
                ),
              ),
            )
          ],
        )
      ),
    );
  }
}