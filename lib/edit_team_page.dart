import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'bottom_nav_bar.dart'; // Импортируем BottomNavBar
import 'team_selection_page.dart'; // Импортируем TeamSelectionPage

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
  int _currentIndex = 2; // Текущий индекс для BottomNavBar
  bool _isLoading = true; // Состояние загрузки

  @override
  void initState() {
    super.initState();
    _loadTeamData();
  }

  // 📌 Загружаем данные команды
  Future<void> _loadTeamData() async {
    try {
      final teamDoc = await FirebaseFirestore.instance
          .collection('teams')
          .doc(widget.teamId)
          .get();

      if (teamDoc.exists) {
        setState(() {
          teamName = teamDoc['name'] ?? "Без названия";
          teamAvatarUrl = teamDoc['avatar'] ?? "";
          _teamNameController.text = teamName;
          _isLoading = false; // Данные загружены
        });
      } else {
        setState(() {
          _isLoading = false; // Данные не найдены
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Команда не найдена")),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false; // Ошибка загрузки
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ошибка загрузки данных: $e")),
      );
    }
  }

  // 📌 Загружаем новое фото команды
  Future<void> _uploadTeamAvatar() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() {
      _isLoading = true; // Начало загрузки
    });

    try {
      File file = File(image.path);
      Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('teams/${widget.teamId}/avatar.jpg');
      await storageRef.putFile(file);

      String downloadUrl = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('teams')
          .doc(widget.teamId)
          .update({'avatar': downloadUrl});

      setState(() {
        teamAvatarUrl = downloadUrl;
        _isLoading = false; // Загрузка завершена
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Фото команды обновлено!")),
      );
    } catch (e) {
      setState(() {
        _isLoading = false; // Ошибка загрузки
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Ошибка: $e")),
      );
    }
  }

  // 📌 Обновляем имя команды
  Future<void> _updateTeamName() async {
    if (_teamNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Введите название команды")),
      );
      return;
    }

    setState(() {
      _isLoading = true; // Начало обновления
    });

    try {
      await FirebaseFirestore.instance
          .collection('teams')
          .doc(widget.teamId)
          .update({'name': _teamNameController.text});

      setState(() {
        teamName = _teamNameController.text;
        _isLoading = false; // Обновление завершено
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Название команды обновлено!")),
      );
    } catch (e) {
      setState(() {
        _isLoading = false; // Ошибка обновления
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Ошибка: $e")),
      );
    }
  }

  // 📌 Покинуть команду
  Future<void> _leaveTeam() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _isLoading = true; // Начало процесса
    });

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
      setState(() {
        _isLoading = false; // Ошибка
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Ошибка: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(teamName), // Отображаем текущее название команды
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // Индикатор загрузки
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _uploadTeamAvatar,
              child: CircleAvatar(
                radius: 60,
                backgroundImage: teamAvatarUrl.isNotEmpty
                    ? NetworkImage(teamAvatarUrl)
                    : const AssetImage("assets/team_logo.png") as ImageProvider,
                child: const Icon(Icons.edit, color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _teamNameController,
              decoration: InputDecoration(
                labelText: "Название команды",
                border: OutlineInputBorder(),
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
              ),
              child: const Text("Покинуть команду"),
            ),
          ],
        ),
      ),
    );
  }
}