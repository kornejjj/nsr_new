import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main_page.dart';
import 'edit_profile_page.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _currentIndex = 3;
  String userName = "Загрузка...";
  String teamName = "Без команды";
  String avatarUrl = "assets/default_avatar.png";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  /// 🔥 Загружаем данные пользователя из Firestore
  Future<void> _loadUserData() async {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();

    if (userDoc.exists) {
      setState(() {
        userName = "${userDoc['firstName']} ${userDoc['lastName']}";
        avatarUrl = userDoc['avatar'] ?? "assets/default_avatar.png";
      });

      // Загружаем название команды
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

  /// 🔥 Выход из аккаунта
  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Center(child: Text("Мой профиль")),
        backgroundColor: Colors.yellow.shade600,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: avatarUrl.startsWith("http") ? NetworkImage(avatarUrl) : AssetImage(avatarUrl) as ImageProvider,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    userName,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "🚀 $teamName",
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 10),

                  /// ✅ **Кнопки "Редактировать профиль" + "Выход"**
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => EditProfilePage()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.yellow[600],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          "Редактировать профиль",
                          style: TextStyle(fontSize: 16, color: Colors.black),
                        ),
                      ),
                      const SizedBox(width: 10),

                      /// 🔥 **Иконка выхода**
                      IconButton(
                        icon: const Icon(Icons.logout, color: Colors.red, size: 28),
                        tooltip: "Выйти из аккаунта",
                        onPressed: _logout,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  _buildStatCard("19 Missionen erfüllt", "2680 pts"),
                  _buildStatCard("254504 Schritte", "1609 pts"),
                ],
              ),
            ),
          ),
          _buildBottomNavBar(),
        ],
      ),
    );
  }

  /// ✅ Виджет карточки статистики
  Widget _buildStatCard(String title, String points) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.green[300],
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(points, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  /// ✅ **Закрепленный `NavigationBar`**
  Widget _buildBottomNavBar() {
    return NavigationBar(
      selectedIndex: _currentIndex,
      onDestinationSelected: (index) {
        if (index != _currentIndex) {
          switch (index) {
            case 0:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => MainPage()),
              );
              break;
            case 1:
            case 2:
              break;
            case 3:
              break;
          }
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
