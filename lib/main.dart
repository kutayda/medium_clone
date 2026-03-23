import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:medium_clone/screens/onboarding_screen.dart';

void main() {
  runApp(const MediumCloneApp());
}

class MediumCloneApp extends StatelessWidget {
  const MediumCloneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp( // Sadece burası değişti!
      title: 'Medium Clone',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const OnboardingScreen(),
    );
  }
}
