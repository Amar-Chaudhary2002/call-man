import 'dart:async';

import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:call_app/database/database_service.dart';
import 'package:call_app/main_app_ui/home.dart';
import 'package:call_app/main_app_ui/utils/fonts.dart';
import 'package:flutter/material.dart';

class PermissionsScreen extends StatefulWidget{

  DatabaseService dbService;
  PermissionsScreen(this.dbService);

  @override
  State<StatefulWidget> createState() {
    return _PermissionsScreenState();
  }
}

class _PermissionsScreenState extends State<PermissionsScreen>{

  bool drawOverOtherAppsPermissionGranted = false;
  late Timer timer;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (timer) async{
      drawOverOtherAppsPermissionGranted = await FlutterOverlayWindow.isPermissionGranted();
      setState(() {});
    });
  }

  @override
  void dispose(){
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
        body: Column(
          children: [
            SizedBox(height: screenHeight*0.07,),
            _logo(),
            SizedBox(height: screenHeight*0.03,),
            Text("Permission Required", style: TextStyle(fontSize: screenWidth*0.06,),),
            SizedBox(height: screenHeight*0.02,),
            _aboutPermissionsSection(),
            SizedBox(height: screenHeight*0.04,),
            _overlayWidgetPermissionWidget(),
            const Spacer(),
            drawOverOtherAppsPermissionGranted ? _continueToAppButton() : const SizedBox.shrink(),
            SizedBox(height: screenHeight*0.02,)
          ],
        )
    );

  }

  Widget _logo(){
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;

    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10)
      ),
      child: SizedBox(
          height: screenHeight*0.15,
          width: screenWidth*0.6,
          child: const Image(image: AssetImage("assets/icons/logoWithText.png"),)
      ),
    );
  }

  Widget _aboutPermissionsSection(){
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;

    return Center(
      child: SizedBox(
        height: screenHeight*0.25,
        width: screenWidth*0.95,
        child: Card(
          elevation: 10,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  SizedBox(width: screenWidth*0.1,),
                  CircleAvatar(
                      backgroundColor:Colors.blue,
                      radius: screenWidth*0.09,
                      child: Icon(Icons.timer, size: screenWidth*0.13, color: Colors.white,)
                  ),
                  SizedBox(width: screenWidth*0.04,),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Display Over Apps", style: TextStyle(fontSize: screenWidth*0.04,fontWeight: FontWeight.bold, decoration: TextDecoration.underline),),
                        Text("To show overlay popup every 5 seconds", style: TextStyle(fontSize: screenWidth*0.03, fontStyle: FontStyle.italic),),
                        SizedBox(height: screenHeight*0.01,),
                        Text("This permission allows the app to display notifications and alerts over other applications.",
                          style: TextStyle(fontSize: screenWidth*0.025, color: Colors.grey[600]),
                        )
                      ],
                    ),
                  ),
                  SizedBox(width: screenWidth*0.05,),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _continueToAppButton(){
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;

    return MaterialButton(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(10),
      onPressed: drawOverOtherAppsPermissionGranted
          ? () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (BuildContext context) => Home(widget.dbService)))
          : null,
      color: Colors.white,
      disabledColor: Colors.grey,
      child: Text("Continue to App", style: TextStyle(fontSize: screenWidth*0.04, color: Colors.black),),
    );
  }

  Widget _overlayWidgetPermissionWidget(){
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;

    return Center(
      child: SizedBox(
        height: screenHeight*0.25,
        width: screenWidth*0.7,
        child: Card(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)
          ),
          elevation: 10,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: screenHeight*0.02),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.timer, size: screenWidth*0.15, color: Colors.blue,),
                  SizedBox(width: screenWidth*0.03,),
                  Icon(
                    drawOverOtherAppsPermissionGranted
                        ? Icons.check_circle_sharp
                        : Icons.close_rounded,
                    color: drawOverOtherAppsPermissionGranted
                        ? Colors.green
                        : Colors.red,
                    size: screenWidth*0.15,
                  )
                ],
              ),
              SizedBox(height: screenHeight*0.02,),
              Text(
                drawOverOtherAppsPermissionGranted ? "Permission Granted" : "Permission Required",
                style: TextStyle(
                  fontSize: screenWidth*0.035,
                  fontWeight: FontWeight.bold,
                  color: drawOverOtherAppsPermissionGranted ? Colors.green : Colors.red,
                ),
              ),
              SizedBox(height: screenHeight*0.02,),
              MaterialButton(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                color: drawOverOtherAppsPermissionGranted ? Colors.grey : Colors.blue,
                disabledColor: Colors.grey,
                onPressed: drawOverOtherAppsPermissionGranted
                    ? null
                    : () async{
                  await _askForDisplayOverWidgetsPermission();
                  setState(() {});
                },
                child: Text(
                  drawOverOtherAppsPermissionGranted ? "Granted" : "Grant Permission",
                  style: TextStyle(fontSize: screenWidth*0.035, color: Colors.white),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  _askForDisplayOverWidgetsPermission() async{
    bool? overlayPermissionsGranted = await FlutterOverlayWindow.requestPermission();
    if(overlayPermissionsGranted != null && !overlayPermissionsGranted){
      debugPrint("Overlay Permissions not granted!");
    }
  }
}