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
    loadCategories(); 
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

  // İŞTE SİHİRLİ VE DÜZELTİLMİŞ BÖLÜM BURASI 🪄
  Future<void> finishOnboarding() async {
    if (selectedCategory.value != null) {
      final prefs = await SharedPreferences.getInstance();
      
      // FeedController bizden liste bekliyor. Biz de seçilen tek kategoriyi köşeli parantez içine alıp Liste olarak kaydediyoruz!
      await prefs.setStringList('my_categories', [selectedCategory.value!]);
    }
    
    Get.offAll(() => const FeedScreen()); 
  }
}