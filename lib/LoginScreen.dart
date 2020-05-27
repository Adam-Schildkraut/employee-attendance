import 'package:day13/Animation/FadeAnimation.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class LoginScreen extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<LoginScreen> with TickerProviderStateMixin{

  final _businessIDTextInputController = TextEditingController();
  final _employeeNumberTextInputController = TextEditingController();

  AnimationController _businessIDAnimationController;
  Animation _businessIDErrorAnimation;
  AnimationController _employeeNumberAnimationController;
  Animation _employeeNumberErrorAnimation;

  @override
  void initState() {

    _businessIDAnimationController = AnimationController(vsync: this, duration: Duration(milliseconds: 500));
    _businessIDErrorAnimation = ColorTween(begin: Colors.grey[600], end: Colors.red[300]).animate(_businessIDAnimationController);

    _employeeNumberAnimationController = AnimationController(vsync: this, duration: Duration(milliseconds: 500));
    _employeeNumberErrorAnimation = ColorTween(begin: Colors.grey[600], end: Colors.red[300]).animate(_employeeNumberAnimationController);

    super.initState();
  }

  bool isNumeric(String s) {
    if (s == null) {
      return false;
    }
    return double.tryParse(s) != null;
  }

  void checkLoginDetails() {
    String businessID = _businessIDTextInputController.text;
    String employeeNumber = _employeeNumberTextInputController.text;

    if (businessID == "" || !isNumeric(businessID)) {
      if (_businessIDAnimationController.status == AnimationStatus.completed) {
        _businessIDAnimationController.reverse();
      } else {
        _businessIDAnimationController.forward();
        Timer(Duration(seconds: 5), () {
          _businessIDAnimationController.reverse();
        });
      }
    }

    if (employeeNumber == "") {
      if (_employeeNumberAnimationController.status == AnimationStatus.completed) {
        _employeeNumberAnimationController.reverse();
      } else {
        _employeeNumberAnimationController.forward();
        Timer(Duration(seconds: 5), () {
          _employeeNumberAnimationController.reverse();
        });
      }
    }
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
                  FadeAnimation(1.5, Text("Login", style: TextStyle(color: Color.fromRGBO(49, 39, 79, 1), fontWeight: FontWeight.bold, fontSize: 30),)),
                  SizedBox(height: 30,),
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
                          animation: _businessIDErrorAnimation,
                          builder: (context, child) => Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(
                                color: Colors.grey[200]
                              ))
                            ),
                            child: TextField(
                              controller: _businessIDTextInputController,
                              style: TextStyle(color: _businessIDErrorAnimation.value),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: "Business ID",
                                hintStyle: TextStyle(color: _businessIDErrorAnimation.value)
                              ),
                            ),
                          ),
                        ),
                        AnimatedBuilder(
                          animation: _employeeNumberErrorAnimation,
                          builder: (context, child) => Container(
                            padding: EdgeInsets.all(10),
                            child: TextField(
                              controller: _employeeNumberTextInputController,
                              style: TextStyle(color: _employeeNumberErrorAnimation.value),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: "Employee Number",
                                hintStyle: TextStyle(color: _employeeNumberErrorAnimation.value)
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                  SizedBox(height: 20,),
                  FadeAnimation(1.7, Center(child: Text("Forgot ID / Number?", style: TextStyle(color: Color.fromRGBO(196, 135, 198, 1)),))),
                  SizedBox(height: 30,),
                  FadeAnimation(1.9, Center(
                      child: ButtonTheme(
                        minWidth: 225,
                        height: 50,
                        child: FlatButton(
                          color: Color.fromRGBO(49, 39, 79, 1),
                          shape: new RoundedRectangleBorder(borderRadius: new BorderRadius.circular(30.0)),
                          onPressed: checkLoginDetails,
                          child: Text("Login", style: TextStyle(color: Colors.white),),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 30,),
                  FadeAnimation(2, Center(child: Text("Create Account", style: TextStyle(color: Color.fromRGBO(49, 39, 79, .6)),))),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _businessIDTextInputController.dispose();
    _businessIDAnimationController.dispose();

    _employeeNumberTextInputController.dispose();
    _employeeNumberAnimationController.dispose();
    super.dispose();
  }
}
