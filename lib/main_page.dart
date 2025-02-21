import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_page.dart';
import 'team_page.dart';
import 'team_selection_page.dart';

/// Главная страница приложения
class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  final List<ButtonData> _actionButtons = [
    ButtonData(Icons.flag, 'Missionen', Colors.orange),
    ButtonData(Icons.directions_run, 'Schritte', Colors.green),
    ButtonData(Icons.leaderboard, 'Aktivität', Colors.blue),
    ButtonData(Icons.wb_sunny, 'Wetter', Colors.purple),
  ];

  /// 🔥 Получаем имя пользователя из Firestore
  Future<String> _fetchUserName() async {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    DocumentSnapshot userDoc =
    await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return userDoc.exists ? userDoc['firstName'] ?? "User" : "User";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: _buildBottomNavBar(),
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
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 15),

              /// 🔥 Динамическое имя пользователя
              FutureBuilder<String>(
                future: _fetchUserName(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Text(
                      "Let's Go!",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    );
                  }
                  return Text(
                    "Let's Go ${snapshot.data}!",
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  );
                },
              ),

              const SizedBox(height: 15),
              const _StatsSection(),
              Expanded(child: _buildActionButtons()),
            ],
          ),
        ),
      ),
    );
  }

  /// 📌 Заголовок (Логотип по центру, ракеты и колокольчик)
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
                  child: Icon(Icons.rocket_launch, color: Colors.black45, size: 26),
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
            child: IconButton(
              icon: const Icon(Icons.notifications, color: Colors.black54, size: 26),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }

  /// 📌 Кнопки действий
  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(25),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          childAspectRatio: 1.2,
        ),
        itemCount: _actionButtons.length,
        itemBuilder: (context, index) {
          final button = _actionButtons[index];
          return _CustomSquareButton(
            icon: button.icon,
            text: button.text,
            color: button.color,
            iconSize: 36,
            fontSize: 20,
          );
        },
      ),
    );
  }

  /// 📌 Нижняя панель навигации
  Widget _buildBottomNavBar() {
    return NavigationBar(
      selectedIndex: _currentIndex,
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
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home), label: 'Главная'),
        NavigationDestination(icon: Icon(Icons.shopping_cart), label: 'Магазин'),
        NavigationDestination(icon: Icon(Icons.group), label: 'Команда'),
        NavigationDestination(icon: Icon(Icons.person), label: 'Профиль'),
      ],
    );
  }

  /// ✅ Проверяем, есть ли у пользователя команда
  Future<void> _navigateToTeamPage() async {
    String userId = FirebaseAuth.instance.currentUser!.uid;

    QuerySnapshot teams = await FirebaseFirestore.instance
        .collection('teams')
        .where('members', arrayContains: userId)
        .get();

    if (teams.docs.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => TeamPage()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => TeamSelectionPage()),
      );
    }
  }
}

/// 📌 Блок статистики (Team)
class _StatsSection extends StatelessWidget {
  const _StatsSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 40,
                backgroundImage: AssetImage('assets/flag.png'),
                backgroundColor: Colors.transparent,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Team Ukraine',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: 0.9,
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                      minHeight: 14,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      '125.365 Punkte',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 📌 Кнопки квадратные
class _CustomSquareButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final double iconSize;
  final double fontSize;

  const _CustomSquareButton({
    required this.icon,
    required this.text,
    required this.color,
    this.iconSize = 42,
    this.fontSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(15),
      elevation: 5,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(15),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.8), color],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: iconSize),
              const SizedBox(height: 7),
              Text(
                text,
                style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 📌 Модель данных для кнопок
class ButtonData {
  final IconData icon;
  final String text;
  final Color color;

  ButtonData(this.icon, this.text, this.color);
}
