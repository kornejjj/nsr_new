import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_page.dart';
import 'team_page.dart';
import 'team_selection_page.dart';
import 'all_teams_page.dart';
import 'bottom_nav_bar.dart';
import 'dart:math' show sin;

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key); // Добавлен const конструктор

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<String> _fetchUserName() async {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    DocumentSnapshot userDoc =
    await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return userDoc.exists ? userDoc['firstName'] ?? "User" : "User";
  }

  Future<Map<String, dynamic>> _fetchUserTeamWithRank() async {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    try {
      QuerySnapshot teams = await FirebaseFirestore.instance
          .collection('teams')
          .where('members', arrayContains: userId)
          .get();

      if (teams.docs.isNotEmpty) {
        var userTeam = teams.docs.first.data() as Map<String, dynamic>;
        int teamPoints = userTeam['points']?.toInt() ?? 0;

        QuerySnapshot allTeams = await FirebaseFirestore.instance
            .collection('teams')
            .get();
        var sortedTeams = allTeams.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
        sortedTeams.sort((a, b) => (b['points'] ?? 0).compareTo(a['points'] ?? 0));

        int rank = sortedTeams.indexWhere((team) => team['name'] == userTeam['name']) + 1;
        userTeam['rank'] = rank;
        return userTeam;
      }
    } catch (e) {
      print('Ошибка при загрузке команды: $e');
    }
    return {'name': 'Выберите команду', 'points': '0', 'avatar': 'assets/flag.png', 'rank': 'N/A'};
  }

  @override
  Widget build(BuildContext context) {
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
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFCA28), Color(0xFFFFE57F), Color(0xFFFFF8E1)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          image: DecorationImage(
            image: const AssetImage("assets/space_background.png"),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.2), BlendMode.dstATop),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _Header(animationController: _animationController),
              const SizedBox(height: 15),
              FutureBuilder<String>(
                future: _fetchUserName(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator(color: Colors.teal);
                  }
                  return Text(
                    "Let's Go ${snapshot.data}!",
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: MediaQuery.of(context).size.width * 0.07,
                      shadows: const [Shadow(blurRadius: 4.0, color: Colors.white70, offset: Offset(2.0, 2.0))],
                    ),
                  );
                },
              ),
              const SizedBox(height: 15),
              FutureBuilder<Map<String, dynamic>>(
                future: _fetchUserTeamWithRank(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator(color: Colors.teal);
                  }
                  final teamName = snapshot.data?['name'] ?? 'Выберите команду';
                  final teamPoints = snapshot.data?['points']?.toString() ?? '0';
                  final teamAvatar = snapshot.data?['avatar'] ?? 'assets/flag.png';
                  final teamRank = snapshot.data?['rank']?.toString() ?? 'N/A';

                  return _TeamCard(
                    teamName: teamName,
                    teamPoints: teamPoints,
                    teamAvatar: teamAvatar,
                    teamRank: teamRank,
                  );
                },
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
        MaterialPageRoute(builder: (context) => TeamPage(teamId: teamId)), // Убрано const
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
  final AnimationController animationController;

  const _Header({required this.animationController});

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
            child: AnimatedBuilder(
              animation: animationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + (sin(animationController.value * 2 * 3.14) * 0.05),
                  child: Image.asset('assets/logo.png', height: 80, fit: BoxFit.contain),
                );
              },
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
  final String teamAvatar;
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
                      backgroundImage: teamAvatar.startsWith("http")
                          ? NetworkImage(teamAvatar)
                          : AssetImage(teamAvatar) as ImageProvider,
                      backgroundColor: Colors.transparent,
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
                          "$teamPoints Punkte",
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
            text: 'Missionen',
            color: Colors.deepPurple,
          ),
          _CustomSquareButton(
            icon: Icons.directions_run,
            text: 'Schritte',
            color: Colors.green,
          ),
          _CustomSquareButton(
            icon: Icons.leaderboard,
            text: 'Aktivität',
            color: Colors.blue,
          ),
          _CustomSquareButton(
            icon: Icons.wb_sunny,
            text: 'Wetter',
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