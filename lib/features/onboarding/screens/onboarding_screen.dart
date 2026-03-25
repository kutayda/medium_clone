import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/onboarding_controller.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final OnboardingController controller = Get.put(OnboardingController());

    return Scaffold(
      body: SafeArea(
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
                  'Sana özel bir akış oluşturmamız için\nbir veya daha fazla kategori seç.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 40),

                // ✅ Çoklu seçim destekli kategori chipleri
                Wrap(
                  spacing: 12.0,
                  runSpacing: 12.0,
                  alignment: WrapAlignment.center,
                  children: controller.categories.map((category) {
                    final categoryName = category['name'];
                    final isSelected = controller.selectedCategories.contains(
                      categoryName,
                    );

                    return FilterChip(
                      label: Text(
                        categoryName,
                        style: TextStyle(
                          fontSize: 16,
                          color: isSelected ? Colors.white : null,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (_) =>
                          controller.toggleCategory(categoryName),
                      selectedColor: Colors.deepPurple,
                      checkmarkColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                // ✅ Kaç kategori seçildiğini gösteren bilgi yazısı
                Obx(
                  () => controller.selectedCategories.isEmpty
                      ? const Text(
                          'En az bir kategori seçmelisin.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.orange, fontSize: 14),
                        )
                      : Text(
                          '${controller.selectedCategories.length} kategori seçildi: '
                          '${controller.selectedCategories.join(', ')}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.deepPurple,
                            fontSize: 14,
                          ),
                        ),
                ),

                const Spacer(),

                // ✅ Seçim yoksa buton devre dışı
                Obx(
                  () => ElevatedButton(
                    onPressed: controller.selectedCategories.isEmpty
                        ? null
                        : controller.finishOnboarding,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Devam Et',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
