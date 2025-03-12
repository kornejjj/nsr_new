import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main_page.dart';
import 'edit_profile_page.dart';
import 'bottom_nav_bar.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _currentIndex = 3;
  String userName = "Загрузка...";
  String teamName = "Без команды";
  String avatarUrl = "assets/default_avatar.png"; // Установка по умолчанию
  int userPoints = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      DocumentSnapshot userDoc =
      await FirebaseFirestore.instance.collection('users').doc(userId).get();

      if (userDoc.exists) {
        setState(() {
          userName = "${userDoc['firstName'] ?? ''} ${userDoc['lastName'] ?? ''}".trim();
          // Проверяем поле avatar: если оно пустое, null или не URL, используем стандартный аватар
          String? avatar = userDoc['avatar'];
          avatarUrl = (avatar != null && avatar.isNotEmpty && avatar.startsWith("http"))
              ? avatar
              : "assets/default_avatar.png";
          userPoints = (userDoc['points'] ?? 0).toInt();
          print("Avatar URL: $avatarUrl"); // Отладка: проверяем, что загружается
        });

        if (userDoc['teamId'] != null) {
          DocumentSnapshot teamDoc =
          await FirebaseFirestore.instance.collection('teams').doc(userDoc['teamId']).get();
          if (teamDoc.exists) {
            setState(() {
              teamName = teamDoc['name'] ?? "Без команды";
            });
          }
        }
      } else {
        setState(() {
          avatarUrl = "assets/default_avatar.png"; // Если пользователя нет, используем стандартный аватар
          print("User does not exist, using default avatar: $avatarUrl");
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ошибка загрузки данных: $e")),
      );
      setState(() {
        avatarUrl = "assets/default_avatar.png"; // При ошибке используем стандартный аватар
        print("Error loading data, using default avatar: $avatarUrl");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const _AppBarTitle(),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black, size: 26),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const EditProfilePage()),
            ),
          ),
        ],
        backgroundColor: Colors.yellow.shade600,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MainPage()),
            );
          }
        },
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  child: Image(
                    image: avatarUrl.startsWith("http")
                        ? NetworkImage(avatarUrl)
                        : const AssetImage("assets/default_avatar.png") as ImageProvider,
                    fit: BoxFit.cover, // Сохраняем пропорции
                    errorBuilder: (context, error, stackTrace) {
                      print("Error loading image: $error"); // Отладка: выводим ошибку загрузки
                      return Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child: Text(
                            "Ошибка загрузки",
                            style: TextStyle(color: Colors.red, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 15),
                _buildUserInfo(),
                const SizedBox(height: 10),
                _buildTeamInfo(),
                const SizedBox(height: 20),
                _buildStatsSection(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserInfo() {
    return Column(
      children: [
        Text(
          userName,
          style: const TextStyle(fontSize: 37, fontWeight: FontWeight.bold, color: Colors.black87),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          "$userPoints баллов",
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
        ),
      ],
    );
  }

  Widget _buildTeamInfo() {
    return Column(
      children: [
        Text(
          "🚀 $teamName",
          style: const TextStyle(fontSize: 22, color: Colors.black),
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    return Column(
      children: [
        _buildStatCard("19 Missionen erfüllt", "2680 pts"),
        _buildStatCard("254504 Schritte", "1609 pts"),
        _buildStatCard("5677 Laufen", "109 pts"),
      ],
    );
  }

  Widget _buildStatCard(String title, String points) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        onTap: () {
          // Добавьте действие при нажатии
        },
        borderRadius: BorderRadius.circular(10),
        child: ListTile(
          title: Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green[300]!, Colors.green[400]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              points,
              style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}

class _AppBarTitle extends StatelessWidget {
  const _AppBarTitle();

  @override
  Widget build(BuildContext context) {
    return const Text(
      "Мой профиль",
      style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
    );
  }
}