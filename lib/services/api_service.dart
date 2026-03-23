// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:io';
import 'package:get/get.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8000';
  
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  // 1. GİRİŞ YAPMA (LOGIN) VE TOKEN ALMA
  Future<bool> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/jwt/login'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'username': email, 
        'password': password,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await storage.write(key: 'jwt_token', value: data['access_token']);
      await storage.write(key: 'jwt_token', value: data['access_token']);
      await storage.write(key: 'current_email', value: email); // YENİ: Kimin giriş yaptığını kaydediyoruz
      return true;
    } else {
      print('Giriş hatası: ${response.body}');
      return false;
    }
  }

  // 2. KAYIT OLMA (REGISTER)
Future<bool> register(String email, String password, String username) async {
  final response = await http.post(
    Uri.parse('$baseUrl/auth/register'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'email': email,
      'password': password,
      'username': username, 
      'is_active': true,
      'is_superuser': false,
      'is_verified': false,
    }),
  );
  return response.statusCode == 201;
}

  // 3. KASADAN TOKEN'I OKUMA
  Future<String?> getToken() async {
    return await storage.read(key: 'jwt_token');
  }

// ÇIKIŞ YAPMA
  Future<void> logout() async {
    await storage.delete(key: 'jwt_token'); 
    await storage.delete(key: 'current_email');
  }
  // 5. KATEGORİLERİ ÇEKME
  Future<List<dynamic>> getCategories() async {
    final response = await http.get(Uri.parse('$baseUrl/categories'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body); 
    }
    return [];
  }

// 6. YAZILARI (POSTLARI) ÇEKME - İsteğe bağlı filtreyle
  Future<List<dynamic>> getFeed({String? category}) async {
    String url = '$baseUrl/feed';
    
    if (category != null && category.isNotEmpty) {
      final encodedCategory = Uri.encodeQueryComponent(category);
      url += '?categories=$encodedCategory';
    }
    
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }
  // 7. YENİ YAZI EKLEME (POST CREATE)
  // YENİ GÖNDERİ PAYLAŞMA MOTORU (Artık 4 parametre alıyor)
  Future<bool> createPost(String title, String content, List<String> categories, String imageUrl) async {
    final token = await getToken();
    if (token == null) return false;

    final response = await http.post(
      Uri.parse('$baseUrl/upload'), // Kendi backend'indeki endpoint neyse o (muhtemelen /upload veya /feed)
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'title': title,
        'content': content,
        'categories': categories, // Liste olarak gidiyor
        'image_url': imageUrl.isEmpty ? null : imageUrl, // Fotoğraf URL eklendi
      }),
    );
    return response.statusCode == 200;
  }
  // 8. BULUTA GÖRSEL YÜKLEME (ImgBB API)
  Future<String?> uploadImageToCloud(File imageFile) async {
    const String imgbbApiKey = '24797aac8bff931ccc31cbd092700568'; 
    
    try {
      final request = http.MultipartRequest(
        'POST', 
        Uri.parse('https://api.imgbb.com/1/upload?key=$imgbbApiKey')
      );
      
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
      
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonResult = jsonDecode(responseData);
      
      if (response.statusCode == 200) {
        return jsonResult['data']['url']; 
      } else {
        print('Görsel yükleme hatası: ${jsonResult['error']['message']}');
        return null;
      }
    } catch (e) {
      print('Bağlantı hatası: $e');
      return null;
    }
  }
// 9. POST SİLME
  Future<bool> deletePost(String postId) async {
    final token = await getToken();
    if (token == null) return false;

    final response = await http.delete(
      Uri.parse('$baseUrl/feed/$postId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    
    if (response.statusCode == 200) {
      return true;
    } else {
      print('🚨 SİLME İŞLEMİ REDDEDİLDİ 🚨');
      print('Durum Kodu: ${response.statusCode}');
      print('Hata Mesajı: ${response.body}');
      return false;
    }
  }
  // 10. Beğeni gönder/çek 
  Future<bool?> toggleLike(String postId) async{
    final token = await getToken();
    if (token == null) return false; 
    
    final response = await http.post(
      Uri.parse('$baseUrl/feed/$postId/like'),
      headers:{'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200){
      final data = jsonDecode(response.body);
      return data['liked'];
    }  
    return null;
  }

  // 11.Yorum ekle 
  Future<bool> addComment(String postId, String content) async{
    final token = await getToken();
    if (token == null) return false; 

    final response = await http.post(
      Uri.parse('$baseUrl/feed/$postId/comment'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'content': content}),
    );
    return response.statusCode == 200;
  }

// 12. GÖNDERİ GÜNCELLE (PUT İsteği)
  Future<bool> updatePost(String postId, String title, String content, String imageUrl) async {
    final token = await getToken();
    if (token == null) return false;

    final response = await http.put(
      Uri.parse('$baseUrl/feed/$postId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json', // 🚨 BU SATIR EKSİKSE 422 HATASI ALIRSIN!
      },
      body: jsonEncode({
        'title': title,
        'content': content,
        'image_url': imageUrl.isEmpty ? null : imageUrl,
      }),
    );

    if (response.statusCode != 200) {
      Get.snackbar(
        'Backend Ne Dedi? (${response.statusCode})', 
        response.body, 
        backgroundColor: Colors.red, 
        colorText: Colors.white,
        duration: const Duration(seconds: 15), 
      );
    }
    return response.statusCode == 200;
  }
}