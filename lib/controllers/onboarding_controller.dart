import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../screens/feed_screen.dart';

class OnboardingController extends GetxController {
  final ApiService _apiService = ApiService();

  // Değişkenlerin sonuna ".obs" (observable) ekleyerek onları reaktif (dinlenebilir) yapıyoruz
  var categories = [].obs;
  var selectedCategory = RxnString(); 
  var isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadCategories(); // Controller hafızaya alındığı an verileri çekmeye başla
  }

  Future<void> loadCategories() async {
    isLoading.value = true;
    final fetchedCategories = await _apiService.getCategories();
    categories.value = fetchedCategories;
    isLoading.value = false;
  }

  void selectCategory(String categoryName) {
    if (selectedCategory.value == categoryName) {
      selectedCategory.value = null; // Aynı şeye tıklarsa seçimi kaldır
    } else {
      selectedCategory.value = categoryName;
    }
  }

  Future<void> finishOnboarding() async {
    if (selectedCategory.value != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_category', selectedCategory.value!);
    }
    
    // offAll, geçmişteki tüm sayfaları silip yeni sayfaya geçer (Geri tuşunu iptal eder).
    Get.offAll(() => const FeedScreen()); 
  }
}