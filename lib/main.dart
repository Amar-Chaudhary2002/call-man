import 'package:call_app/presentation/auth/login_with_password_screen.dart';
import 'package:call_app/presentation/dashboard/dashboard_screen.dart';
import 'package:call_app/presentation/onboarding/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'blocs/auth/auth_cubit.dart';
import 'blocs/auth/auth_state.dart';
import 'routes/app_routes.dart';
import 'core/theme.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    BlocProvider(
      create: (_) => AuthCubit()..checkAuthStatus(), // 🔥 Key fix: Check auth status on startup
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
          // 🔥 OPTION 1: Remove home property and use initialRoute + onGenerateRoute
          initialRoute: '/',
          routes: AppRoutes.routes,
          // If you need custom route generation, use onGenerateRoute instead of routes
          onGenerateRoute: (settings) {
            // Handle the root route specially
            if (settings.name == '/') {
              return MaterialPageRoute(
                builder: (context) => AuthWrapper(),
              );
            }
            // Let AppRoutes handle other routes
            final route = AppRoutes.routes[settings.name];
            if (route != null) {
              return MaterialPageRoute(builder: route);
            }
            // Fallback for unknown routes
            return MaterialPageRoute(
              builder: (context) => Scaffold(
                body: Center(
                  child: Text('Route not found: ${settings.name}'),
                ),
              ),
            );
          },
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

// Auth Wrapper to handle initial navigation based on auth state
class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        print('🚀 AuthWrapper - Current state: ${state.runtimeType}');

        // Show loading screen while checking auth status
        if (state is AuthLoading) {
          return Scaffold(
            backgroundColor: Colors.blue, // Use your primary color
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 20),
                  Text(
                    'Loading...',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
          );
        }

        // If user is authenticated, show main app screen
        if (state is AuthSuccess) {
          print('🚀 AuthWrapper - User authenticated: ${state.user.id}');
          return HomeScreen(); // Fixed: Use DashboardScreen instead of HomeScreen
        }

        // Default: show welcome screen for unauthenticated users
        print('🚀 AuthWrapper - User not authenticated, showing welcome');
        return WelcomeScreen();
      },
    );
  }
}