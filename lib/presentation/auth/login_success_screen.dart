// import 'package:call_app/core/constant/app_color.dart';
// import 'package:call_app/core/image_constant.dart';
// import 'package:call_app/presentation/dashboard/recent_call_screen.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
//
// class LoginSuccessScreen extends StatelessWidget {
//   const LoginSuccessScreen({super.key});
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.primaryColor,
//       resizeToAvoidBottomInset: false,
//       body: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Center(
//             child: SingleChildScrollView(
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               child: Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(23.sp),
//                   border: Border.all(color: Color(0xFFE5E7EB), width: 0.1),
//                   gradient: const LinearGradient(
//                     colors: [Color(0xFF082046), Color(0xFF45006E)],
//                     begin: Alignment.topLeft,
//                     end: Alignment.bottomRight,
//                   ),
//                   boxShadow: [
//                     BoxShadow(
//                       color: const Color(0x66000000),
//                       offset: const Offset(0, 25),
//                       blurRadius: 50,
//                       spreadRadius: 0,
//                     ),
//                   ],
//                 ),
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Image.asset(ImageConstant.righticons),
//                     const SizedBox(height: 7),
//                     Text(
//                       "Login Successful!",
//                       style: TextStyle(
//                         fontFamily: "Roboto",
//                         fontSize: 20.sp,
//                         fontWeight: FontWeight.w400,
//                         color: Colors.white,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       "Welcome back! You're now logged in to your account.",
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontFamily: "Roboto",
//                         fontSize: 12.sp,
//                         fontWeight: FontWeight.w400,
//                       ),
//                     ),
//                     const SizedBox(height: 82),
//                     SizedBox(
//                       width: double.infinity,
//                       child: ElevatedButton(
//                         onPressed: () {
//                           Navigator.pushReplacement(
//                             context,
//                             MaterialPageRoute(
//                               builder: (_) => const RecentCallScreen(),
//                             ),
//                           );
//                         },
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.black,
//                           padding: const EdgeInsets.symmetric(vertical: 15),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(9),
//                           ),
//                           elevation: 6,
//                           shadowColor: Colors.black.withOpacity(0.3),
//                         ),
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: const [
//                             Text(
//                               "Go To Home",
//                               style: TextStyle(
//                                 color: Colors.white,
//                                 fontSize: 16,
//                               ),
//                             ),
//                             SizedBox(width: 8),
//                             Icon(Icons.arrow_right_alt, color: Colors.white),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//           SizedBox(height: 5.h),
//           const Text(
//             "Need help? Contact Support",
//             style: TextStyle(color: Colors.white, fontSize: 10),
//             textAlign: TextAlign.center,
//           ),
//         ],
//       ),
//     );
//   }
// }
