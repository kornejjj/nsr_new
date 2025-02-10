import 'package:flutter/material.dart';
import 'main_page.dart';
import 'edit_profile_page.dart'; // ✅ Подключаем страницу редактирования профиля

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _currentIndex = 3; // ✅ Устанавливаем "Profil" активным

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Center(child: Text("Mein Profil")), // ✅ Центрируем заголовок
        backgroundColor: Colors.yellow.shade600,
        elevation: 0,
        automaticallyImplyLeading: false, // ❌ Убираем кнопку "Назад"
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  const CircleAvatar(
                    radius: 60,
                    backgroundImage: AssetImage('assets/profile.jpg'), // ✅ Фото профиля
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Artem Kornienko",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "🚀 Team Ukraine 🇺🇦",
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 10),
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
                      "Profil bearbeiten",
                      style: TextStyle(fontSize: 16, color: Colors.black),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildStatCard("19 Missionen erfüllt", "2680 pts"),
                  _buildStatCard("254504 Schritte", "1609 pts"),
                ],
              ),
            ),
          ),
          _buildBottomNavBar(), // ✅ Нижняя панель навигации остается на месте
        ],
      ),
    );
  }

  /// Виджет карточки статистики
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
          // ✅ Переход только если выбрана другая вкладка
          switch (index) {
            case 0:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => MainPage()),
              );
              break;
            case 1:
            case 2:
            // ✅ Здесь можно добавить переход на другие страницы
              break;
            case 3:
            // ✅ Ничего не делаем, так как уже на странице "Profil"
              break;
          }
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
