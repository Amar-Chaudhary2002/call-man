import 'package:call_app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:call_app/core/image_constant.dart';
import 'package:call_app/core/constant/app_color.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  void _skip() {
    _pageController.jumpToPage(3);
  }

  void _next() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Navigate to SignUp using named route
      Navigator.pushReplacementNamed(context, AppRoutes.signUp);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<_OnboardingContent> pages = [
      _OnboardingContent(
        icon: ImageConstant.callguard,
        title: "Welcome to CallGuard",
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
      ),
      _OnboardingContent(
        icon: ImageConstant.smarticon,
        title: "Smart Call Log",
        description:
            "Group and tag your calls intelligently. Never lose track of important conversations with automatic categorization.",
        bullets: const ["Auto Tagging", "Smart Grouping", "Quick Search"],
      ),
      _OnboardingContent(
        icon: ImageConstant.customdialor,
        title: "Custom Dialer",
        description:
            "Personalize your dialer with quick actions and smart shortcuts for faster calling",
        bullets: const ["Quick Actions", "Smart Suggestions"],
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      body: SafeArea(
        child: Column(
          children: [
            // if (_currentPage == 0) ...[
            //   Align(
            //     alignment: Alignment.topRight,
            //     child: TextButton(
            //       onPressed: _skip,
            //       child: const Text(
            //         "Skip",
            //         style: TextStyle(color: Colors.white),
            //       ),
            //     ),
            //   ),
            // ],
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
                        if (index == 0) const Spacer(),
                        if (index > 0) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (index > 0)
                                IconButton(
                                  onPressed: () {
                                    _pageController.previousPage(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      curve: Curves.easeInOut,
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.arrow_back,
                                    color: Colors.white,
                                  ),
                                )
                              else
                                const SizedBox(width: 48),
                              Text(
                                '${index + 1} of ${pages.length}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14.sp,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: (index + 1) / pages.length,
                            backgroundColor: Colors.white24,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                          Spacer(),
                        ],
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
                          style: TextStyle(
                            fontFamily: "Roboto",
                            fontWeight: FontWeight.w700,
                            fontSize: 30.sp,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          page.description,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: "Roboto",
                            fontWeight: FontWeight.w400,
                            fontSize: 18.sp,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (page.bullets.isNotEmpty)
                          Column(
                            children: page.bullets.map((e) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle,
                                      size: 20,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        e,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16.sp,
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

            if (_currentPage > 0) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Left: Dot indicators
                    Center(
                      child: Row(
                        children: List.generate(
                          pages.length,
                          (index) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: DotIndicator(
                              isActive: index == _currentPage,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Right: Skip button
                    TextButton(
                      onPressed: _skip,
                      child: const Text(
                        "Skip",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _next,
                  icon: const Icon(Icons.arrow_forward, color: Colors.white),
                  label: Text(
                    _currentPage == 0 ? "Get Started" : "Continue",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class DotIndicator extends StatelessWidget {
  final bool isActive;
  const DotIndicator({super.key, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isActive ? 10 : 8,
      height: isActive ? 10 : 8,
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.white38,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _OnboardingContent {
  final String icon;
  final String title;
  final String description;
  final List<String> bullets;
  // final bool progressbar;
  const _OnboardingContent({
    required this.icon,
    required this.title,
    required this.description,
    required this.bullets,
    // this.progressbar = false,
  });
}
