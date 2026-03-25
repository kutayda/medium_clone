import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/api_service.dart';
import '../../feed/screens/feed_screen.dart';

class OnboardingController extends GetxController {
  final ApiService _apiService = ApiService();

  var categories = [].obs;
  // ✅ Tek seçim yerine çoklu seçim listesi
  var selectedCategories = <String>[].obs;
  var isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadCategories();
  }

  Future<void> loadCategories() async {
    isLoading.value = true;
    final fetchedCategories = await _apiService.getCategories();
    categories.value = fetchedCategories;
    isLoading.value = false;
  }

  // ✅ Seçili ise kaldır, değilse ekle
  void toggleCategory(String categoryName) {
    if (selectedCategories.contains(categoryName)) {
      selectedCategories.remove(categoryName);
    } else {
      selectedCategories.add(categoryName);
    }
  }

  Future<void> finishOnboarding() async {
    if (selectedCategories.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      // ✅ Tüm seçili kategorileri kaydet
      await prefs.setStringList('my_categories', selectedCategories.toList());
    }

    Get.offAll(() => const FeedScreen());
  }
}
