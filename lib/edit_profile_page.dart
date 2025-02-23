import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  File? _image;

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil bearbeiten"),
        backgroundColor: Colors.yellow.shade600,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          children: [
            _buildProfileHeader(context),
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

  Widget _buildProfileHeader(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              builder: (BuildContext context) {
                return SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.photo_library),
                        title: const Text('Aus Galerie auswählen'),
                        onTap: () {
                          _pickImage(ImageSource.gallery);
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.camera_alt),
                        title: const Text('Foto aufnehmen'),
                        onTap: () {
                          _pickImage(ImageSource.camera);
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
          child: CircleAvatar(
            radius: 50,
            backgroundImage: _image != null ? FileImage(_image!) : const AssetImage("assets/profile.jpg") as ImageProvider,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          "Max Mustermann",
          style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          "🚀 Team Germany 🇩🇪",
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.grey),
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