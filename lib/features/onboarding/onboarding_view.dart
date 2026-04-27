import 'package:flutter/material.dart';
import 'package:akademiX/features/onboarding/onboarding_controller.dart';
import 'package:akademiX/features/auth/presentation/login_screen.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({Key? key}) : super(key: key);

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  late OnboardingController controller;
  late PageController pageController;

  @override
  void initState() {
    super.initState();
    controller = OnboardingController();
    pageController = PageController();
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: pageController,
        onPageChanged: (index) {
          setState(() {
            controller.step = index;
          });
        },
        children: [
          _buildSplashScreen(context),
          ..._buildOnboardingScreens(context),
        ],
      ),
    );
  }

  Widget _buildSplashScreen(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(height: 60),
          Column(
            children: [
              Image.asset(
                controller.splashData['image']!,
                width: 160,
                height: 160,
                fit: BoxFit.contain,
              ),
              SizedBox(height: 32),
              Text(
                controller.splashData['title']!,
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8),
              Text(
                controller.splashData['subtitle']!,
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.all(32),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  pageController.nextPage(
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Mulai Gunakan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3B82F6),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build semua onboarding screens dari data controller
  List<Widget> _buildOnboardingScreens(BuildContext context) {
    return List.generate(
      controller.totalSteps,
      (index) => _buildOnboardingScreen(context, index),
    );
  }

  // Build satu onboarding screen
  Widget _buildOnboardingScreen(BuildContext context, int index) {
    return Container(
      color: Color(0xFFF3F4F6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(height: 40),
          Column(
            children: [
              Image.asset(
                controller.imagePaths[index],
                width: 140,
                height: 140,
                fit: BoxFit.contain,
              ),
              SizedBox(height: 32),
              Text(
                controller.titles[index],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 20),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  controller.descriptions[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              children: [
                // Indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (int i = 0; i < controller.totalSteps; i++)
                      Container(
                        width: i == index ? 24 : 8,
                        height: 8,
                        margin: EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: i == index
                              ? Color(0xFF3B82F6)
                              : Color(0xFFC5D9E8),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 24),
                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: index == 0
                            ? null
                            : () {
                                pageController.previousPage(
                                  duration: Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              },
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(
                            color: index == 0
                                ? Colors.grey[300]!
                                : Color(0xFF3B82F6),
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Kembali',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: index == 0
                                ? Colors.grey[400]
                                : Color(0xFF3B82F6),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (controller.isLastPageViewStep) {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => LoginScreen(),
                              ),
                            );
                          } else {
                            pageController.nextPage(
                              duration: Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF3B82F6),
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          controller.isLastPageViewStep ? 'Mulai' : 'Lanjutkan',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
