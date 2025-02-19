
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key}); // ✅ Добавлен key

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false; // ✅ Добавлен индикатор загрузки
  String? _errorMessage;

  /// ✅ Функция входа
  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true); // Показать индикатор загрузки

      await Future.delayed(const Duration(seconds: 2)); // Симуляция запроса

      setState(() {
        _isLoading = false;
        bool loginSuccess = _emailController.text == "test@example.com" && _passwordController.text == "123456";

        if (loginSuccess) {
          Navigator.pushReplacementNamed(context, '/main');
        } else {
          _errorMessage = "Falsche E-Mail oder Passwort";
        }
      });
    }
  }

  /// ✅ Текстовое поле
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool isPassword = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && !_isPasswordVisible,
      keyboardType: isPassword ? TextInputType.visiblePassword : TextInputType.emailAddress,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[200],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        suffixIcon: isPassword
            ? AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                child: IconButton(
                  key: ValueKey<bool>(_isPasswordVisible),
                  icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                ),
              )
            : null,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "Dieses Feld darf nicht leer sein";
        }
        if (!isPassword && !RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$").hasMatch(value)) {
          return "Ungültige E-Mail";
        }
        if (isPassword && value.length < 6) {
          return "Mindestens 6 Zeichen";
        }
        return null;
      },
    );
  }

  /// ✅ Кнопка (с поддержкой загрузки)
  Widget _buildButton({
    required String text,
    required VoidCallback onPressed,
    bool isPrimary = false,
  }) {
    return SizedBox(
      width: double.infinity,
      child: isPrimary
          ? ElevatedButton(
              onPressed: _isLoading ? null : onPressed, // 🔄 Блокируем кнопку во время загрузки
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                    )
                  : Text(text),
            )
          : OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black,
                side: const BorderSide(color: Colors.black),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(text),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Anmeldung",
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(controller: _emailController, label: "E-Mail"),
                  const SizedBox(height: 10),
                  _buildTextField(controller: _passwordController, label: "Passwort", isPassword: true),
                  const SizedBox(height: 10),
                  if (_errorMessage != null)
                    Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 20),
                  _buildButton(text: "Anmelden", onPressed: _login, isPrimary: true),
                  const SizedBox(height: 10),
                  _buildButton(text: "Registrieren", onPressed: () => Navigator.pushNamed(context, '/register')),
                  const SizedBox(height: 10),
                  _buildButton(text: "Passwort vergessen?", onPressed: () => Navigator.pushNamed(context, '/reset_password')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}



