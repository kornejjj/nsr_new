import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_page.dart';
import 'team_page.dart';
import 'team_selection_page.dart';
import 'all_teams_page.dart';
import 'bottom_nav_bar.dart';

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  Future<String> _fetchUserName() async {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    DocumentSnapshot userDoc =
    await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return userDoc.exists ? userDoc['firstName'] ?? "User" : "User";
  }

  Future<Map<String, dynamic>?> _fetchUserTeam() async {
    String userId = FirebaseAuth.instance.currentUser!.uid;

    try {
      QuerySnapshot teams = await FirebaseFirestore.instance
          .collection('teams')
          .where('members', arrayContains: userId)
          .get();

      if (teams.docs.isNotEmpty) {
        return teams.docs.first.data() as Map<String, dynamic>;
      }
    } catch (e) {
      print('Ошибка при загрузке команды: $e');
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });

          if (index == 2) {
            _navigateToTeamPage();
          } else if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ProfilePage()),
            );
          }
        },
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFFFD54F),
              Color(0xFFFFE082),
              Color(0xFFFFF9C4),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          image: DecorationImage(
            image: AssetImage("assets/space_background.png"), // Фоновое изображение
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 15),
              FutureBuilder<String>(
                future: _fetchUserName(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Text(
                      "Let's Go!",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 28, // Увеличенный размер шрифта
                      ),
                    );
                  }
                  return Text(
                    "Let's Go ${snapshot.data}!",
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 28, // Увеличенный размер шрифта
                    ),
                  );
                },
              ),
              const SizedBox(height: 15),
              FutureBuilder<Map<String, dynamic>?>(
                future: _fetchUserTeam(),
                builder: (context, snapshot) {
                  final teamName = snapshot.data?['name'] ?? 'Выберите команду';
                  final teamPoints = snapshot.data?['points']?.toString() ?? '0';
                  final teamAvatar = snapshot.data?['avatar'] ?? 'assets/flag.png';

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
                          gradient: LinearGradient(
                            colors: [Colors.orange.shade200, Colors.yellow.shade100],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.3),
                              blurRadius: 10,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 35,
                                backgroundImage: teamAvatar.startsWith("http")
                                    ? NetworkImage(teamAvatar)
                                    : AssetImage(teamAvatar) as ImageProvider,
                                backgroundColor: Colors.transparent,
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      teamName,
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      "$teamPoints Punkte",
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 15),
              Expanded(child: _buildActionButtons()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
                  child: Icon(Icons.rocket_launch, color: Colors.orange, size: 30), // Яркие иконки
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
                      color: Colors.red,
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

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(25),
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 1.2,
        children: const [
          _CustomSquareButton(icon: Icons.flag, text: 'Missionen', color: Colors.orange),
          _CustomSquareButton(icon: Icons.directions_run, text: 'Schritte', color: Colors.green),
          _CustomSquareButton(icon: Icons.leaderboard, text: 'Aktivität', color: Colors.blue),
          _CustomSquareButton(icon: Icons.wb_sunny, text: 'Wetter', color: Colors.purple),
        ],
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
        MaterialPageRoute(
          builder: (context) => TeamPage(teamId: teamId),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => TeamSelectionPage()),
      );
    }
  }
}

class _CustomSquareButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _CustomSquareButton({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(15),
      elevation: 5,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.8), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 36),
              const SizedBox(height: 7),
              Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}