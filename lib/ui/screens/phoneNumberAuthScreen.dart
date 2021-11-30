import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:phone_auth/ui/screens/homeScreen.dart';
import 'package:wakelock/wakelock.dart';

class PhoneNumberAuthScreen extends StatefulWidget {
  PhoneNumberAuthScreen({Key? key}) : super(key: key);

  @override
  _PhoneNumberAuthScreenState createState() => _PhoneNumberAuthScreenState();
}

class _PhoneNumberAuthScreenState extends State<PhoneNumberAuthScreen> with WidgetsBindingObserver {
  final TextEditingController phoneNumberEditingController = TextEditingController();
  final TextEditingController smsCodeEditingController = TextEditingController();

  bool codeSent = false;
  bool hasError = false;
  String errorMessage = "";
  bool isLoading = false;
  String userVerificationId = "";

  Timer? timer;
  bool canGiveExamAgain = true;
  int canGiveExamAgainTimeInSeconds = 5;
  int resendOtpTimeInSeconds = 30;

  bool showResendOtpButton = false;

  Timer? resendOtpTimer;

  void setResendOtpTimer() {
    resendOtpTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (resendOtpTimeInSeconds == 0) {
        timer.cancel();
        showResendOtpButton = true;
        setState(() {});
      } else {
        print("Resend otp will be enable after : $resendOtpTimeInSeconds");
        resendOtpTimeInSeconds--;
      }
    });
  }

  // void canGiveExamTimer() {
  //   timer = Timer.periodic(Duration(seconds: 1), (timer) {
  //     if (canGiveExamAgainTimeInSeconds == 0) {
  //       addFirebaseDocument();
  //       timer.cancel();
  //       canGiveExamAgain = false;
  //     } else {
  //       canGiveExamAgainTimeInSeconds--;
  //     }
  //   });
  // }

  @override
  void initState() {
    super.initState();
    Wakelock.enable();
    WidgetsBinding.instance?.addObserver(this);
  }

  // @override
  // void didChangeAppLifecycleState(appState) {
  //   if (appState == AppLifecycleState.paused) {
  //     canGiveExamTimer();
  //   } else if (appState == AppLifecycleState.resumed) {
  //     timer?.cancel();
  //     canGiveExamAgain = true;
  //     canGiveExamAgainTimeInSeconds = 5;
  //   }
  // }

  void addFirebaseDocument() {
    FirebaseFirestore.instance.collection("test").add({
      "timestamp": Timestamp.now(),
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance?.removeObserver(this);
    phoneNumberEditingController.dispose();
    smsCodeEditingController.dispose();
    timer?.cancel();
    resendOtpTimer?.cancel();
    Wakelock.disable();
    super.dispose();
  }

  void signInWithPhoneNumber({required String phoneNumber}) async {
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: '+91 $phoneNumber',
      verificationCompleted: (PhoneAuthCredential credential) {
        print("Phone number verified");
      },
      verificationFailed: (FirebaseAuthException e) {
        //if otp code does not verify
        print(e.message);
        setState(() {
          isLoading = false;
        });
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          codeSent = true;
          userVerificationId = verificationId;
          isLoading = false;
        });
        setResendOtpTimer();
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        //code auto retrieval time out
        print("Timeout for waiting otp");
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Stack(
        children: [
          Center(
            child: codeSent
                ? TextField(
                    decoration: InputDecoration(hintText: "Enter sms code"),
                    controller: smsCodeEditingController,
                  )
                : TextField(
                    decoration: InputDecoration(hintText: "Enter phone number"),
                    controller: phoneNumberEditingController,
                  ),
          ),
          Center(
            child: Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).size.height * 0.2,
              ),
              child: isLoading
                  ? CircularProgressIndicator()
                  : CupertinoButton(
                      child: Text("Submit"),
                      onPressed: () async {
                        setState(() {
                          isLoading = true;
                        });

                        //check for phone number
                        if (codeSent) {
                          //
                          PhoneAuthCredential phoneAuthCredential = PhoneAuthProvider.credential(verificationId: userVerificationId, smsCode: smsCodeEditingController.text.trim());
                          FirebaseAuth.instance.signInWithCredential(phoneAuthCredential).then((value) {
                            print("Signed in successfully");
                            setState(() {
                              isLoading = false;
                            });
                            Navigator.of(context).pushReplacement(CupertinoPageRoute(builder: (_) => HomeScreen()));
                          }).catchError((e) {
                            print((e as FirebaseAuthException).code);
                            print(e.toString());
                            setState(() {
                              isLoading = false;
                            });
                          });
                        } else {
                          signInWithPhoneNumber(phoneNumber: phoneNumberEditingController.text.trim());
                        }
                      }),
            ),
          ),
          Center(
            child: Padding(
                child: showResendOtpButton
                    ? CupertinoButton(
                        child: Text("Resend Otp"),
                        onPressed: () {
                          setState(() {
                            showResendOtpButton = false;
                          });
                          resendOtpTimeInSeconds = 30;
                          signInWithPhoneNumber(phoneNumber: phoneNumberEditingController.text.trim());
                        })
                    : Container(),
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).size.height * (0.35),
                )),
          )
        ],
      ),
    );
  }
}
