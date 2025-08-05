import 'package:call_app/presentation/auth/login_with_password_screen.dart';
import 'package:call_app/presentation/dashboard/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'blocs/auth/auth_cubit.dart';
import 'blocs/auth/auth_state.dart';
import 'routes/app_routes.dart';
import 'core/theme.dart';
import 'package:firebase_core/firebase_core.dart';


void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    BlocProvider(
      create: (_) => AuthCubit(),
      child: MyApp(),
    ),
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


class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (state is AuthSuccess) {
          return HomeScreen();
        } else {
          return LoginWithPasswordScreen();
        }
      },
    );
  }
}