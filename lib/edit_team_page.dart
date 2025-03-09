import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'bottom_nav_bar.dart';
import 'team_selection_page.dart';

class EditTeamPage extends StatefulWidget {
  final String teamId;

  const EditTeamPage({super.key, required this.teamId});

  @override
  _EditTeamPageState createState() => _EditTeamPageState();
}

class _EditTeamPageState extends State<EditTeamPage> {
  String teamName = "Loading...";
  String teamAvatarUrl = "";
  final TextEditingController _teamNameController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTeamData();
  }

  Future<void> _loadTeamData() async {
    try {
      final teamDoc =
      await FirebaseFirestore.instance.collection('teams').doc(widget.teamId).get();

      if (teamDoc.exists) {
        setState(() {
          teamName = teamDoc['name'] ?? "Без названия";
          teamAvatarUrl = teamDoc['avatar'] ?? "";
          _teamNameController.text = teamName;
          _isLoading = false;
        });
      } else {
        _handleTeamNotFound();
      }
    } catch (e) {
      _handleTeamNotFound();
    }
  }

  void _handleTeamNotFound() {
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Команда не найдена")),
    );
  }

  Future<void> _uploadTeamAvatar() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() => _isLoading = true);

    try {
      File file = File(image.path);
      Reference storageRef =
      FirebaseStorage.instance.ref().child('teams/${widget.teamId}/avatar.jpg');
      await storageRef.putFile(file);

      String downloadUrl = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('teams')
          .doc(widget.teamId)
          .update({'avatar': downloadUrl});

      setState(() {
        teamAvatarUrl = downloadUrl;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Фото команды обновлено!")),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Ошибка: $e")),
      );
    }
  }

  Future<void> _updateTeamName() async {
    if (_teamNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Введите название команды")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('teams')
          .doc(widget.teamId)
          .update({'name': _teamNameController.text});

      setState(() {
        teamName = _teamNameController.text;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Название команды обновлено!")),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Ошибка: $e")),
      );
    }
  }

  Future<void> _leaveTeam() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('teams')
          .doc(widget.teamId)
          .update({
        'members': FieldValue.arrayRemove([user.uid]),
      });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'teamId': FieldValue.delete()});

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => TeamSelectionPage()),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Вы покинули команду!")),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Ошибка: $e")),
      );
    }
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
                "Редактирование команды",
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold, color: Colors.black),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.yellow.shade600,
        elevation: 0,
        automaticallyImplyLeading: false, // Убираем стрелку назад
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: 2, onDestinationSelected: (_) {}),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _uploadTeamAvatar,
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 56,
                  backgroundImage: teamAvatarUrl.isNotEmpty
                      ? NetworkImage(teamAvatarUrl)
                      : const AssetImage("assets/team_logo.png") as ImageProvider,
                  child: const Icon(Icons.edit, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _teamNameController,
              decoration: InputDecoration(
                labelText: "Название команды",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: _updateTeamName,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _leaveTeam,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text("Покинуть команду"),
            ),
          ],
        ),
      ),
    );
  }
}