import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main_page.dart';
import 'edit_profile_page.dart';
import 'bottom_nav_bar.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key); // Добавлен параметр key

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _currentIndex = 3; // Текущий индекс для BottomNavBar
  String userName = "Загрузка...";
  String teamName = "Без команды";
  String avatarUrl = "assets/default_avatar.png";
  int userPoints = 3663; // Новое поле: Баллы участника

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();

    if (userDoc.exists) {
      setState(() {
        userName = "${userDoc['firstName']} ${userDoc['lastName']}";
        avatarUrl = userDoc['avatar'] ?? "assets/default_avatar.png";
        userPoints = userDoc['points'] ?? 3663; // Загружаем баллы из Firestore
      });

      if (userDoc['teamId'] != null) {
        DocumentSnapshot teamDoc = await FirebaseFirestore.instance.collection('teams').doc(userDoc['teamId']).get();
        if (teamDoc.exists) {
          setState(() {
            teamName = teamDoc['name'];
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Stack(
          alignment: Alignment.center,
          children: [
            const Center(
              child: Text(
                "Мой профиль",
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
              ),
            ),
            Positioned(
              right: 16, // Отступ справа
              child: IconButton(
                icon: const Icon(Icons.settings, color: Colors.black, size: 26),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => EditProfilePage()),
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
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });

          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => MainPage()),
            );
          }
        },
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 50),
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: avatarUrl.startsWith("http")
                        ? NetworkImage(avatarUrl)
                        : AssetImage(avatarUrl) as ImageProvider,
                    backgroundColor: Colors.transparent,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    userName,
                    style: const TextStyle(fontSize: 37, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "🚀 $teamName",
                    style: const TextStyle(fontSize: 22, color: Colors.black),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "$userPoints баллов",
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                  const SizedBox(height: 20),
                  _buildStatCard("19 Missionen erfüllt", "2680 pts"),
                  _buildStatCard("254504 Schritte", "1609 pts"),
                  _buildStatCard("5677 Laufen", "109 pts"),
                ],
              ),
            ),
          ),
        ],
      ),
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
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500), // Увеличен размер
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green[300]!, Colors.green[400]!], // Новый цвет
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              points,
              style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold), // Увеличен размер
            ),
          ),
        ),
      ),
    );
  }
}