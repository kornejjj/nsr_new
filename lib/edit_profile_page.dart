import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'bottom_nav_bar.dart';

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

  void _deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection("users").doc(user.uid).delete();
    await user.delete();

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Аккаунт удален!")));
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
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: fields,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Отмена")),
            TextButton(onPressed: () { onSave(); Navigator.of(context).pop(); }, child: const Text("Сохранить")),
          ],
        );
      },
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool obscureText = false}) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(labelText: label),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text("Редактирование профиля")),
        backgroundColor: Colors.yellow.shade600,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          children: [
            GestureDetector(
              onTap: _uploadAvatar,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: avatarUrl.isNotEmpty
                    ? NetworkImage(avatarUrl)
                    : const AssetImage("assets/profile.jpg") as ImageProvider,
              ),
            ),
            const SizedBox(height: 10),
            Text("$firstName $lastName", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _buildSettingItem(Icons.account_circle, "Изменить имя и фамилию", _showEditNameDialog),
            _buildSettingItem(Icons.mail, "Изменить Email", _showEditEmailDialog),
            _buildSettingItem(Icons.lock, "Изменить пароль", _showEditPasswordDialog),
            _buildSettingItem(Icons.delete, "Удалить аккаунт", _deleteAccount, isDestructive: true),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: 3, onDestinationSelected: (_) {}),
    );
  }

  Widget _buildSettingItem(IconData icon, String title, VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? Colors.red : Colors.black),
      title: Text(title, style: TextStyle(color: isDestructive ? Colors.red : Colors.black)),
      onTap: onTap,
    );
  }
}
