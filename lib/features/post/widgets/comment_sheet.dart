import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../feed/controllers/feed_controller.dart';

class CommentSheet {
  static void show(
    BuildContext context,
    FeedController controller,
    dynamic post,
  ) {
    final TextEditingController commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final comments = post['comments'] as List<dynamic>? ?? [];
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

                // YORUM LİSTESİ
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

                // YORUM YAZMA ALANI (Sadece giriş yapılmışsa görünür)
                controller.currentUserEmail.value != null
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: commentController,
                                decoration: const InputDecoration(
                                  hintText: 'Düşüncelerini paylaş...',
                                  border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(20)),
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
                                    post['id'],
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
                    : const Padding(
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
}
