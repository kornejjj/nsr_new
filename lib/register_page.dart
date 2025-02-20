import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart';
import 'main_page.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String? _errorMessage;

  /// 🔥 **Функция регистрации пользователя**
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordController.text.trim() != _confirmPasswordController.text.trim()) {
      setState(() => _errorMessage = "Пароли не совпадают");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // ✅ Регистрируем пользователя в Firebase
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // ✅ Сохраняем данные пользователя в Firestore
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'uid': userCredential.user!.uid,
        'avatar': 'assets/default_avatar.png',
        'points': 0,
      });

      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MainPage()));
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFD54F), Color(0xFFFFE082), Color(0xFFFFF9C4)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  /// 📌 **Логотип**
                  Image.asset('assets/logo.png', height: 100),

                  const SizedBox(height: 20),

                  const Text(
                    "Создайте аккаунт",
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black),
                  ),

                  const SizedBox(height: 30),

                  /// 📌 **Поле Имя**
                  _buildTextField(_firstNameController, "Имя", false),

                  const SizedBox(height: 15),

                  /// 📌 **Поле Фамилия**
                  _buildTextField(_lastNameController, "Фамилия", false),

                  const SizedBox(height: 15),

                  /// 📌 **Поле Email**
                  _buildTextField(_emailController, "E-Mail", false),

                  const SizedBox(height: 15),

                  /// 📌 **Поле Пароль**
                  _buildTextField(_passwordController, "Пароль", true),

                  const SizedBox(height: 15),

                  /// 📌 **Поле Подтверждение пароля**
                  _buildTextField(_confirmPasswordController, "Повторите пароль", true),

                  const SizedBox(height: 10),

                  /// 🔥 **Ошибка**
                  if (_errorMessage != null)
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                    ),

                  const SizedBox(height: 20),

                  /// 📌 **Кнопка "Создать аккаунт"**
                  _buildPrimaryButton("Создать аккаунт", _register),

                  const SizedBox(height: 10),

                  /// 📌 **Кнопка "Уже есть аккаунт? Войти"**
                  _buildSecondaryButton("Уже есть аккаунт? Войти", () {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginPage()));
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 📌 **Поле ввода (Имя, Фамилия, Email, Пароль)**
  Widget _buildTextField(TextEditingController controller, String label, bool isPassword) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && !_isPasswordVisible,
      keyboardType: isPassword ? TextInputType.visiblePassword : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
          onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
        )
            : null,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "Поле не должно быть пустым";
        }
        if (!isPassword && label == "E-Mail" && !RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$").hasMatch(value)) {
          return "Некорректный email";
        }
        if (isPassword && value.length < 6) {
          return "Минимум 6 символов";
        }
        return null;
      },
    );
  }

  /// 📌 **Основная кнопка (жёлтая)**
  Widget _buildPrimaryButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: _isLoading
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : Text(text, style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  /// 📌 **Второстепенная кнопка (контурная)**
  Widget _buildSecondaryButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.black,
          side: const BorderSide(color: Colors.black),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(text, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}
