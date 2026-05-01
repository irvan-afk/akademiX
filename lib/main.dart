import 'package:flutter/material.dart';
import 'package:akademiX/features/onboarding/onboarding_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'akademiX',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const OnboardingView(),
      debugShowCheckedModeBanner: false,
    );
  }
}
