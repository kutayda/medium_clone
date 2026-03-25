// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/create_post_controller.dart';

class CreatePostScreen extends StatelessWidget {
  const CreatePostScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Beyni (Controller) ayağa kaldırıyoruz
    final CreatePostController controller = Get.put(CreatePostController());

    return Scaffold(
      appBar: AppBar(
title: Obx(() => Text(controller.isEditMode.value ? 'Yazıyı Düzenle' : 'Yeni Yazı', style: const TextStyle(fontWeight: FontWeight.bold))),        actions: [
          // Sağ üstteki Paylaş butonu (Yüklenirken dönen ikona dönüşür)
          Obx(() => controller.isLoading.value
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))),
                )
              : IconButton(
                  icon: const Icon(Icons.send, color: Colors.deepPurple),
                  onPressed: controller.submitPost,
                ))
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // KATEGORİ SEÇİCİ (Dropdown)
            Obx(() {
              if (controller.categories.isEmpty) {
                return const Center(child: CircularProgressIndicator()); // Kategoriler yüklenirken bekleme ikonu
              }
              return DropdownButtonFormField<String>(
                value: controller.selectedCategory.value,
                decoration: InputDecoration(
                  labelText: 'Kategori',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.category),
                ),
                items: controller.categories.map((cat) {
                  return DropdownMenuItem<String>(
                    value: cat['name'],
                    child: Text(cat['name']),
                  );
                }).toList(),
                onChanged: (val) => controller.selectedCategory.value = val,
              );
            }),
            const SizedBox(height: 16),

            // BAŞLIK KUTUSU
            TextField(
              controller: controller.titleController,
              decoration: InputDecoration(
                labelText: 'Başlık',
                hintText: 'Etkileyici bir başlık girin...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // FOTOĞRAF URL KUTUSU
            TextField(
              controller: controller.imageUrlController,
              decoration: InputDecoration(
                labelText: 'Kapak Fotoğrafı URL (İsteğe Bağlı)',
                hintText: 'https://...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.image),
              ),
            ),
            const SizedBox(height: 16),

            // İÇERİK (YAZI) KUTUSU
            TextField(
              controller: controller.contentController,
              maxLines: 12, // Geniş bir alan veriyoruz
              decoration: InputDecoration(
                labelText: 'İçerik',
                hintText: 'Düşüncelerini paylaşmaya başla...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}