// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';

class ApiService {
  // ✅ baseUrl ve imgbbApiKey artık .env'den okunuyor
  static final String baseUrl = dotenv.env['BASE_URL'] ?? 'http://10.0.2.2:8000';
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
      debugPrint("Login Hatası: $e");
      return false;
    }
  }

  // 2. KAYIT OLMA ✅ try-catch eklendi
  Future<bool> register(String email, String password, String username) async {
    try {
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
    } catch (e) {
      debugPrint("Register Hatası: $e");
      return false;
    }
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
      debugPrint("Kategori çekme hatası: $e");
    }
    return [];
  }

  // 6. AKIŞI GETİR (Filtreli ve Güvenli URL)
  Future<List<dynamic>?> getFeed({List<String>? selectedCategories}) async {
    final token = await getToken();

    var uri = Uri.parse('$baseUrl/feed');

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
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
    } catch (e) {
      debugPrint("Feed çekme hatası: $e");
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

    debugPrint("🚀 API'YE GİDEN KATEGORİLER: $categories");

    final response = await http.post(
      Uri.parse('$baseUrl/upload'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'title': title,
        'content': content,
        'category_ids': categories,
        'image_url': imageUrl.isEmpty ? null : imageUrl,
      }),
    );
    return response.statusCode == 200;
  }

  // 8. BULUTA GÖRSEL YÜKLEME (ImgBB) ✅ Key artık .env'den okunuyor
  Future<String?> uploadImageToCloud(File imageFile) async {
    final String imgbbApiKey = dotenv.env['IMGBB_API_KEY'] ?? '';
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.imgbb.com/1/upload?key=$imgbbApiKey'),
      );
      request.files
          .add(await http.MultipartFile.fromPath('image', imageFile.path));
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonResult = jsonDecode(responseData);

      if (response.statusCode == 200) {
        return jsonResult['data']['url'];
      }
    } catch (e) {
      debugPrint('Görsel yükleme hatası: $e');
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

  // 12. GÖNDERİ GÜNCELLE
  Future<bool> updatePost(
    String postId,
    String title,
    String content,
    List<String> categories,
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
        'category_ids': categories,
        'image_url': imageUrl.isEmpty ? null : imageUrl,
      }),
    );
    return response.statusCode == 200;
  }
}
