import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'routes/app_routes.dart';
import 'core/theme.dart';

void main() {
  runApp(const MyApp());
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
          title: 'CallGuard',
          theme: appTheme,
          initialRoute: AppRoutes.welcome,
          routes: AppRoutes.routes,
          debugShowCheckedModeBanner: true,
        );
      },
    );
  }
}
