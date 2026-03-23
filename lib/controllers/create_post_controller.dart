import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'feed_controller.dart';

class CreatePostController extends GetxController{
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
    
    // 1. ÖNCE DÜZENLEME MODUNDA MIYIZ ONA BAKALIM
    if (Get.arguments != null) {
      isEditMode.value = true;
      final post = Get.arguments;
      
      // ZIRHLI ATAMALAR: Eğer veritabanından 'null' gelirse, çökme, yerine '' (boş metin) koy! (Sihirli işaret: ?? '')
      editPostId.value = post['id'] ?? '';
      titleController.text = post['title'] ?? '';
      contentController.text = post['content'] ?? '';
      imageUrlController.text = post['image_url'] ?? '';

      // ESKİ KATEGORİYİ SEÇİLİ HALE GETİR
      if (post['categories'] != null && post['categories'].isNotEmpty) {
        selectedCategory.value = post['categories'][0]['name'];
      }
    }

    // 2. SONRA KATEGORİLERİ SUNUCUDAN ÇEK
    _loadCategories(); 
  }

  // Kategorileri Getir
  Future<void> _loadCategories() async {
    categories.value = await _apiService.getCategories();
    
    // DİKKAT: Eğer düzenleme modundaysak eski kategori zaten seçilmiştir, onu bozma!
    // Sadece eğer kategori boşsa (yeni post açılıyorsa) ilk kategoriyi varsayılan yap.
    if (categories.isNotEmpty && selectedCategory.value == null) {
      selectedCategory.value = categories[0]['name']; 
    }
  }

  // Gönderi Paylaş
Future<void> submitPost() async {
    if (titleController.text.trim().isEmpty || contentController.text.trim().isEmpty) {
      Get.snackbar('Uyarı', 'Lütfen başlık ve içerik alanlarını doldurun.', backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    isLoading.value = true;
    bool success;

    // ŞALTERE GÖRE KARAR VERİYORUZ
    if (isEditMode.value) {
      // GÜNCELLEME İŞLEMİ
      success = await _apiService.updatePost(
        editPostId.value,
        titleController.text.trim(),
        contentController.text.trim(),
        imageUrlController.text.trim(),
      );
    } else {
    // YENİ PAYLAŞMA İŞLEMİ
      success = await _apiService.createPost(
        titleController.text.trim(),
        contentController.text.trim(),
        [selectedCategory.value ?? 'Genel'], 
        imageUrlController.text.trim(), 
      );
    }

    if (success) {
      Get.back(); 
      // Mesajı moda göre değiştir
      Get.snackbar('Başarılı', isEditMode.value ? 'Yazınız güncellendi!' : 'Yazınız paylaşıldı!', backgroundColor: Colors.green, colorText: Colors.white);
      
      if (Get.isRegistered<FeedController>()) {
        Get.find<FeedController>().loadData();
      }
    } else {
      Get.snackbar('Hata', 'İşlem başarısız oldu.', backgroundColor: Colors.red, colorText: Colors.white);
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