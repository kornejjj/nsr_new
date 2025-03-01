import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'bottom_nav_bar.dart'; // Импортируем BottomNavBar

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  String avatarUrl = "";
  String userName = "Loading...";
  int _currentIndex = 3; // Текущий индекс для BottomNavBar

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // 📌 Загружаем данные пользователя из Firestore
  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance.collection("users").doc(user.uid).get();
    if (doc.exists) {
      setState(() {
        avatarUrl = doc.data()?["avatar"] ?? "";
        userName = "${doc.data()?["firstName"] ?? ""} ${doc.data()?["lastName"] ?? ""}";
      });
    }
  }

  // 📌 Загружаем новый аватар
  Future<void> _uploadAvatar() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    try {
      File file = File(image.path);
      Reference storageRef = FirebaseStorage.instance.ref().child('users/${user.uid}/avatar.jpg');
      await storageRef.putFile(file);

      String downloadUrl = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance.collection("users").doc(user.uid).update({
        "avatar": downloadUrl
      });

      setState(() {
        avatarUrl = downloadUrl;
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Аватар обновлён!")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ Ошибка: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil bearbeiten"),
        backgroundColor: Colors.yellow.shade600,
        elevation: 0,
        automaticallyImplyLeading: false, // Убираем стрелку назад
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  _buildSettingItem(
                    context,
                    icon: Icons.account_circle_rounded,
                    title: "Name ändern",
                    onTap: () => _navigateTo(context, "name"),
                  ),
                  _buildSettingItem(
                    context,
                    icon: Icons.mail_rounded,
                    title: "E-Mail ändern",
                    onTap: () => _navigateTo(context, "email"),
                  ),
                  _buildSettingItem(
                    context,
                    icon: Icons.lock_rounded,
                    title: "Passwort ändern",
                    onTap: () => _navigateTo(context, "password"),
                  ),
                  _buildSettingItem(
                    context,
                    icon: Icons.visibility_rounded,
                    title: "Sichtbarkeit",
                    onTap: () => _navigateTo(context, "visibility"),
                  ),
                  _buildSettingItem(
                    context,
                    icon: Icons.notifications_active_rounded,
                    title: "Benachrichtigungen",
                    onTap: () => _navigateTo(context, "notifications"),
                  ),
                  _buildSettingItem(
                    context,
                    icon: Icons.delete_forever_rounded,
                    title: "Konto löschen",
                    isDestructive: true,
                    onTap: () => _showDeleteConfirmation(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        GestureDetector(
          onTap: _uploadAvatar,
          child: Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: avatarUrl.isNotEmpty
                    ? NetworkImage(avatarUrl)
                    : const AssetImage("assets/profile.jpg") as ImageProvider,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.blue,
                  child: const Icon(Icons.edit, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          userName,
          style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildSettingItem(
      BuildContext context, {
        required IconData icon,
        required String title,
        required VoidCallback onTap,
        bool isDestructive = false,
      }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: ListTile(
        leading: Icon(icon, size: 28, color: isDestructive ? Colors.red : Theme.of(context).iconTheme.color),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isDestructive ? Colors.red : Theme.of(context).textTheme.bodyLarge!.color,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  void _navigateTo(BuildContext context, String page) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Navigating to: $page")),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Konto löschen"),
          content: const Text("Bist du sicher, dass du dein Konto dauerhaft löschen möchtest?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Abbrechen"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Konto gelöscht")),
                );
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text("Löschen"),
            ),
          ],
        );
      },
    );
  }
}