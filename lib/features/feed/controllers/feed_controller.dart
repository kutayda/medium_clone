// ignore_for_file: dead_code

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
  var selectedCategories = <String>[].obs; // Çoklu seçim destekli
  var isLoading = true.obs;
  var currentUserEmail = RxnString();

   // PAGINATION
  var skip = 0.obs;
  final int limit = 10;
  var hasMoreData = true.obs; // Başka çekilecek post kaldı mı?
  var isFetchingMore = false.obs; // Şu an aşağıdan yeni post yükleniyor mu?
  final ScrollController scrollController = ScrollController(); // Ekranı dinleyecek

  @override
  void onInit() {
    super.onInit();
    _initAndLoad(); 
    scrollController.addListener(_onScroll);
  }

  @override
  void onClose() {
    scrollController.dispose(); 
    super.onClose();
  }

  // --- KAYDIRMA DİNLEYİCİSİ ---
  void _onScroll() {
    if (scrollController.position.pixels >= scrollController.position.maxScrollExtent - 200) {
      fetchMoreData();
    }
  }

Future<void> _initAndLoad() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? myCategories = prefs.getStringList('my_categories');

    if (myCategories != null && myCategories.isNotEmpty) {
      selectedCategories.assignAll(myCategories);
    }
    
    //  API'den verileri çek
    await loadData();
  }

  //  1. VERİLERİ YÜKLE  
  Future<void> loadData() async {
    try {
      isLoading.value = true;
      
      // Sayfalamayı sıfırla
      skip.value = 0;
      hasMoreData.value = true;
      posts.clear();

      currentUserEmail.value = await _storage.read(key: 'current_email');

      final fetchedCategories = await _apiService.getCategories() ?? [];
      categories.assignAll(fetchedCategories);

      final initialPosts = await _apiService.getFeed(
        selectedCategories: selectedCategories.isNotEmpty ? selectedCategories.toList() : null,
        skip: skip.value,
        limit: limit,
      ) ?? [];

      if (initialPosts.length < limit) {
        hasMoreData.value = false;
      }
      posts.assignAll(initialPosts);

    } catch (e) {
      debugPrint("Feed yüklenirken hata: $e");
    } finally {
      isLoading.value = false;
    }
  }

  //  2. SONSUZ KAYDIRMA  
  Future<void> fetchMoreData() async {
    if (isFetchingMore.value || !hasMoreData.value) return;
    
    try {
      isFetchingMore.value = true;
      skip.value += limit; // Sayfayı 10 adım ileri atlat

      final newPosts = await _apiService.getFeed(
        selectedCategories: selectedCategories.isNotEmpty ? selectedCategories.toList() : null,
        skip: skip.value,
        limit: limit,
      ) ?? [];

      if (newPosts.length < limit) {
        hasMoreData.value = false; // Sona ulaştık
      }

      posts.addAll(newPosts); // Yeni postları listenin ALTINA ekle
    } catch (e) {
      debugPrint("Daha fazla post yüklenirken hata: $e");
    } finally {
      isFetchingMore.value = false;
    }
  }

  // 3. KATEGORİ FİLTRELEME
  void filterByCategory(String? categoryName) {
    if (categoryName == null) {
      selectedCategories.clear();
    } else {
      if (selectedCategories.contains(categoryName)) {
        selectedCategories.remove(categoryName);
      } else {
        selectedCategories.add(categoryName);
      }
    }
    loadData(); // Filtre değiştiği için postları sıfırdan çek
  }

  // 4. SİLME
  Future<bool> deletePost(String id) async {
    bool success = await _apiService.deletePost(id);
    if (success) {
      posts.removeWhere((p) => p['id'] == id);
      return true;
    }
    return false;
  }

  // 5. BEĞENİ
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

  // 6. YORUM EKLE
  Future<bool> addComment(String postId, String content) async {
    bool success = await _apiService.addComment(postId, content);
    if (success) {
      final index = posts.indexWhere((p) => p['id'] == postId);
      if (index != -1) {
        final updatedPost = Map<String, dynamic>.from(posts[index]);
        final List comments = List.from(updatedPost['comments'] ?? []);
        
        comments.add({
          'content': content,
          'author': {'email': currentUserEmail.value ?? 'Anonim', 'username': 'Ben'}
        });
        
        updatedPost['comments'] = comments;
        posts[index] = updatedPost;
      }
      return true;
    }
    return false;
  }
}