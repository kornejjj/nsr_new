import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main_page.dart';

class TeamPage extends StatefulWidget {
  @override
  _TeamPageState createState() => _TeamPageState();
}

class _TeamPageState extends State<TeamPage> {
  String? teamId;
  Map<String, dynamic>? teamData;
  List<Map<String, dynamic>> members = [];

  @override
  void initState() {
    super.initState();
    _loadTeam();
  }

  /// 🔥 Загружаем данные команды
  Future<void> _loadTeam() async {
    String userId = FirebaseAuth.instance.currentUser!.uid;

    QuerySnapshot teams = await FirebaseFirestore.instance
        .collection('teams')
        .where('members', arrayContains: userId)
        .get();

    if (teams.docs.isNotEmpty) {
      var teamDoc = teams.docs.first;
      var teamInfo = teamDoc.data() as Map<String, dynamic>;

      setState(() {
        teamId = teamDoc.id;
        teamData = teamInfo;
      });

      _loadMembers(teamInfo['members']);
    } else {
      setState(() {
        teamId = null;
        teamData = null;
      });
    }
  }

  /// 🔥 Загружаем участников команды
  Future<void> _loadMembers(List<dynamic> memberIds) async {
    List<Map<String, dynamic>> loadedMembers = [];

    for (String userId in memberIds) {
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
        title: const Text(
          "Team",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.yellow[600],
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black),
            onPressed: () {}, // 🔧 Настройки команды
          ),
        ],
      ),
      body: teamData == null
          ? const Center(child: Text("Вы не состоите в команде", style: TextStyle(fontSize: 18)))
          : Column(
        children: [
          _buildTeamHeader(),
          const SizedBox(height: 20),
          Expanded(child: _buildMemberList()),
        ],
      ),
    );
  }

  /// 📌 **Хедер команды (аватарка, название, очки)**
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
              backgroundImage: AssetImage('assets/team_logo.png'), // ✅ Логотип команды
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

  /// 📌 **Список участников**
  Widget _buildMemberList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Mitglieder",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text("${members.length}/20", style: const TextStyle(color: Colors.grey)),
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
                      backgroundImage: AssetImage(member['avatar'] ?? 'assets/default_avatar.png'),
                    ),
                    title: Text(
                      member['name'] ?? "Без имени",
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text("${member['points'] ?? 0} Pkt"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.flash_on, color: Colors.deepPurple, size: 18),
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

  /// 📌 **Закреплённая нижняя панель**
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
        NavigationDestination(icon: Icon(Icons.home), label: 'Startseite'),
        NavigationDestination(icon: Icon(Icons.shopping_cart), label: 'Shop'),
        NavigationDestination(icon: Icon(Icons.group), label: 'Team'),
        NavigationDestination(icon: Icon(Icons.person), label: 'Profil'),
      ],
    );
  }
}
