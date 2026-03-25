import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/login_controller.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Controller'ı ekrana bağlıyoruz.
    final LoginController controller = Get.put(LoginController());

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 30),
          onPressed: () => Get.back(),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Obx(() => Text(
                controller.isLoginMode.value ? 'Tekrar Hoş Geldin' : 'Aramıza Katıl',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              )),
              const SizedBox(height: 40),

              // KULLANICI ADI KUTUSU (Sadece Kayıt modunda görünür)
              Obx(() {
                if (!controller.isLoginMode.value) {
                  return Column(
                    children: [
                      TextField(
                        controller: controller.usernameController,
                        decoration: const InputDecoration(labelText: 'Kullanıcı Adı', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                }
                return const SizedBox.shrink(); // Boşluk kaplamaması için
              }),

              // E-POSTA
              TextField(
                controller: controller.emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'E-posta', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email)),
              ),
              const SizedBox(height: 16),

              // ŞİFRE
              TextField(
                controller: controller.passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Şifre', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock)),
              ),
              const SizedBox(height: 24),

              // ANA BUTON (Yükleniyor veya Buton yazısı değişeceği için Obx ile sarıldı)
              SizedBox(
                height: 50,
                child: Obx(() => ElevatedButton(
                  onPressed: controller.isLoading.value ? null : controller.submit,
                  child: controller.isLoading.value
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          controller.isLoginMode.value ? 'Giriş Yap' : 'Kayıt Ol',
                          style: const TextStyle(fontSize: 18),
                        ),
                )),
              ),
              const SizedBox(height: 16),

              // MOD DEĞİŞTİRME BUTONU
              Obx(() => TextButton(
                onPressed: controller.toggleMode,
                child: Text(
                  controller.isLoginMode.value
                      ? 'Hesabın yok mu? Yeni hesap oluştur.'
                      : 'Zaten hesabın var mı? Giriş yap.',
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }
}