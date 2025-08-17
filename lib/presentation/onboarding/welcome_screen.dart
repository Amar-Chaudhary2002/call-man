import 'dart:developer';
import 'package:call_app/blocs/auth/auth_cubit.dart';
import 'package:call_app/blocs/auth/auth_state.dart';
import 'package:call_app/presentation/dashboard/home.dart';
import 'package:call_app/routes/app_routes.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:call_app/core/image_constant.dart';
import 'package:call_app/core/constant/app_color.dart';
import 'package:google_fonts/google_fonts.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _hasCheckedAuth = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  // 🔥 Simple auth check without SharedPreferences
  void _checkAuthStatus() {
    if (!_hasCheckedAuth) {
      log('🔥 WelcomeScreen: Checking auth status...');
      context.read<AuthCubit>().checkAuthStatus();
      _hasCheckedAuth = true;
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  void _skip() {
    _pageController.jumpToPage(3);
  }

  void _next() {
    if (_currentPage < 0) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Go to sign up after onboarding
      Navigator.pushReplacementNamed(context, AppRoutes.signUp);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        log('🚀 WelcomeScreen - Auth state: ${state.runtimeType}');

        // If user is already authenticated, go to home
        if (state is AuthSuccess) {
          log('🚀 WelcomeScreen - ✅ User authenticated, navigating to home');
          Navigator.pushReplacementNamed(context, AppRoutes.home);
        }
      },
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          log('🚀 WelcomeScreen - Building with state: ${state.runtimeType}');
          // Show loading only briefly while checking auth
          if (state is AuthLoading && !_hasCheckedAuth) {
            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: Scaffold(
                backgroundColor: AppColors.primaryColor,
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      const SizedBox(height: 20),
                      Text(
                        'Checking authentication...',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          if (state is AuthSuccess) {
            return DashboardScreen();
          }
          // Show onboarding for non-authenticated users
          return _buildOnboardingScreen();
        },
      ),
    );
  }

  // 🔥 Your existing onboarding screen code
  Widget _buildOnboardingScreen() {
    final List<_OnboardingContent> pages = [
      _OnboardingContent(
        icon: ImageConstant.callguard,
        title: "Welcome to CallMan",
        description:
            "Your smart companion for better call\nmanagement and protection",
        bullets: const [],
      ),
      _OnboardingContent(
        icon: ImageConstant.spamicon,
        title: "Block Spam Calls",
        description:
            "Automatically block known spam callers and protect yourself from unwanted interruptions",
        bullets: const [
          "Real-time spam detection",
          "Community-based blocking",
          "Custom block lists",
        ],
        bulletIcons: const [
          "assets/icons/right.svg",
          "assets/icons/right.svg",
          "assets/icons/right.svg",
        ],
      ),
      _OnboardingContent(
        icon: ImageConstant.smarticon,
        title: "Smart Call Log",
        description:
            "Group and tag your calls intelligently. Never lose track of important conversations with automatic categorization.",
        bullets: const ["Auto Tagging", "Smart Grouping", "Quick Search"],
        bulletIcons: const [
          "assets/icons/svg.svg",
          "assets/icons/svg (1).svg",
          "assets/icons/svg (2).svg",
        ],
        bulletSubtitles: [
          "Automatically categorize calls by type",
          "Related calls grouped together",
          "Find any call in seconds",
        ],
      ),
      _OnboardingContent(
        icon: ImageConstant.customdialor,
        title: "Custom Dialer",
        description:
            "Personalize your dialer with quick actions and smart shortcuts for faster calling",
        bullets: const ["Quick Actions", "Smart Suggestions"],
        bulletIcons: const [
          "assets/icons/svg (3).svg",
          "assets/icons/svg (4).svg",
        ],
        bulletSubtitles: [
          "Find any call in seconds",
          "Get intelligent contact suggestions while typing",
        ],
      ),
    ];

    return Container(
      decoration: const BoxDecoration(
        // color: Color(0xFF0F172A),
        gradient: LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              if (_currentPage < 0) ...[
                Align(
                  alignment: Alignment.topRight,
                  child: TextButton(
                    onPressed: _skip,
                    child: Text(
                      "Skip",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: pages.length,
                  itemBuilder: (context, index) {
                    final page = pages[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      child: Column(
                        children: [
                          // if (index == 0) const Spacer(),
                          // if (index > 0) ...[
                          //   Row(
                          //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          //     children: [
                          //       // IconButton(
                          //       //   onPressed: () {
                          //       //     _pageController.previousPage(
                          //       //       duration: const Duration(
                          //       //         milliseconds: 300,
                          //       //       ),
                          //       //       curve: Curves.easeInOut,
                          //       //     );
                          //       //   },
                          //       //   icon: const Icon(
                          //       //     Icons.arrow_back,
                          //       //     color: Colors.white,
                          //       //   ),
                          //       // ),
                          //       // Text(
                          //       //   '${index + 1} of ${pages.length}',
                          //       //   style: TextStyle(
                          //       //     fontFamily: "Roboto",
                          //       //     color: Colors.white,
                          //       //     fontSize: 14.sp,
                          //       //   ),
                          //       // ),
                          //     ],
                          //   ),
                          Spacer(),
                          Center(
                            child: SvgPicture.asset(
                              page.icon,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 32),
                          Text(
                            page.title,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.roboto(
                              fontWeight: FontWeight.w700,
                              fontSize: 30.sp,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 11),
                          Text(
                            page.description,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.roboto(
                              fontWeight: FontWeight.w400,
                              fontSize: 18.sp,
                              color: Colors.white.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 50),
                          if (page.bullets.isNotEmpty)
                            Column(
                              children: List.generate(page.bullets.length, (i) {
                                bool isCircular = index == 1 || index == 2;

                                double containerSize;
                                if (index == 1) {
                                  containerSize = 35;
                                } else if (index == 2) {
                                  containerSize = 45;
                                } else if (index == 3) {
                                  containerSize = 52;
                                } else {
                                  containerSize = 45;
                                }

                                double bottomPadding;
                                if (index == 1) {
                                  bottomPadding = 16.0;
                                } else if (index == 2) {
                                  bottomPadding = 28.0;
                                } else if (index == 3) {
                                  bottomPadding = 28.0;
                                } else {
                                  bottomPadding = 16.0;
                                }

                                return Padding(
                                  padding: EdgeInsets.only(
                                    bottom: bottomPadding,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: containerSize,
                                        height: containerSize,
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: isCircular
                                              ? BorderRadius.circular(999)
                                              : BorderRadius.circular(12),
                                        ),
                                        child: SvgPicture.asset(
                                          page.bulletIcons.length > i
                                              ? page.bulletIcons[i]
                                              : ImageConstant.callguard,
                                          height: 30,
                                          width: 30,
                                        ),
                                      ),
                                      SizedBox(width: 16.w),
                                      Expanded(
                                        child:
                                            page.bulletSubtitles.length > i &&
                                                page.bulletSubtitles[i]
                                                    .trim()
                                                    .isNotEmpty
                                            ? Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    page.bullets[i],
                                                    style: TextStyle(
                                                      fontFamily: "Roboto",
                                                      color: Colors.white,
                                                      fontSize: 16.sp,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                  Text(
                                                    page.bulletSubtitles[i],
                                                    style: GoogleFonts.poppins(
                                                      color: Colors.white,
                                                      fontSize: 12.sp,
                                                      fontWeight:
                                                          FontWeight.w400,
                                                    ),
                                                  ),
                                                ],
                                              )
                                            : Align(
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                  page.bullets[i],
                                                  style: TextStyle(
                                                    fontFamily: "Roboto",
                                                    color: Colors.white,
                                                    fontSize: 16.sp,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          const Spacer(),
                        ],
                      ),
                    );
                  },
                ),
              ),
              if (_currentPage < 1) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: List.generate(
                        pages.length,
                        (index) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: DotIndicator(isActive: index == _currentPage),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x1A000000),
                        offset: Offset(0, 10),
                        blurRadius: 15,
                      ),
                      BoxShadow(
                        color: Color(0x1A000000),
                        offset: Offset(0, 4),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _next,
                    icon: const Icon(Icons.arrow_forward, color: Colors.white),
                    label: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _currentPage == 0 ? "Get Started" : "Continue",
                          style: GoogleFonts.roboto(
                            // color: Colors.white,
                            color: Color(0xFF0F172A),
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 5.w),
                        Icon(
                          CupertinoIcons.arrow_right,
                          color: Color(0xFF0F172A),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// Your existing classes remain the same
class DotIndicator extends StatelessWidget {
  final bool isActive;
  const DotIndicator({super.key, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isActive ? 32 : 9,
      height: isActive ? 9 : 9,
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.white38,
        // shape: BoxShape.circle,
        borderRadius: BorderRadius.circular(100),
      ),
    );
  }
}

class _OnboardingContent {
  final String icon;
  final String title;
  final String description;
  final List<String> bullets;
  final List<String> bulletSubtitles;
  final List<String> bulletIcons;

  const _OnboardingContent({
    required this.icon,
    required this.title,
    required this.description,
    required this.bullets,
    this.bulletSubtitles = const [],
    this.bulletIcons = const [],
  });
}
