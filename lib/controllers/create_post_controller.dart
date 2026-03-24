import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'feed_controller.dart';

class CreatePostController extends GetxController {
  final ApiService _apiService = ApiService();

  final titleController = TextEditingController();
  final contentController = TextEditingController();
  final imageUrlController = TextEditingController();

  var isLoading = false.obs;
  var categories = [].obs;
  var selectedCategory = RxnString();

  var isEditMode = false.obs;
  var editPostId = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _loadCategories();

    // Eğer sayfaya bir argüman (post verisi) geldiyse düzenleme moduna geç
    if (Get.arguments != null) {
      isEditMode.value = true;
      final post = Get.arguments;
      editPostId.value = post['id'];
      
      // Mevcut verileri kutucuklara doldur
      titleController.text = post['title'] ?? '';
      contentController.text = post['content'] ?? '';
      imageUrlController.text = post['image_url'] ?? '';
      
      // Eğer postun zaten bir kategorisi varsa onu seçili yap
      if (post['categories'] != null && post['categories'].isNotEmpty) {
        selectedCategory.value = post['categories'][0]['name'];
      }
    }
  }

  // Kategorileri Sunucudan Getir
  Future<void> _loadCategories() async {
    final fetched = await _apiService.getCategories();
    categories.value = fetched;
    
    // Eğer yeni post açılıyorsa ve kategori seçilmemişse ilkini varsayılan yap
    if (categories.isNotEmpty && selectedCategory.value == null) {
      selectedCategory.value = categories[0]['name'];
    }
  }

  // Ana İşlem: Paylaş veya Güncelle
  Future<void> submitPost() async {
    if (titleController.text.trim().isEmpty || 
        contentController.text.trim().isEmpty || 
        selectedCategory.value == null) {
      Get.snackbar('Uyarı', 'Lütfen başlık, içerik ve kategori alanlarını doldurunuz.', 
          backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    isLoading.value = true;
    bool success = false;

    // Seçilen kategoriyi bir liste olarak hazırlıyoruz
    List<String> categoryList = [selectedCategory.value!];

    if (isEditMode.value) {
      // GÜNCELLEME İŞLEMİ
      success = await _apiService.updatePost(
        editPostId.value,
        titleController.text.trim(),
        contentController.text.trim(),
        categoryList, 
        imageUrlController.text.trim(),
      );
    } else {
      // YENİ PAYLAŞMA İŞLEMİ
      success = await _apiService.createPost(
        titleController.text.trim(),
        contentController.text.trim(),
        categoryList,
        imageUrlController.text.trim(),
      );
    }

    if (success) {
      // Ana sayfadaki verileri yenile
      if (Get.isRegistered<FeedController>()) {
        await Get.find<FeedController>().loadData();
      }
      
      Get.back(); // Sayfayı kapat
      Get.snackbar('Başarılı', isEditMode.value ? 'Yazınız güncellendi!' : 'Yazınız paylaşıldı!', 
          backgroundColor: Colors.green, colorText: Colors.white);
    } else {
      Get.snackbar('Hata', 'İşlem gerçekleştirilirken bir sorun oluştu.', 
          backgroundColor: Colors.red, colorText: Colors.white);
    }

    isLoading.value = false;
  }

  @override
  void onClose() {
    titleController.dispose();
    contentController.dispose();
    imageUrlController.dispose();
    super.onClose();
  }
}