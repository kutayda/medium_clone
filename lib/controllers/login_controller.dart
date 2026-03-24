import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/api_service.dart';
import '../screens/feed_screen.dart';

class LoginController extends GetxController{
  final ApiService _apiService = ApiService();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final usernameController = TextEditingController();

  var isLoginMode = true.obs;
  var isLoading = false.obs;

  void toggleMode(){
    isLoginMode.value = !isLoginMode.value;
  }

  Future<void> submit() async{
    isLoading.value = true; 

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if(isLoginMode.value){
      //Giriş Yapma İşlemi
      bool success = await _apiService.login(email,password);
      if(success){
        Get.snackbar('','Giriş Başarılı r', backgroundColor: Colors.green, colorText: Colors.white);
        Get.offAll(() => const FeedScreen());
      } else {
        Get.snackbar('Hata', 'Giriş yapılırken bir hata oluştu', backgroundColor: Colors.red, colorText: Colors.white); 
      }
    }else{
      //Kayıt Olma İşlemi 
      final username = usernameController.text.trim();  
      bool success = await _apiService.register(email, password, username);
      if (success){
        Get.snackbar('Kayıt Basarılı', 'Kayıt olma işlemi basarılı', backgroundColor: Colors.green, colorText: Colors.white);
        isLoginMode.value = true;
        passwordController.clear();
      }else{
        Get.snackbar('Hata', 'Kayıt olma işlemi basarısız', backgroundColor: Colors.red, colorText: Colors.white);
      }
    }

    isLoading.value = false;
  }
  
  @override
  void onClose(){
    emailController.dispose();
    passwordController.dispose();
    usernameController.dispose();
    super.onClose();  
  }
}