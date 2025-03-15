import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'main_page.dart';
import 'bottom_nav_bar.dart';

class TeamSelectionPage extends StatefulWidget {
  const TeamSelectionPage({Key? key}) : super(key: key);

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
    _checkIfInTeam();
  }

  @override
  void dispose() {
    _teamNameController.dispose();
    super.dispose();
  }

  Future<void> _checkIfInTeam() async {
    String userId = _auth.currentUser!.uid;
    DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
    if (userDoc.exists && userDoc['teamId'] != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainPage()),
      );
    }
  }

  Future<void> _createTeam() async {
    String teamName = _teamNameController.text.trim();
    if (teamName.isEmpty) {
      _showSnackBar("Введите название команды");
      return;
    }
    setState(() => _isLoading = true);
    String userId = _auth.currentUser!.uid;
    try {
      // Проверяем, что команды с таким названием нет
      QuerySnapshot existingTeams = await _firestore.collection('teams')
          .where('name', isEqualTo: teamName).get();
      if (existingTeams.docs.isNotEmpty) {
        _showSnackBar("Эта команда уже существует!");
        setState(() => _isLoading = false);
        return;
      }
      // Создаем команду и обновляем пользователя в одной транзакции
      await _firestore.runTransaction((transaction) async {
        DocumentReference teamRef = _firestore.collection('teams').doc();
        transaction.set(teamRef, {
          'name': teamName,
          'members': [userId],
          'avatar': 'assets/team_logo.png'
        });
        transaction.update(_firestore.collection('users').doc(userId), {'teamId': teamRef.id});
      });
      _showSnackBar("Команда успешно создана!");
      _navigateToMain();
    } catch (error) {
      _showSnackBar("Ошибка: $error");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _joinTeam(String teamId, List<String> members) async {
    String userId = _auth.currentUser!.uid;
    if (members.contains(userId)) {
      _showSnackBar("Вы уже в этой команде!");
      return;
    }
    if (members.length >= 20) {
      _showSnackBar("Эта команда уже заполнена (20/20)!");
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _firestore.runTransaction((transaction) async {
        DocumentReference teamRef = _firestore.collection('teams').doc(teamId);
        DocumentSnapshot teamSnap = await transaction.get(teamRef);
        if (!teamSnap.exists) throw Exception("Команда не найдена");
        List<dynamic> currentMembers = List<dynamic>.from((teamSnap.data() as Map<String, dynamic>)['members'] ?? []);
        if (currentMembers.contains(userId)) throw Exception("Вы уже в этой команде!");
        if (currentMembers.length >= 20) throw Exception("Эта команда уже заполнена (20/20)!");
        currentMembers.add(userId);
        transaction.update(teamRef, {'members': currentMembers});
        transaction.update(_firestore.collection('users').doc(userId), {'teamId': teamId});
      });
      _showSnackBar("Вы успешно присоединились!");
      _navigateToMain();
    } catch (error) {
      String errorMsg;
      if (error is FirebaseException) {
        errorMsg = "Ошибка: ${error.message}";
      } else if (error is Exception) {
        errorMsg = error.toString().replaceFirst('Exception: ', '');
      } else {
        errorMsg = "Ошибка: $error";
      }
      _showSnackBar(errorMsg);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToMain() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainPage()),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Center(child: Text("Выбор команды")),
        backgroundColor: Colors.yellow.shade600,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              "Создайте свою команду или присоединитесь к существующей",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
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
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isLoading ? null : _createTeam,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text("Создать команду"),
            ),
            const SizedBox(height: 30),
            const Text("Или присоединитесь к команде:", style: TextStyle(fontSize: 18)),
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
                      List<String> members = List<String>.from(team['members'] ?? []);
                      String teamAvatar = team['avatar'] ?? 'assets/team_logo.png';
                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 3,
                        child: ListTile(
                          leading: CircleAvatar(
                            radius: 25,
                            backgroundImage: teamAvatar.startsWith("http")
                                ? NetworkImage(teamAvatar)
                                : AssetImage(teamAvatar) as ImageProvider,
                          ),
                          title: Text(team['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("Участников: ${members.length}/20"),
                          trailing: ElevatedButton(
                            onPressed: _isLoading ? null : () => _joinTeam(team.id, members),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
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
      bottomNavigationBar: BottomNavBar(currentIndex: 2, onDestinationSelected: (_) {}),
    );
  }
}
