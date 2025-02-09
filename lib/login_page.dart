/*
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  String _errorMessage = '';

  void _login() {
    if (_formKey.currentState!.validate()) {
      bool loginSuccess = true; // Симуляция успешного входа

      if (loginSuccess) {
        Navigator.pushReplacementNamed(context, '/main');
      } else {
        setState(() {
          _errorMessage = "Falsche E-Mail oder Passwort";
        });
      }
    }
  }

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
        fillColor: Colors.grey[200],
        border: OutlineInputBorder(borderRadius: BorderRadius.zero),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
          onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
        )
            : null,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "Dieses Feld darf nicht leer sein";
        }
        if (!isPassword && !value.contains("@")) {
          return "Ungültige E-Mail";
        }
        if (isPassword && value.length < 6) {
          return "Mindestens 6 Zeichen";
        }
        return null;
      },
    );
  }

  Widget _buildButton({
    required String text,
    required VoidCallback onPressed,
    bool isPrimary = false,
  }) {
    return SizedBox(
      width: double.infinity,
      child: isPrimary
          ? ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber, // 💛 Желтая кнопка!
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
        child: Text(text),
      )
          : OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.black,
          side: BorderSide(color: Colors.black),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
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
                      color: Colors.amber, // 💛 Желтый заголовок
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(controller: _emailController, label: "E-Mail"),
                  const SizedBox(height: 10),
                  _buildTextField(controller: _passwordController, label: "Passwort", isPassword: true),
                  const SizedBox(height: 10),
                  if (_errorMessage.isNotEmpty)
                    Text(_errorMessage, style: TextStyle(color: Colors.red)),
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
*/
