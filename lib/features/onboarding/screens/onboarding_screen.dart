import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/onboarding_controller.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Controller'ı arayüze bağla (Dependency Injection)
    final OnboardingController controller = Get.put(OnboardingController());

    return Scaffold(
      body: SafeArea(
        // Obx widget'ı, içindeki ".value" değişkenlerinden biri değiştiğinde 
        // SADECE kendi içindeki kısmı yeniden çizer. Tüm sayfayı değil!
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Nelerle İlgileniyorsun?',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Sana özel bir akış (feed) oluşturmamız için bir kategori seç.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 40),
                
                Wrap(
                  spacing: 12.0,
                  runSpacing: 12.0,
                  alignment: WrapAlignment.center,
                  children: controller.categories.map((category) {
                    final categoryName = category['name'];
                    // Seçili olup olmadığını ".value" üzerinden kontrol ediyoruz
                    final isSelected = controller.selectedCategory.value == categoryName;
                    
                    return ChoiceChip(
                      label: Text(categoryName, style: const TextStyle(fontSize: 16)),
                      selected: isSelected,
                      onSelected: (_) => controller.selectCategory(categoryName),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    );
                  }).toList(),
                ),
                const Spacer(),
                
                ElevatedButton(
                  onPressed: controller.finishOnboarding,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Devam Et', style: TextStyle(fontSize: 18)),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}