import 'package:flutter/material.dart';
import 'profile_page.dart'; // ✅ Подключаем страницу профиля

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
              Text(
                "Let's Go Vika!",
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 15),
              const _StatsSection(),
              Expanded( // 🔥 Растягиваем фон до нижней панели
                child: _buildActionButtons(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 📌 Заголовок (Логотип по центру, ракеты и колокольчик выше)
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
              height: 80, // Немного уменьшил логотип
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

  /// 📌 Кнопки действий (растянуты до нижней панели)
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
          childAspectRatio: 1, // 🔹 Делаем кнопки квадратными
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

        if (index == 3) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ProfilePage()),
          );
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
              CircleAvatar(
                radius: 40,
                backgroundImage: const AssetImage('assets/flag.png'),
                backgroundColor: Colors.transparent,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _StatsText('Team Ukraine', 22),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: 0.7,
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                      minHeight: 8,
                    ),
                    const SizedBox(height: 10),
                    const _StatsText('125.365 Punkte', 18),
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
                textAlign: TextAlign.center,
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

/// 📌 Текст для статистики
class _StatsText extends StatelessWidget {
  final String text;
  final double fontSize;

  const _StatsText(this.text, this.fontSize);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600, color: Colors.grey[800]),
    );
  }
}
