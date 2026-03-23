import 'package:get/get.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';

class FeedController extends GetxController{
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
  Future<void> loadData() async{
  isLoading.value = true; 

  categories.value = await _apiService.getCategories();
  posts.value = await _apiService.getFeed();
  currentUserEmail.value = await _storage.read(key: 'current_email');

  isLoading.value = false;
  }

  // 2. Kategoriye Göre Filtrele
  Future<void> filterByCategory(String? categoryName) async{
    selectedCategory.value = categoryName;
    isLoading.value = true;

    posts.value = await _apiService.getFeed(category: categoryName);
    isLoading.value = false;
  }

  // 3. Post Sil 
  Future<bool> deletePost(String postId) async{
    bool success = await _apiService.deletePost(postId);
    if(success){
      posts.removeWhere((element) => element['id'] == postId);
    }
    return success; 
  }

  // 4. Çıkış Yap 
  Future<void> logout()async{
    await _apiService.logout();
    currentUserEmail.value = null;
    loadData();
  }

  //5. Beğeni At/Geri al 
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
  
  //6. Yoruma at
  Future<bool> addComment(String postId, String content)async{
    bool success = await _apiService.addComment(postId, content);
    if(success){
      loadData();
    }
    return success;
  }
}