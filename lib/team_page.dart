import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main_page.dart';

class TeamPage extends StatefulWidget {
  final String teamId; // Принимаем teamId

  const TeamPage({super.key, required this.teamId}); // teamId обязателен

  @override
  _TeamPageState createState() => _TeamPageState();
}

class _TeamPageState extends State<TeamPage> {
  Map<String, dynamic>? teamData;
  List<Map<String, dynamic>> members = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTeam();
  }

  /// 🔥 Загружаем данные команды по teamId
  Future<void> _loadTeam() async {
    try {
      var teamDoc = await FirebaseFirestore.instance
          .collection('teams')
          .doc(widget.teamId)
          .get();

      if (teamDoc.exists) {
        setState(() {
          teamData = teamDoc.data() as Map<String, dynamic>;
        });

        await _loadMembers(teamData!['members']);
      } else {
        setState(() {
          teamData = null;
        });
      }
    } catch (error) {
      print('Ошибка при загрузке команды: $error');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 🔥 Загружаем участников команды
  Future<void> _loadMembers(List<dynamic> memberIds) async {
    List<Map<String, dynamic>> loadedMembers = [];

    for (String userId in memberIds.take(15)) {
      var userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (userDoc.exists) {
        loadedMembers.add(userDoc.data() as Map<String, dynamic>);
      }
    }

    setState(() {
      members = loadedMembers;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: _buildBottomNavBar(),
      appBar: AppBar(
        title: const Text("Команда", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.yellow[600],
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black),
            onPressed: () {}, // 🔧 Настройки команды
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // 🔄 Показываем индикатор загрузки
          : teamData == null
          ? const Center(child: Text("Команда не найдена", style: TextStyle(fontSize: 18)))
          : Column(
        children: [
          _buildTeamHeader(),
          const SizedBox(height: 20),
          Expanded(child: _buildMemberList()),
        ],
      ),
    );
  }

  /// 📌 Хедер команды (аватарка, название, очки)
  Widget _buildTeamHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD54F), Color(0xFFFFE082)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white,
            child: CircleAvatar(
              radius: 46,
              backgroundImage: NetworkImage(teamData!['avatar'] ?? 'assets/team_logo.png'), // 🔥 Логотип команды (из БД)
            ),
          ),
          const SizedBox(height: 10),
          Text(
            teamData!['name'] ?? "Без названия",
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          Text(
            "Место: ${teamData!['rank'] ?? 'N/A'}",
            style: const TextStyle(fontSize: 18, color: Colors.black54),
          ),
          const SizedBox(height: 5),
          Text(
            "${teamData!['points'] ?? 0} Pkt",
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepPurple),
          ),
        ],
      ),
    );
  }

  /// 📌 Список участников
  Widget _buildMemberList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Участники",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text("${members.length}/15", style: const TextStyle(color: Colors.grey)), // 🔥 15 участников максимум
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: members.length,
              itemBuilder: (context, index) {
                var member = members[index];
                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 3,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(member['avatar'] ?? 'assets/default_avatar.png'),
                    ),
                    title: Text(
                      "${member['firstName']} ${member['lastName']}",
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text("${member['points'] ?? 0} Pkt"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.rocket_launch, color: Colors.deepPurple, size: 18),
                        Text("x${member['boost'] ?? 1}", style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 📌 Закреплённая нижняя панель
  Widget _buildBottomNavBar() {
    return NavigationBar(
      selectedIndex: 2, // ✅ Выбрана вкладка Team
      onDestinationSelected: (index) {
        if (index == 0) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MainPage()),
          );
        }
      },
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home), label: 'Главная'),
        NavigationDestination(icon: Icon(Icons.shopping_cart), label: 'Магазин'),
        NavigationDestination(icon: Icon(Icons.group), label: 'Команда'),
        NavigationDestination(icon: Icon(Icons.person), label: 'Профиль'),
      ],
    );
  }
}