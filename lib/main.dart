import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:medium_clone/features/onboarding/screens/onboarding_screen.dart';
import 'core/theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Tema kontrolcüsünü uygulama başlar başlamaz ayağa kaldırıyoruz
  Get.put(ThemeController());
  
  runApp(const MediumCloneApp());
}

class MediumCloneApp extends StatelessWidget {
  const MediumCloneApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Hafızadan okunan tema bilgisini alıyoruz
    final themeController = Get.find<ThemeController>();

    return GetMaterialApp(
      title: 'Medium Clone',
      debugShowCheckedModeBanner: false,
      
      // ☀️ AYDINLIK TEMA (Light Mode)
      theme: ThemeData.light(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
      ),

      // 🌙 KARANLIK TEMA (Dark Mode)
      darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey[900],
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),

      // Uygulama açılışında kontrolcüdeki değere göre temayı belirliyoruz
      themeMode: themeController.isDarkMode.value ? ThemeMode.dark : ThemeMode.light,

      home: const OnboardingScreen(),
    );
  }
}