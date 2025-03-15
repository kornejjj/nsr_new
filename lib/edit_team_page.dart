import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'team_selection_page.dart';
import 'bottom_nav_bar.dart';

class EditTeamPage extends StatefulWidget {
  final String teamId;
  const EditTeamPage({Key? key, required this.teamId}) : super(key: key);

  @override
  _EditTeamPageState createState() => _EditTeamPageState();
}

class _EditTeamPageState extends State<EditTeamPage> {
  final TextEditingController _teamNameController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();
  String? _avatarUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTeamData();
  }

  @override
  void dispose() {
    _teamNameController.dispose();
    super.dispose();
  }

  Future<void> _loadTeamData() async {
    try {
      DocumentSnapshot teamDoc = await _firestore.collection('teams').doc(widget.teamId).get();
      if (teamDoc.exists) {
        setState(() {
          _teamNameController.text = teamDoc['name'] ?? '';
          _avatarUrl = teamDoc['avatar'];
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ошибка загрузки данных команды: $e")),
      );
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _isLoading = true);
      try {
        String fileName = 'team_avatars/${widget.teamId}/${DateTime.now().millisecondsSinceEpoch}.jpg';
        Reference storageRef = _storage.ref().child(fileName);
        await storageRef.putFile(File(image.path));
        String downloadUrl = await storageRef.getDownloadURL();
        await _firestore.collection('teams').doc(widget.teamId).update({'avatar': downloadUrl});
        setState(() {
          _avatarUrl = downloadUrl;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Аватар успешно обновлён")),
        );
      } catch (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Ошибка загрузки аватара: $e")),
        );
      }
    }
  }

  Future<void> _updateTeamName() async {
    String newName = _teamNameController.text.trim();
    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Введите название команды")),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _firestore.collection('teams').doc(widget.teamId).update({'name': newName});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Название команды обновлено")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ошибка обновления названия: $e")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _leaveTeam() async {
    String userId = _auth.currentUser!.uid;
    setState(() => _isLoading = true);
    try {
      await _firestore.runTransaction((transaction) async {
        DocumentReference teamRef = _firestore.collection('teams').doc(widget.teamId);
        DocumentReference userRef = _firestore.collection('users').doc(userId);
        DocumentSnapshot teamSnap = await transaction.get(teamRef);
        if (!teamSnap.exists) return;
        List<dynamic> members = (teamSnap.data() as Map<String, dynamic>)['members'] ?? [];
        members.remove(userId);
        if (members.isEmpty) {
          transaction.delete(teamRef);
        } else {
          transaction.update(teamRef, {'members': members});
        }
        transaction.update(userRef, {'teamId': null});
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Вы покинули команду")),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const TeamSelectionPage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ошибка при выходе из команды: $e")),
      );
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)),
        title: const Text("Редактировать команду"),
        backgroundColor: Colors.yellow.shade600,
        elevation: 0,
        centerTitle: true,
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: 2, onDestinationSelected: (_) {}),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _avatarUrl != null && _avatarUrl!.startsWith("http")
                    ? NetworkImage(_avatarUrl!)
                    : const AssetImage('assets/team_logo.png') as ImageProvider,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Icon(Icons.camera_alt, size: 30, color: Colors.white),
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
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _updateTeamName,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text("Обновить название"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _leaveTeam,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text("Покинуть команду"),
            ),
          ],
        ),
      ),
    );
  }
}
