import 'package:flutter/material.dart';
import 'profile_page.dart'; // ✅ Подключаем страницу профиля

/// Главная страница приложения
class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  final List<_ButtonData> _actionButtons = [
    _ButtonData(Icons.flag, 'Missionen', Colors.orange),
    _ButtonData(Icons.directions_run, 'Schritte', Colors.green),
    _ButtonData(Icons.leaderboard, 'Aktivität', Colors.blue),
    _ButtonData(Icons.wb_sunny, 'Wetter', Colors.purple),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const _StatsSection(),
            _buildActionButtons(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  /// Создание верхнего AppBar
  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(180),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.yellow, Colors.yellowAccent.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Let's GO Vika!",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.notifications, color: Colors.black),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: Image.asset(
                    'assets/logo.png',
                    height: 90,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Создание сетки кнопок действий
  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          int crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 1,
            ),
            itemCount: _actionButtons.length,
            itemBuilder: (context, index) {
              final button = _actionButtons[index];
              return _CustomSquareButton(
                icon: button.icon,
                text: button.text,
                color: button.color,
              );
            },
          );
        },
      ),
    );
  }

  /// Нижняя панель навигации
  Widget _buildBottomNavBar() {
    return NavigationBar(
      selectedIndex: _currentIndex,
      onDestinationSelected: (index) {
        setState(() {
          _currentIndex = index;
        });

        // ✅ Переход на страницу профиля при нажатии на "Profil"
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

/// Виджет блока статистики команды
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
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
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

/// Виджет квадратных кнопок
class _CustomSquareButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _CustomSquareButton({
    required this.icon,
    required this.text,
    required this.color,
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
              Icon(icon, color: Colors.white, size: 42),
              const SizedBox(height: 8),
              Text(
                text,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Модель данных для кнопок
class _ButtonData {
  final IconData icon;
  final String text;
  final Color color;

  _ButtonData(this.icon, this.text, this.color);
}

/// Виджет для стилизованного текста статистики
class _StatsText extends StatelessWidget {
  final String text;
  final double fontSize;

  const _StatsText(this.text, this.fontSize);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        color: Colors.grey[800],
      ),
    );
  }
}
