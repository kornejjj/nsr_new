import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'main_page.dart';

class TeamSelectionPage extends StatefulWidget {
  @override
  _TeamSelectionPageState createState() => _TeamSelectionPageState();
}

class _TeamSelectionPageState extends State<TeamSelectionPage> {
  final TextEditingController _teamNameController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;

  /// ✅ Создать новую команду
  Future<void> _createTeam() async {
    String teamName = _teamNameController.text.trim();
    if (teamName.isEmpty) {
      _showSnackBar("Введите название команды");
      return;
    }

    setState(() => _isLoading = true);
    String userId = _auth.currentUser!.uid;

    try {
      // 🔹 Проверяем, есть ли уже такая команда
      QuerySnapshot existingTeams = await _firestore
          .collection('teams')
          .where('name', isEqualTo: teamName)
          .get();

      if (existingTeams.docs.isNotEmpty) {
        _showSnackBar("Эта команда уже существует!");
        setState(() => _isLoading = false);
        return;
      }

      // 🔹 Создаём новую команду с текущим пользователем
      await _firestore.collection('teams').add({
        'name': teamName,
        'members': [userId],
      });

      _showSnackBar("Команда успешно создана!");
      _navigateToMain();

    } catch (error) {
      print("Ошибка Firestore: $error");
      _showSnackBar("Ошибка создания команды: $error");

    } finally {
      setState(() => _isLoading = false); // ✅ Останавливаем индикатор загрузки
    }
  }

  /// ✅ Присоединиться к существующей команде
  Future<void> _joinTeam(String teamId, List members) async {
    String userId = _auth.currentUser!.uid;

    if (members.contains(userId)) {
      _showSnackBar("Вы уже в этой команде!");
      return;
    }

    if (members.length >= 15) {
      _showSnackBar("Эта команда уже заполнена (15/15)!");
      return;
    }

    try {
      members.add(userId);
      await _firestore.collection('teams').doc(teamId).update({'members': members});

      _showSnackBar("Вы успешно присоединились!");
      _navigateToMain();

    } catch (error) {
      print("Ошибка Firestore: $error");
      _showSnackBar("Ошибка присоединения: $error");
    }
  }

  /// 🔄 Переход на `MainPage`
  void _navigateToMain() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => MainPage()),
    );
  }

  /// 🔔 Отображение уведомлений
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Выбор команды")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              "Создайте свою команду или присоединитесь к существующей",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),

            /// 🔹 Поле ввода для создания команды
            TextField(
              controller: _teamNameController,
              decoration: InputDecoration(
                labelText: "Название команды",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isLoading ? null : _createTeam,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text("Создать команду"),
            ),

            const SizedBox(height: 30),
            const Text("Или присоединитесь к команде:", style: TextStyle(fontSize: 18)),
            const SizedBox(height: 10),

            /// 🔹 Список доступных команд
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('teams').snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text("Ошибка загрузки: ${snapshot.error}"));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("Нет доступных команд"));
                  }

                  var teams = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: teams.length,
                    itemBuilder: (context, index) {
                      var team = teams[index];
                      var teamName = team['name'];
                      var members = List<String>.from(team['members']);

                      return Card(
                        child: ListTile(
                          title: Text(teamName),
                          subtitle: Text("Участников: ${members.length}/15"),
                          trailing: ElevatedButton(
                            onPressed: () => _joinTeam(team.id, members),
                            child: const Text("Присоединиться"),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
