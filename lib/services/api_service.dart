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

  // 1. GİRİŞ YAPMA
  Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/jwt/login'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'username': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await storage.write(key: 'jwt_token', value: data['access_token']);
        await storage.write(key: 'current_email', value: email);
        return true;
      }
      return false;
    } catch (e) {
      print("Login Hatası: $e");
      return false;
    }
  }

  // 2. KAYIT OLMA
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

  // 3. TOKEN OKUMA
  Future<String?> getToken() async {
    return await storage.read(key: 'jwt_token');
  }

  // 4. ÇIKIŞ YAPMA
  Future<void> logout() async {
    await storage.delete(key: 'jwt_token');
    await storage.delete(key: 'current_email');
  }

  // 5. KATEGORİLERİ ÇEKME
  Future<List<dynamic>> getCategories() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/categories'));
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
    } catch (e) {
      print("Kategori çekme hatası: $e");
    }
    return [];
  }

  // 6. AKIŞI GETİR (Filtreli ve Güvenli URL)
  Future<List<dynamic>?> getFeed({List<String>? selectedCategories}) async {
    final token = await getToken();
    
    // Temel URI nesnesi oluşturuyoruz
    var uri = Uri.parse('$baseUrl/feed');

    // Kategori varsa, Flutter'ın Uri sınıfı & ve Türkçe karakterleri otomatik zırhlar!
    if (selectedCategories != null && selectedCategories.isNotEmpty) {
      uri = uri.replace(queryParameters: {
        'categories': selectedCategories.join(','),
      });
    }

    try {
      final response = await http.get(
        uri,
        headers: {if (token != null) 'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        // Gelen verideki Türkçe karakterleri korumak için utf8.decode şart
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
    } catch (e) {
      print("Feed çekme hatası: $e");
    }
    return null;
  }

  // 7. YENİ GÖNDERİ PAYLAŞMA
  Future<bool> createPost(
    String title,
    String content,
    List<String> categories,
    String imageUrl,
  ) async {
    final token = await getToken();
    if (token == null) return false;
    
    print("🚀 API'YE GİDEN KATEGORİLER: $categories");
    
    final response = await http.post(
      Uri.parse('$baseUrl/upload'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'title': title,
        'content': content,
        'category_ids': categories, // Backend'in beklediği etiket ismi
        'image_url': imageUrl.isEmpty ? null : imageUrl,
      }),
    );
    return response.statusCode == 200;
  }

  // 8. BULUTA GÖRSEL YÜKLEME (ImgBB)
  Future<String?> uploadImageToCloud(File imageFile) async {
    const String imgbbApiKey = '24797aac8bff931ccc31cbd092700568';
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.imgbb.com/1/upload?key=$imgbbApiKey'),
      );
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonResult = jsonDecode(responseData);

      if (response.statusCode == 200) {
        return jsonResult['data']['url'];
      }
    } catch (e) {
      print('Görsel yükleme hatası: $e');
    }
    return null;
  }

  // 9. POST SİLME
  Future<bool> deletePost(String postId) async {
    final token = await getToken();
    if (token == null) return false;

    final response = await http.delete(
      Uri.parse('$baseUrl/feed/$postId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return response.statusCode == 200;
  }

  // 10. BEĞENİ
  Future<bool?> toggleLike(String postId) async {
    final token = await getToken();
    if (token == null) return null;

    final response = await http.post(
      Uri.parse('$baseUrl/feed/$postId/like'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['liked'];
    }
    return null;
  }

  // 11. YORUM EKLE
  Future<bool> addComment(String postId, String content) async {
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

// 12. GÖNDERİ GÜNCELLE (Kategori desteği eklendi)
  Future<bool> updatePost(
    String postId,
    String title,
    String content,
    List<String> categories, // 🚨 Kategorileri de parametre olarak ekledik
    String imageUrl,
  ) async {
    final token = await getToken();
    if (token == null) return false;

    final response = await http.put(
      Uri.parse('$baseUrl/feed/$postId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'title': title,
        'content': content,
        'category_ids': categories, // 🚨 Python'a kategorileri gönderiyoruz
        'image_url': imageUrl.isEmpty ? null : imageUrl,
      }),
    );
    // ... geri kalan snackbar kısımları aynı kalabilir ...
    return response.statusCode == 200;
  }
}