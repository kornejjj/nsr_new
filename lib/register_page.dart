import 'package:flutter/material.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  String _errorMessage = '';

  void _register() {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text.trim() != _confirmPasswordController.text.trim()) {
        setState(() {
          _errorMessage = "Passwörter stimmen nicht überein";
        });
        return;
      }
      // Логика регистрации без Firebase
      Navigator.pushReplacementNamed(context, '/team-selection');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Registrierung", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                SizedBox(height: 20),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(labelText: "E-Mail"),
                  validator: (value) => value!.contains("@") ? null : "Ungültige E-Mail",
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(labelText: "Passwort"),
                  obscureText: true,
                  validator: (value) => value!.length >= 6 ? null : "Mindestens 6 Zeichen",
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(labelText: "Passwort bestätigen"),
                  obscureText: true,
                ),
                SizedBox(height: 10),
                if (_errorMessage.isNotEmpty)
                  Text(_errorMessage, style: TextStyle(color: Colors.red)),
                SizedBox(height: 20),
                ElevatedButton(onPressed: _register, child: Text("Registrieren")),
                TextButton(onPressed: () => Navigator.pop(context), child: Text("Bereits registriert? Anmelden")),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
