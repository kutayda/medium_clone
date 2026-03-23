// ignore_for_file: avoid_print

import 'package:get/get.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class FeedController extends GetxController {
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  var posts = [].obs;
  var categories = [].obs;
  var selectedCategory = RxnString();
  var isLoading = true.obs;
  var currentUserEmail = RxnString();

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  // 1. Verileri Yükle
  Future<void> loadData() async {
    try {
      isLoading.value = true;
      currentUserEmail.value = await _storage.read(key: 'current_email');

      // Üstteki kategori butonlarını çek
      final fetchedCategories = await _apiService.getCategories();
      categories.assignAll(fetchedCategories);

      // Telefona kaydettiğimiz ilgi alanlarını oku
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String>? myCategories = prefs.getStringList('my_categories');

      // Eğer bir ilgi alanı seçilmişse butonu işaretle
      if (myCategories != null && myCategories.isNotEmpty) {
        selectedCategory.value = myCategories.first;
      } else {
        selectedCategory.value = 'Tümü'; // Varsayılan
      }

      // Verileri çek
      var fetchedPosts = await _apiService.getFeed(selectedCategories: myCategories);
      if (fetchedPosts != null) {
        posts.assignAll(fetchedPosts);
      }
    } catch (e) {
      print("Veri yükleme hatası: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // 2. Kategoriye Göre Filtrele
  Future<void> filterByCategory(String? categoryName) async {
    try {
      isLoading.value = true;
      selectedCategory.value = categoryName;

      List<String>? catsToSend;
      if (categoryName != null && categoryName != 'Tümü') {
        catsToSend = [categoryName];
      }

      var fetchedPosts = await _apiService.getFeed(selectedCategories: catsToSend);
      if (fetchedPosts != null) {
        posts.assignAll(fetchedPosts);
      }
    } catch (e) {
      print("Filtreleme hatası: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // ... Silme, Beğeni ve Yorum fonksiyonların harika, onlara dokunmuyorum ...
  
  // 3. Post Sil
  Future<bool> deletePost(String postId) async {
    bool success = await _apiService.deletePost(postId);
    if (success) {
      posts.removeWhere((element) => element['id'] == postId);
    }
    return success;
  }

  // 4. Çıkış Yap
  Future<void> logout() async {
    await _apiService.logout();
    currentUserEmail.value = null;
    loadData();
  }

  // 5. Beğeni İşlemi
  Future<bool> toggleLike(String postId) async {
    bool? isLikedNow = await _apiService.toggleLike(postId);
    if (isLikedNow != null) {
      int index = posts.indexWhere((p) => p['id'] == postId);
      if (index != -1) {
        var updatedPost = Map<String, dynamic>.from(posts[index]);
        List likes = List.from(updatedPost['likes'] ?? []);
        if (isLikedNow == true) {
          likes.add({'user_id': 'current_user'});
        } else {
          if (likes.isNotEmpty) likes.removeLast();
        }
        updatedPost['likes'] = likes;
        updatedPost['is_liked_by_me'] = isLikedNow;
        posts[index] = updatedPost;
      }
      return true;
    }
    return false;
  }

  // 6. Yorum Ekle
  Future<bool> addComment(String postId, String content) async {
    bool success = await _apiService.addComment(postId, content);
    if (success) {
      loadData();
    }
    return success;
  }
}