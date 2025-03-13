import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'profile_page.dart';
import 'team_page.dart';
import 'team_selection_page.dart';
import 'all_teams_page.dart';
import 'bottom_nav_bar.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;
  String? _userName;
  Map<String, dynamic>? _teamData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkTeamAndLoadData();
  }

  Future<void> _checkTeamAndLoadData() async {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    debugPrint('Starting _checkTeamAndLoadData for user: $userId');

    try {
      debugPrint('Querying teams for user: $userId');
      QuerySnapshot teams = await FirebaseFirestore.instance
          .collection('teams')
          .where('members', arrayContains: userId)
          .get();

      debugPrint('Query completed. Docs found: ${teams.docs.length}');
      if (teams.docs.isEmpty) {
        debugPrint('User $userId is not in a team. Redirecting to TeamSelectionPage.');
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const TeamSelectionPage()),
          );
        }
        return;
      }

      debugPrint('Fetching user name for: $userId');
      _userName = await _fetchUserName();
      debugPrint('Fetching team data for: $userId');
      _teamData = await _fetchUserTeamWithRank();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error in _checkTeamAndLoadData: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Ошибка загрузки данных: $e")),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const TeamSelectionPage()),
        );
      }
    }
  }

  Future<String> _fetchUserName() async {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    debugPrint('Fetching user name for: $userId');
    DocumentSnapshot userDoc =
    await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return userDoc.exists ? userDoc['firstName'] ?? "User" : "User";
  }

  Future<Map<String, dynamic>> _fetchUserTeamWithRank() async {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    debugPrint('Fetching team with rank for user: $userId');
    try {
      QuerySnapshot teams = await FirebaseFirestore.instance
          .collection('teams')
          .where('members', arrayContains: userId)
          .get();

      if (teams.docs.isNotEmpty) {
        var userTeamDoc = teams.docs.first;
        var userTeam = {'id': userTeamDoc.id, ...userTeamDoc.data() as Map<String, dynamic>};
        int teamPoints = 0;

        List<dynamic> memberIds = userTeam['members'] as List<dynamic>? ?? [];
        List<Future<int>> pointFutures = [];
        for (String memberId in memberIds.take(20)) {
          pointFutures.add(
            FirebaseFirestore.instance.collection('users').doc(memberId).get().then((doc) {
              if (doc.exists) {
                int points = doc['points'] as int? ?? 0;
                debugPrint('User $memberId points: $points');
                return points;
              }
              return 0;
            }),
          );
        }

        if (pointFutures.isNotEmpty) {
          var points = await Future.wait(pointFutures);
          teamPoints = points.reduce((a, b) => a + b);
        }

        QuerySnapshot allTeams = await FirebaseFirestore.instance.collection('teams').get();
        var sortedTeams = [];
        for (var teamDoc in allTeams.docs) {
          var teamData = {'id': teamDoc.id, ...teamDoc.data() as Map<String, dynamic>};
          int teamTotalPoints = 0;
          List<dynamic> teamMemberIds = teamData['members'] as List<dynamic>? ?? [];
          List<Future<int>> teamPointFutures = [];
          for (String memberId in teamMemberIds.take(20)) {
            teamPointFutures.add(
              FirebaseFirestore.instance.collection('users').doc(memberId).get().then((doc) {
                return doc.exists ? (doc['points'] as int? ?? 0) : 0;
              }),
            );
          }
          if (teamPointFutures.isNotEmpty) {
            var teamPointsList = await Future.wait(teamPointFutures);
            teamTotalPoints = teamPointsList.reduce((a, b) => a + b);
          }
          teamData['points'] = teamTotalPoints;
          sortedTeams.add(teamData);
        }

        sortedTeams.sort((a, b) => (b['points'] as int).compareTo(a['points'] as int));
        int rank = sortedTeams.indexWhere((team) => team['id'] == userTeam['id']) + 1;

        debugPrint('Team ${userTeam['name']} points: $teamPoints, rank: $rank');
        return {
          'name': userTeam['name'] ?? 'Без названия',
          'points': teamPoints,
          'avatar': userTeam['avatar'],
          'rank': rank,
        };
      }
    } catch (e) {
      debugPrint('Error fetching team with rank: $e');
    }
    return {'name': null, 'points': 0, 'avatar': null, 'rank': 'N/A'};
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.teal)),
      );
    }

    if (_teamData == null || _teamData!['name'] == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.teal)),
      );
    }

    return Scaffold(
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
          if (index == 2) {
            _navigateToTeamPage();
          } else if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfilePage()),
            );
          }
        },
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFCA28), Color(0xFFFFE57F), Color(0xFFFFF8E1)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const _Header(),
              const SizedBox(height: 15),
              Text(
                "Let's Go $_userName!",
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: MediaQuery.of(context).size.width * 0.07,
                  shadows: const [Shadow(blurRadius: 4.0, color: Colors.white70, offset: Offset(2.0, 2.0))],
                ),
              ),
              const SizedBox(height: 15),
              _TeamCard(
                teamName: _teamData!['name'],
                teamPoints: _teamData!['points'].toString(),
                teamAvatar: _teamData!['avatar'],
                teamRank: _teamData!['rank'].toString(),
              ),
              const SizedBox(height: 15),
              Expanded(child: _ActionButtons()),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _navigateToTeamPage() async {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    QuerySnapshot teams = await FirebaseFirestore.instance
        .collection('teams')
        .where('members', arrayContains: userId)
        .get();
    if (teams.docs.isNotEmpty) {
      String teamId = teams.docs.first.id;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => TeamPage(teamId: teamId)),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const TeamSelectionPage()),
      );
    }
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                3,
                    (index) => const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(Icons.rocket_launch, color: Colors.deepPurple, size: 34),
                ),
              ),
            ),
          ),
          Center(
            child: Image.asset(
              'assets/logo.png',
              height: 80,
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications, color: Colors.black54, size: 26),
                  onPressed: () {},
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamCard extends StatelessWidget {
  final String teamName;
  final String teamPoints;
  final String? teamAvatar;
  final String teamRank;

  const _TeamCard({
    required this.teamName,
    required this.teamPoints,
    required this.teamAvatar,
    required this.teamRank,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AllTeamsPage()),
        ),
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.teal, Colors.cyanAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.3), blurRadius: 10, spreadRadius: 5)],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundImage: teamAvatar != null && teamAvatar!.startsWith("http")
                          ? NetworkImage(teamAvatar!) as ImageProvider
                          : const AssetImage('assets/team_logo.png'),
                      backgroundColor: Colors.transparent,
                      onBackgroundImageError: (exception, stackTrace) {
                        debugPrint('Failed to load team avatar: $exception');
                      },
                    ),
                    const SizedBox(width: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          teamName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "Место: $teamRank",
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "$teamPoints баллов",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Icon(Icons.arrow_forward, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(25),
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 1.3,
        children: const [
          _CustomSquareButton(
            icon: Icons.flag,
            text: 'Миссии',
            color: Colors.deepPurple,
          ),
          _CustomSquareButton(
            icon: Icons.directions_run,
            text: 'Шаги',
            color: Colors.green,
          ),
          _CustomSquareButton(
            icon: Icons.leaderboard,
            text: 'Активность',
            color: Colors.blue,
          ),
          _CustomSquareButton(
            icon: Icons.wb_sunny,
            text: 'Погода',
            color: Colors.orange,
            isRadial: true,
          ),
        ],
      ),
    );
  }
}

class _CustomSquareButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final bool isRadial;

  const _CustomSquareButton({
    required this.icon,
    required this.text,
    required this.color,
    this.isRadial = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(15),
      elevation: 5,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(15),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            gradient: isRadial
                ? RadialGradient(
              colors: [color.withOpacity(0.8), color],
              radius: 0.8,
            )
                : LinearGradient(
              colors: [color.withOpacity(0.8), color],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 10, spreadRadius: 2)],
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 36),
                const SizedBox(height: 7),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}