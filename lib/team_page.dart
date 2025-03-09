import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main_page.dart';
import 'bottom_nav_bar.dart';
import 'edit_team_page.dart';

class TeamPage extends StatefulWidget {
  final String teamId;

  const TeamPage({super.key, required this.teamId});

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

        // Прослушивание изменений в реальном времени
        FirebaseFirestore.instance
            .collection('teams')
            .doc(widget.teamId)
            .snapshots()
            .listen((snapshot) {
          if (snapshot.exists) {
            setState(() {
              teamData = snapshot.data() as Map<String, dynamic>;
            });
            _loadMembers(teamData!['members']);
          }
        });
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
      backgroundColor: Colors.grey[50],
      bottomNavigationBar: BottomNavBar(
        currentIndex: 2,
        onDestinationSelected: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => MainPage()),
            );
          }
        },
      ),
      appBar: AppBar(
        title: Stack(
          alignment: Alignment.center,
          children: [
            const Center(
              child: Text(
                "Моя команда",
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold, color: Colors.black),
              ),
            ),
            Positioned(
              right: 16, // Отступ справа
              child: IconButton(
                icon: const Icon(Icons.settings, color: Colors.black, size: 26),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditTeamPage(teamId: widget.teamId),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        backgroundColor: Colors.yellow.shade600,
        elevation: 0,
        automaticallyImplyLeading: false, // Убираем стрелку назад
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : teamData == null
          ? const Center(child: Text("Команда не найдена", style: TextStyle(fontSize: 18)))
          : Column(
        children: [
          const SizedBox(height: 20),
          CircleAvatar(
            radius: 60,
            backgroundColor: Colors.white,
            child: CircleAvatar(
              radius: 56,
              backgroundImage: NetworkImage(teamData!['avatar'] ?? 'assets/team_logo.png'),
            ),
          ),
          const SizedBox(height: 15),
          Text(
            teamData!['name'] ?? "Без названия",
            style: const TextStyle(fontSize: 37, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            "Место: ${teamData!['rank'] ?? 'N/A'}",
            style: const TextStyle(fontSize: 22, color: Colors.black),
          ),
          const SizedBox(height: 5),
          Text(
            "${teamData!['points'] ?? 0} баллов",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
          ),
          const SizedBox(height: 20),
          Expanded(child: _buildMemberList()),
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
          Text("${members.length}/15", style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: members.length,
              itemBuilder: (context, index) {
                var member = members[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 5),
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
                    subtitle: Text("${member['points'] ?? 0} баллов"),
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
}