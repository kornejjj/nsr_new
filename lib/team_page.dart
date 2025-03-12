import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint;
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
  int totalTeamPoints = 0; // Для хранения суммы баллов
  int teamRank = 0; // Для хранения текущего места команды

  @override
  void initState() {
    super.initState();
    _loadTeam();
  }

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
        await _calculateTeamRank(); // Рассчитываем место команды

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
            _calculateTeamRank(); // Пересчитываем место команды при обновлении
          }
        });
      } else {
        setState(() {
          teamData = null;
        });
      }
    } catch (error) {
      debugPrint('Ошибка при загрузке команды: $error');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMembers(List<dynamic> memberIds) async {
    List<Map<String, dynamic>> loadedMembers = [];

    for (String userId in memberIds.take(15)) {
      var userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (userDoc.exists) {
        loadedMembers.add(userDoc.data() as Map<String, dynamic>);
      }
    }

    // Сортировка участников по баллам (от большего к меньшему)
    loadedMembers.sort((a, b) {
      int pointsA = a['points'] as int? ?? 0; // Исправляем ошибку с toInt()
      int pointsB = b['points'] as int? ?? 0;
      return pointsB.compareTo(pointsA); // Сортировка по убыванию
    });

    // Рассчитываем сумму баллов участников
    int pointsSum = loadedMembers.fold(0, (sum, member) => sum + (member['points'] as int? ?? 0));

    setState(() {
      members = loadedMembers;
      totalTeamPoints = pointsSum; // Обновляем сумму баллов
    });
  }

  Future<void> _calculateTeamRank() async {
    try {
      // Получаем все команды
      var teamsSnapshot = await FirebaseFirestore.instance.collection('teams').get();
      List<Map<String, dynamic>> teams = [];

      // Для каждой команды рассчитываем сумму баллов участников
      for (var teamDoc in teamsSnapshot.docs) {
        var team = teamDoc.data();
        List<dynamic> memberIds = team['members'] as List<dynamic>? ?? [];

        int teamPoints = 0;
        for (String userId in memberIds) {
          var userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
          if (userDoc.exists) {
            teamPoints += userDoc['points'] as int? ?? 0;
          }
        }

        teams.add({
          'id': teamDoc.id,
          'points': teamPoints,
        });
      }

      // Сортируем команды по сумме баллов (от большего к меньшему)
      teams.sort((a, b) => (b['points'] as int).compareTo(a['points'] as int));

      // Находим место текущей команды
      int rank = teams.indexWhere((team) => team['id'] == widget.teamId) + 1;

      setState(() {
        teamRank = rank; // Обновляем место команды
      });
    } catch (error) {
      debugPrint('Ошибка при расчёте места команды: $error');
      setState(() {
        teamRank = 0; // Если ошибка, показываем "N/A"
      });
    }
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
              MaterialPageRoute(builder: (context) => const MainPage()),
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
              right: 16,
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
        automaticallyImplyLeading: false,
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
            "Место: ${teamRank == 0 ? 'N/A' : teamRank}", // Отображаем место команды
            style: const TextStyle(fontSize: 22, color: Colors.black),
          ),
          const SizedBox(height: 5),
          Text(
            "$totalTeamPoints баллов", // Сумма баллов участников
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
          ),
          const SizedBox(height: 20),
          Expanded(child: _buildMemberList()),
        ],
      ),
    );
  }

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
                String memberName = "${member['firstName'] ?? ''} ${member['lastName'] ?? ''}".trim();
                String memberPoints = (member['points'] ?? 0).toString();
                String? memberAvatar = member['avatar'];
                bool isDefaultAvatar = memberAvatar == null || !memberAvatar.startsWith("http");

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 3,
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      child: Image(
                        image: isDefaultAvatar
                            ? const AssetImage("assets/default_avatar.png") as ImageProvider
                            : NetworkImage(memberAvatar),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          debugPrint("Error loading avatar for $memberName: $error");
                          return Image.asset(
                            "assets/default_avatar.png",
                            fit: BoxFit.cover,
                          );
                        },
                      ),
                    ),
                    title: Text(
                      memberName,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text("$memberPoints баллов"),
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