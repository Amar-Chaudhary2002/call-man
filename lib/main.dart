import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'blocs/auth/auth_cubit.dart';
import 'routes/app_routes.dart';
import 'core/theme.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FlutterError.onError = (FlutterErrorDetails details) {
    // Log graphics errors but don't crash
    if (details.exception.toString().contains('GraphicBuffer') ||
        details.exception.toString().contains('qdgralloc')) {
      log('Graphics error (non-fatal): ${details.exception}');
      return;
    }
    FlutterError.presentError(details);
  };
  runApp(
    BlocProvider(create: (_) => AuthCubit()..checkAuthStatus(), child: MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: Size(404.47, 889),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'CallMan',
          theme: appTheme,
          initialRoute: '/',
          routes: AppRoutes.routes,
          debugShowCheckedModeBanner: false,
          // home: MainNavigationScreen(),
        );
      },
    );
  }
}
