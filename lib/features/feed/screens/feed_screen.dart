import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:medium_clone/core/api_service.dart';
import '../../../core/theme_controller.dart';
import '../controllers/feed_controller.dart';
import '../../auth/screens/login_screen.dart';
import '../../post/screens/create_post_screen.dart';
import '../../post/screens/post_detail_screen.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FeedController controller = Get.put(FeedController());

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Keşfet',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          // TEMA BUTONU
          Obx(() {
            final themeController = Get.find<ThemeController>();
            return IconButton(
              icon: Icon(
                themeController.isDarkMode.value
                    ? Icons.light_mode
                    : Icons.dark_mode,
                color: themeController.isDarkMode.value
                    ? Colors.yellow
                    : Colors.black87,
              ),
              onPressed: () => themeController.toggleTheme(),
            );
          }),
          // ÇIKIŞ BUTONU
          Obx(() {
            if (controller.currentUserEmail.value != null) {
              return IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () {
                  Get.defaultDialog(
                    title: 'Çıkış Yap',
                    middleText:
                        'Hesabınızdan çıkış yapmak istediğinize emin misiniz?',
                    textConfirm: 'Evet, Çıkış Yap',
                    textCancel: 'İptal',
                    confirmTextColor: Colors.white,
                    buttonColor: Colors.red,
                    cancelTextColor: Get.isDarkMode
                        ? Colors.white
                        : Colors.black,
                    onConfirm: () async {
                      // 1. Token'ı ve email'i cihazdan KALICI olarak siliyoruz
                      await ApiService().logout();

                      // 2. Kullanıcıyı uygulamadan atıp Login (Giriş) ekranına yönlendiriyoruz.
                      // Get.offAll() kullanıyoruz ki sayfalar arası "Geri" tuşuna basıp tekrar içeri giremesin.
                      Get.offAll(
                        () => const LoginScreen(),
                      ); // Kendi giriş sayfanın adını yaz (Örn: LoginView vb. olabilir)

                      // 3. Ekrana veda mesajını basıyoruz
                      Get.snackbar(
                        'Görüşürüz!',
                        'Başarıyla çıkış yapıldı.',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.grey[800],
                        colorText: Colors.white,
                      );
                    },
                  );
                },
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),

      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            // KATEGORİ ÇİPLERİ (Yatay Liste)
            SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: controller.categories.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: const Text('Tümü'),
                        selected: controller.selectedCategories.isEmpty,
                        onSelected: (_) => controller.filterByCategory(null),
                      ),
                    );
                  }
                  final category = controller.categories[index - 1];
                  final isSelected = controller.selectedCategories.contains(
                    category['name'],
                  );
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(category['name']),
                      selected: isSelected,
                      onSelected: (_) =>
                          controller.filterByCategory(category['name']),
                    ),
                  );
                },
              ),
            ),

            // YAZILARIN LİSTESİ (Sonsuz Kaydırma Ekli)
            Expanded(
              child: controller.posts.isEmpty
                  ? const Center(child: Text('Bu kategoride henüz yazı yok.'))
                  : ListView.builder(
                      controller: controller
                          .scrollController, // 🚨 SCROLL DİNLEYİCİSİ BAĞLANDI
                      // 🚨 En alta loading ikonu veya "Bitti" yazısı koymak için eleman sayısını 1 artırıyoruz
                      itemCount: controller.posts.length + 1,
                      itemBuilder: (context, index) {
                        // EĞER LİSTENİN EN SONUNA (EKTRA EKLEDİĞİMİZ KISMA) GELDİYSEK
                        if (index == controller.posts.length) {
                          return Obx(() {
                            if (controller.isFetchingMore.value) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 24),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            if (!controller.hasMoreData.value &&
                                controller.posts.isNotEmpty) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 24,
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          });
                        }

                        // NORMAL POST KARTI OLUŞTURMA
                        final post = controller.posts[index];
                        final authorData = post['author'];
                        final authorName =
                            (authorData != null &&
                                authorData['username'] != null)
                            ? authorData['username']
                            : (authorData != null
                                  ? authorData['email'].split('@')[0]
                                  : 'Anonim');

                        final rawDate = DateTime.parse(post['created_at']);
                        final formattedDate = DateFormat(
                          'dd MMM yyyy',
                        ).format(rawDate);
                        final imageUrl = post['image_url'];

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              Get.to(() => PostDetailScreen(post: post));
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: Colors.deepPurple,
                                        child: Text(
                                          authorName[0].toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            authorName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          Text(
                                            formattedDate,
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Spacer(),
                                      if (controller.currentUserEmail.value !=
                                              null &&
                                          authorData != null &&
                                          authorData['email'] ==
                                              controller.currentUserEmail.value)
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(
                                                Icons.edit_outlined,
                                                color: Colors.blue,
                                              ),
                                              onPressed: () => Get.to(
                                                () => const CreatePostScreen(),
                                                arguments: post,
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete_outline,
                                                color: Colors.red,
                                              ),
                                              onPressed: () {
                                                Get.dialog(
                                                  AlertDialog(
                                                    title: const Text(
                                                      'Yazıyı Sil',
                                                    ),
                                                    content: const Text(
                                                      'Bu yazıyı kalıcı olarak silmek istediğinize emin misiniz?',
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            Get.back(),
                                                        child: Text(
                                                          'İptal',
                                                          style: TextStyle(
                                                            color:
                                                                Get.isDarkMode
                                                                ? Colors.white
                                                                : Colors.black,
                                                          ),
                                                        ),
                                                      ),
                                                      ElevatedButton(
                                                        style:
                                                            ElevatedButton.styleFrom(
                                                              backgroundColor:
                                                                  Colors.red,
                                                            ),
                                                        onPressed: () async {
                                                          Get.back();
                                                          bool success =
                                                              await controller
                                                                  .deletePost(
                                                                    post['id'],
                                                                  );
                                                          if (success) {
                                                            Get.snackbar(
                                                              'Silindi',
                                                              'Yazınız silindi.',
                                                              backgroundColor:
                                                                  Colors.green,
                                                              colorText:
                                                                  Colors.white,
                                                            );
                                                          }
                                                        },
                                                        child: const Text(
                                                          'Evet, Sil',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  barrierDismissible: false,
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                                if (imageUrl != null)
                                  Image.network(
                                    imageUrl,
                                    width: double.infinity,
                                    height: 200,
                                    fit: BoxFit.cover,
                                  ),
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        post['title'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        post['content'],
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Get.isDarkMode
                                              ? Colors.white70
                                              : Colors.grey[800],
                                          fontSize: 15,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Divider(height: 1),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                    vertical: 12.0,
                                  ),
                                  child: Row(
                                    children: [
                                      InkWell(
                                        onTap: () {
                                          if (controller
                                                  .currentUserEmail
                                                  .value ==
                                              null) {
                                            Get.snackbar(
                                              'Giriş Gerekli',
                                              'Yazıları alkışlamak için giriş yapmalısın.',
                                              backgroundColor: Colors.orange,
                                              colorText: Colors.white,
                                            );
                                            return;
                                          }
                                          controller.toggleLike(post['id']);
                                        },
                                        child: Row(
                                          children: [
                                            Icon(
                                              post['is_liked_by_me'] == true
                                                  ? Icons.recommend
                                                  : Icons.recommend_outlined,
                                              size: 24,
                                              color:
                                                  post['is_liked_by_me'] == true
                                                  ? Colors.red
                                                  : Colors.grey,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              '${post['likes']?.length ?? 0}',
                                              style: TextStyle(
                                                color:
                                                    post['is_liked_by_me'] ==
                                                        true
                                                    ? Colors.red
                                                    : Colors.grey,
                                                fontSize: 16,
                                                fontWeight:
                                                    post['is_liked_by_me'] ==
                                                        true
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 24),
                                      InkWell(
                                        // onTap: () => _showCommentSheet(context, controller, post), // Comment sheet metodun varsa burayı aç
                                        onTap: () {},
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.chat_bubble_outline,
                                              size: 22,
                                              color: Colors.grey,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              '${post['comments']?.length ?? 0}',
                                              style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      }),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (controller.currentUserEmail.value == null) {
            Get.snackbar(
              'Giriş Gerekli',
              'Yazı paylaşmak için lütfen önce giriş yapın.',
              backgroundColor: Colors.orange,
              colorText: Colors.white,
            );
            Get.to(() => const LoginScreen()); // Yolunu projene göre düzelt
          } else {
            Get.to(
              () => const CreatePostScreen(),
            ); // Yolunu projene göre düzelt
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
