import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'bottom_nav_bar.dart';
import 'login_page.dart'; // Импортируем LoginPage для выхода из аккаунта

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  String avatarUrl = "";
  String firstName = "";
  String lastName = "";
  String userEmail = "";
  bool isSportsAppConnected = false; // Новое поле: Подключение спортивного приложения
  String appLanguage = "Русский"; // Новое поле: Язык приложения
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final doc = await _firestore.collection("users").doc(user.uid).get();
    if (doc.exists) {
      setState(() {
        avatarUrl = doc.data()?["avatar"] ?? "";
        firstName = doc.data()?["firstName"] ?? "";
        lastName = doc.data()?["lastName"] ?? "";
        userEmail = doc.data()?["email"] ?? "";
        isSportsAppConnected = doc.data()?["isSportsAppConnected"] ?? false;
        appLanguage = doc.data()?["appLanguage"] ?? "Русский";
      });
    }
  }

  Future<void> _uploadAvatar() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    try {
      File file = File(image.path);
      Reference storageRef = FirebaseStorage.instance.ref().child('users/${user.uid}/avatar.jpg');
      await storageRef.putFile(file);

      String downloadUrl = await storageRef.getDownloadURL();

      await _firestore.collection("users").doc(user.uid).update({"avatar": downloadUrl});

      setState(() {
        avatarUrl = downloadUrl;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Аватар обновлён!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ Ошибка: $e")));
    }
  }

  void _showEditNameDialog() {
    TextEditingController firstNameController = TextEditingController(text: firstName);
    TextEditingController lastNameController = TextEditingController(text: lastName);

    _showEditDialog(
      title: "Изменить имя и фамилию",
      fields: [
        _buildTextField(firstNameController, "Имя"),
        _buildTextField(lastNameController, "Фамилия"),
      ],
      onSave: () async {
        final user = _auth.currentUser;
        if (user == null) return;

        await _firestore.collection("users").doc(user.uid).update({
          "firstName": firstNameController.text,
          "lastName": lastNameController.text,
        });

        _loadUserData();
      },
    );
  }

  void _showEditEmailDialog() {
    TextEditingController currentEmailController = TextEditingController();
    TextEditingController newEmailController = TextEditingController();
    TextEditingController confirmNewEmailController = TextEditingController();

    _showEditDialog(
      title: "Изменить Email",
      fields: [
        _buildTextField(currentEmailController, "Текущий Email"),
        _buildTextField(newEmailController, "Новый Email"),
        _buildTextField(confirmNewEmailController, "Повторите новый Email"),
      ],
      onSave: () async {
        final user = _auth.currentUser;
        if (user == null) return;

        if (newEmailController.text == confirmNewEmailController.text) {
          await user.updateEmail(newEmailController.text);
          await _firestore.collection("users").doc(user.uid).update({"email": newEmailController.text});
          _loadUserData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("❌ Email не совпадает!")));
        }
      },
    );
  }

  void _showEditPasswordDialog() {
    TextEditingController currentPasswordController = TextEditingController();
    TextEditingController newPasswordController = TextEditingController();
    TextEditingController confirmNewPasswordController = TextEditingController();

    _showEditDialog(
      title: "Изменить пароль",
      fields: [
        _buildTextField(currentPasswordController, "Текущий пароль", obscureText: true),
        _buildTextField(newPasswordController, "Новый пароль", obscureText: true),
        _buildTextField(confirmNewPasswordController, "Повторите новый пароль", obscureText: true),
      ],
      onSave: () async {
        final user = _auth.currentUser;
        if (user == null) return;

        if (newPasswordController.text == confirmNewPasswordController.text) {
          await user.updatePassword(newPasswordController.text);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("❌ Пароли не совпадают!")));
        }
      },
    );
  }

  void _toggleSportsAppConnection() {
    // Показываем уведомление, что функциональность в разработке
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("🚧 Функциональность в разработке!")),
    );
  }

  void _showLanguageSelectionDialog() {
    final List<String> languages = ["Русский", "English", "Deutsch", "Español"];
    String selectedLanguage = appLanguage;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Выберите язык"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: languages.map((language) {
              return RadioListTile(
                title: Text(language),
                value: language,
                groupValue: selectedLanguage,
                onChanged: (value) {
                  setState(() {
                    selectedLanguage = value.toString();
                  });
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Отмена"),
            ),
            TextButton(
              onPressed: () async {
                final user = _auth.currentUser;
                if (user == null) return;

                await _firestore.collection("users").doc(user.uid).update({
                  "appLanguage": selectedLanguage,
                });

                setState(() {
                  appLanguage = selectedLanguage;
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("✅ Язык изменён на $selectedLanguage!")),
                );

                Navigator.of(context).pop();
              },
              child: const Text("Сохранить"),
            ),
          ],
        );
      },
    );
  }

  void _logout() async {
    // Запрос подтверждения перед выходом из аккаунта
    bool confirmLogout = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Подтверждение выхода"),
          content: const Text("Вы действительно хотите выйти из аккаунта?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Отмена
              },
              child: const Text("Нет", style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Подтверждение
              },
              child: const Text("Да", style: TextStyle(color: Colors.green)),
            ),
          ],
        );
      },
    );

    if (confirmLogout != true) return; // Если пользователь не подтвердил выход

    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  void _deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Запрос подтверждения перед удалением аккаунта
    bool confirmDelete = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Подтверждение удаления"),
          content: const Text("Вы действительно хотите удалить аккаунт? Это действие нельзя отменить."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Отмена
              },
              child: const Text("Нет", style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Подтверждение
              },
              child: const Text("Да", style: TextStyle(color: Colors.green)),
            ),
          ],
        );
      },
    );

    if (confirmDelete != true) return; // Если пользователь не подтвердил удаление

    try {
      // Удаление данных из Firestore
      await _firestore.collection("users").doc(user.uid).delete();

      // Удаление аватарки из Firebase Storage
      try {
        Reference storageRef = FirebaseStorage.instance.ref().child('users/${user.uid}/avatar.jpg');
        await storageRef.delete();
      } catch (e) {
        print("Ошибка при удалении аватарки: $e");
      }

      // Удаление пользователя из Firebase Authentication
      await user.delete();

      // Удаление пользователя из массива members в коллекции teams
      final teamsQuery = await _firestore.collection("teams").where("members", arrayContains: user.uid).get();
      for (var teamDoc in teamsQuery.docs) {
        await _firestore.collection("teams").doc(teamDoc.id).update({
          "members": FieldValue.arrayRemove([user.uid]),
        });
        print("Пользователь удален из команды: ${teamDoc.id}");
      }

      // Показываем уведомление об успешном удалении
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Аккаунт удален!")));

      // Перенаправляем пользователя на экран входа или главный экран
      Navigator.of(context).pushReplacementNamed('/login');
    } catch (e) {
      print("Ошибка при удалении аккаунта: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ Ошибка: $e")));
    }
  }

  void _showEditDialog({
    required String title,
    required List<Widget> fields,
    required VoidCallback onSave,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: fields,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Отмена", style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () {
                onSave();
                Navigator.of(context).pop();
              },
              child: const Text("Сохранить", style: TextStyle(color: Colors.green)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool obscureText = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          filled: true,
          fillColor: Colors.grey[200],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Stack(
          alignment: Alignment.center,
          children: [
            const Center(
              child: Text(
                "Редактирование профиля",
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.yellow.shade600,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  GestureDetector(
                    onTap: _uploadAvatar,
                    child: CircleAvatar(
                      radius: 60,
                      backgroundImage: avatarUrl.isNotEmpty
                          ? NetworkImage(avatarUrl)
                          : const AssetImage("assets/default_avatar.png") as ImageProvider,
                      backgroundColor: Colors.transparent,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    "$firstName $lastName",
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  _buildSettingItem(Icons.account_circle, "Изменить имя и фамилию", _showEditNameDialog),
                  _buildSettingItem(Icons.mail, "Изменить Email", _showEditEmailDialog),
                  _buildSettingItem(Icons.lock, "Изменить пароль", _showEditPasswordDialog),
                  _buildSettingItem(
                    Icons.sports,
                    isSportsAppConnected ? "Отключить спортивное приложение" : "Подключить спортивное приложение",
                    _toggleSportsAppConnection,
                  ),
                  _buildSettingItem(Icons.language, "Язык приложения: $appLanguage", _showLanguageSelectionDialog),
                  _buildSettingItem(Icons.logout, "Выйти из аккаунта", _logout, isDestructive: true),
                  _buildSettingItem(Icons.delete, "Удалить аккаунт", _deleteAccount, isDestructive: true),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: 3, onDestinationSelected: (_) {}),
    );
  }

  Widget _buildSettingItem(IconData icon, String title, VoidCallback onTap, {bool isDestructive = false}) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: ListTile(
          leading: Icon(icon, color: isDestructive ? Colors.red : Colors.black),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: isDestructive ? Colors.red : Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}