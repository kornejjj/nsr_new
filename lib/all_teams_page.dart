import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'team_page.dart';
import 'bottom_nav_bar.dart';

class AllTeamsPage extends StatefulWidget {
  const AllTeamsPage({super.key});

  @override
  State<AllTeamsPage> createState() => _AllTeamsPageState();
}

class _AllTeamsPageState extends State<AllTeamsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Все команды',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.yellow[600],
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: 2, onDestinationSelected: (_) {}),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFD54F), Color(0xFFFFE082), Color(0xFFFFF9C4)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('teams').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            return FutureBuilder<List<Map<String, dynamic>>>(
              future: _calculateTeamPoints(snapshot.data!.docs),
              builder: (context, teamSnapshot) {
                if (!teamSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var sortedTeams = teamSnapshot.data!;
                sortedTeams.sort((a, b) => (b['points'] as int).compareTo(a['points'] as int));

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: sortedTeams.length,
                  itemBuilder: (context, index) {
                    var team = sortedTeams[index];
                    int rank = index + 1; // Место определяется после сортировки
                    return _TeamCard(
                      teamId: team['id'],
                      rank: rank,
                      avatar: team['avatar'] ?? 'assets/team_logo.png',
                      name: team['name'] ?? 'Без названия',
                      points: team['points'].toString(),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _calculateTeamPoints(List<QueryDocumentSnapshot> teamDocs) async {
    List<Map<String, dynamic>> teams = [];
    for (var teamDoc in teamDocs) {
      var teamData = {'id': teamDoc.id, ...teamDoc.data() as Map<String, dynamic>};
      int teamPoints = 0;

      List<dynamic> memberIds = teamData['members'] as List<dynamic>? ?? [];
      List<Future<int>> pointFutures = [];
      for (String userId in memberIds.take(15)) {
        pointFutures.add(
          FirebaseFirestore.instance.collection('users').doc(userId).get().then((doc) {
            if (doc.exists) {
              int points = doc['points'] as int? ?? 0;
              debugPrint('User $userId points: $points');
              return points;
            }
            return 0;
          }),
        );
      }

      // Ожидаем завершения всех запросов
      if (pointFutures.isNotEmpty) {
        var points = await Future.wait(pointFutures);
        teamPoints = points.reduce((a, b) => a + b);
      }

      debugPrint('Team ${teamData['name']} points: $teamPoints');
      teamData['points'] = teamPoints;
      teams.add(teamData);
    }
    return teams;
  }
}

class _TeamCard extends StatelessWidget {
  final String teamId;
  final int rank;
  final String avatar;
  final String name;
  final String points;

  const _TeamCard({
    required this.teamId,
    required this.rank,
    required this.avatar,
    required this.name,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => TeamPage(teamId: teamId)),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Text(
                rank.toString(),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black54),
              ),
              const SizedBox(width: 15),
              CircleAvatar(
                radius: 30,
                backgroundImage: avatar.startsWith("http") ? NetworkImage(avatar) : AssetImage(avatar) as ImageProvider,
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '$points баллов',
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward, color: Colors.black54),
            ],
          ),
        ),
      ),
    );
  }
}