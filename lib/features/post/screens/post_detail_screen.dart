import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../feed/controllers/feed_controller.dart';

class PostDetailScreen extends StatelessWidget {
  final dynamic post;
  const PostDetailScreen({super.key, required this.post});

  // Yorum penceresini FeedScreen'deki gibi buraya da ekliyoruz
  void _showCommentSheet(
    BuildContext context,
    FeedController controller,
    dynamic currentPost,
  ) {
    final TextEditingController commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final comments = currentPost['comments'] as List<dynamic>? ?? [];
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 16,
            left: 16,
            right: 16,
          ),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Column(
              children: [
                const Text(
                  'Yanıtlar',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Divider(),
                Expanded(
                  child: comments.isEmpty
                      ? const Center(
                          child: Text('Henüz yanıt yok. İlk sen ol!'),
                        )
                      : ListView.builder(
                          itemCount: comments.length,
                          itemBuilder: (context, index) {
                            final comment = comments[index];
                            final authorData = comment['author'];
                            final authorName =
                                (authorData != null &&
                                    authorData['username'] != null)
                                ? authorData['username']
                                : authorData['email'].split('@')[0];

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.deepPurple[100],
                                child: Text(
                                  authorName[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.deepPurple,
                                  ),
                                ),
                              ),
                              title: Text(
                                authorName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(comment['content']),
                            );
                          },
                        ),
                ),
                if (controller.currentUserEmail.value != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: commentController,
                            decoration: const InputDecoration(
                              hintText: 'Düşüncelerini paylaş...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(20),
                                ),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.send,
                            color: Colors.deepPurple,
                          ),
                          onPressed: () async {
                            final text = commentController.text.trim();
                            if (text.isNotEmpty) {
                              bool success = await controller.addComment(
                                currentPost['id'],
                                text,
                              );
                              if (success) {
                                Get.back();
                                Get.snackbar(
                                  'Başarılı',
                                  'Yanıtınız eklendi!',
                                  backgroundColor: Colors.green,
                                  colorText: Colors.white,
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Yanıt yazmak için giriş yapmalısınız.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // FeedController'ı yakalıyoruz ki beğeni ve yorumları buradan da tetikleyebilelim
    final FeedController controller = Get.find<FeedController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Yazıyı Oku')),
      // Obx ile sarmalıyoruz ki içeride beğeni/yorum yaparsak sayfa anında güncellensin!
      body: Obx(() {
        // En güncel post verisini controller'dan çekiyoruz
        final currentPost = controller.posts.firstWhere(
          (p) => p['id'] == post['id'],
          orElse: () => post, // Eğer bulamazsa ilk gelen veriyi kullan
        );

        final authorData = currentPost['author'];
        final authorName =
            (authorData != null && authorData['username'] != null)
            ? authorData['username']
            : (authorData != null
                  ? authorData['email'].split('@')[0]
                  : 'Anonim');
        final rawDate = DateTime.parse(currentPost['created_at']);
        final formattedDate = DateFormat('dd MMM yyyy').format(rawDate);
        final imageUrl = currentPost['image_url'];

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (imageUrl != null)
                Image.network(
                  imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),

              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentPost['title'],
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.deepPurple,
                          child: Text(
                            authorName[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Divider(),
                    ),

                    Text(
                      currentPost['content'],
                      style: TextStyle(
                        fontSize: 17,
                        height: 1.6,
                        color: Get.isDarkMode ? Colors.white70 : Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 32),
                    const Divider(),
                    const SizedBox(height: 8),

                    // 🚨 BURAYA BEĞENİ VE YORUM BUTONLARINI EKLEDİK 🚨
                    Row(
                      children: [
                        InkWell(
                          onTap: () {
                            if (controller.currentUserEmail.value == null) {
                              Get.snackbar(
                                'Giriş Gerekli',
                                'Yazıları alkışlamak için giriş yapmalısın.',
                                backgroundColor: Colors.orange,
                                colorText: Colors.white,
                              );
                              return;
                            }
                            controller.toggleLike(currentPost['id']);
                          },
                          child: Row(
                            children: [
                              Icon(
                                currentPost['is_liked_by_me'] == true
                                    ? Icons.recommend
                                    : Icons.recommend_outlined,
                                size:
                                    28, // Detay sayfasında ikonlar daha belirgin
                                color: currentPost['is_liked_by_me'] == true
                                    ? Colors.red
                                    : Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${currentPost['likes']?.length ?? 0}',
                                style: TextStyle(
                                  color: currentPost['is_liked_by_me'] == true
                                      ? Colors.red
                                      : Colors.grey,
                                  fontSize: 18,
                                  fontWeight:
                                      currentPost['is_liked_by_me'] == true
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 32),
                        InkWell(
                          onTap: () => _showCommentSheet(
                            context,
                            controller,
                            currentPost,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.chat_bubble_outline,
                                size: 26,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${currentPost['comments']?.length ?? 0}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
