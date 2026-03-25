// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/api_service.dart';

class FeedController extends GetxController {
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  var posts = [].obs;
  var categories = [].obs;
  // ✅ Tek seçim yerine çoklu seçim listesi
  var selectedCategories = <String>[].obs;
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

      final fetchedCategories = await _apiService.getCategories();
      categories.assignAll(fetchedCategories);

      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String>? myCategories = prefs.getStringList('my_categories');

      // ✅ Tüm seçili kategorileri listeye ata
      if (myCategories != null && myCategories.isNotEmpty) {
        selectedCategories.assignAll(myCategories);
      }

      var fetchedPosts =
          await _apiService.getFeed(selectedCategories: myCategories);
      if (fetchedPosts != null) {
        posts.assignAll(fetchedPosts);
      }
    } catch (e) {
      debugPrint("Veri yükleme hatası: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // 2. Kategoriye Göre Filtrele (✅ Çoklu seçim destekli)
  Future<void> toggleCategoryFilter(String categoryName) async {
    try {
      isLoading.value = true;

      if (categoryName == 'Tümü') {
        selectedCategories.clear();
      } else {
        if (selectedCategories.contains(categoryName)) {
          selectedCategories.remove(categoryName);
        } else {
          selectedCategories.add(categoryName);
        }
      }

      List<String>? catsToSend =
          selectedCategories.isEmpty ? null : selectedCategories.toList();

      var fetchedPosts =
          await _apiService.getFeed(selectedCategories: catsToSend);
      if (fetchedPosts != null) {
        posts.assignAll(fetchedPosts);
      }
    } catch (e) {
      debugPrint("Filtreleme hatası: $e");
    } finally {
      isLoading.value = false;
    }
  }

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

  // 5. Beğeni
  Future<bool> toggleLike(String postId) async {
    bool? isLikedNow = await _apiService.toggleLike(postId);
    if (isLikedNow == null) return false;

    final index = posts.indexWhere((p) => p['id'] == postId);
    if (index == -1) return false;

    final updatedPost = Map<String, dynamic>.from(posts[index]);
    final myEmail = currentUserEmail.value;
    final List likes = List.from(updatedPost['likes'] ?? []);

    if (isLikedNow) {
      likes.add({'user_id': myEmail});
    } else {
      likes.removeWhere((like) => like['user_id'] == myEmail);
    }

    updatedPost['likes'] = likes;
    updatedPost['is_liked_by_me'] = isLikedNow;
    posts[index] = updatedPost;

    return true;
  }

  // 6. Yorum Ekle (✅ Artık tüm feed yeniden yüklenmiyor)
  Future<bool> addComment(String postId, String content) async {
    bool success = await _apiService.addComment(postId, content);
    if (success) {
      final index = posts.indexWhere((p) => p['id'] == postId);
      if (index != -1) {
        final updatedPost = Map<String, dynamic>.from(posts[index]);
        final List comments = List.from(updatedPost['comments'] ?? []);

        comments.add({
          'content': content,
          'author': {
            'email': currentUserEmail.value,
            'username': null,
          },
        });

        updatedPost['comments'] = comments;
        posts[index] = updatedPost;
      }
    }
    return success;
  }
}
