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

  @override
  void initState() {
    super.initState();
    _checkIfInTeam(); // 🔥 Проверяем команду перед загрузкой страницы
  }

  /// ✅ Проверяем, есть ли у пользователя команда
  Future<void> _checkIfInTeam() async {
    String userId = _auth.currentUser!.uid;
    DocumentSnapshot userDoc =
    await _firestore.collection('users').doc(userId).get();

    if (userDoc.exists && userDoc['teamId'] != null) {
      // 🔥 Если `teamId` уже есть, отправляем на главную страницу
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainPage()),
      );
    }
  }

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
      QuerySnapshot existingTeams = await _firestore
          .collection('teams')
          .where('name', isEqualTo: teamName)
          .get();

      if (existingTeams.docs.isNotEmpty) {
        _showSnackBar("Эта команда уже существует!");
        setState(() => _isLoading = false);
        return;
      }

      // 🔥 Создаём команду
      DocumentReference teamRef = await _firestore.collection('teams').add({
        'name': teamName,
        'members': [userId],
      });

      // 🔥 **Обновляем `teamId` у пользователя**
      await _firestore.collection('users').doc(userId).update({'teamId': teamRef.id});

      _showSnackBar("Команда успешно создана!");
      _navigateToMain();
    } catch (error) {
      _showSnackBar("Ошибка: $error");
    } finally {
      setState(() => _isLoading = false);
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
      // Добавляем пользователя в массив `members`
      members.add(userId);

      // 🔥 Обновляем команду (добавляем пользователя)
      await _firestore.collection('teams').doc(teamId).update({'members': members});

      // 🔥 **Обновляем `teamId` у пользователя**
      await _firestore.collection('users').doc(userId).update({'teamId': teamId});

      _showSnackBar("Вы успешно присоединились!");
      _navigateToMain();
    } catch (error) {
      _showSnackBar("Ошибка: $error");
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
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
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
            const Text("Или присоединитесь к команде:",
                style: TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('teams').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  var teams = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: teams.length,
                    itemBuilder: (context, index) {
                      var team = teams[index];
                      return ListTile(
                        title: Text(team['name']),
                        trailing: ElevatedButton(
                          onPressed: () => _joinTeam(team.id,
                              List<String>.from(team['members'])),
                          child: const Text("Присоединиться"),
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
