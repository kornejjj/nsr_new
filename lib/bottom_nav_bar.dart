import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Импортируем FirebaseAuth
import 'package:cloud_firestore/cloud_firestore.dart'; // Импортируем FirebaseFirestore
import 'main_page.dart'; // Импортируем MainPage
import 'team_page.dart'; // Импортируем TeamPage
import 'team_selection_page.dart'; // Импортируем TeamSelectionPage
import 'profile_page.dart'; // Импортируем ProfilePage
import 'edit_profile_page.dart'; // Импортируем EditProfilePage

/// 📌 **Закреплённая нижняя панель**
class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onDestinationSelected;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (index) {
        onDestinationSelected(index); // Вызываем переданный колбэк
        _navigateToPage(context, index); // Вызываем навигацию
      },
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home), label: 'Главная'),
        NavigationDestination(icon: Icon(Icons.shopping_cart), label: 'Магазин'),
        NavigationDestination(icon: Icon(Icons.group), label: 'Команда'),
        NavigationDestination(icon: Icon(Icons.person), label: 'Профиль'),
      ],
    );
  }

  /// 🔥 Навигация на страницы
  void _navigateToPage(BuildContext context, int index) {
    switch (index) {
      case 0: // Главная
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainPage()),
        );
        break;
      case 1: // Магазин
      // Добавьте переход на страницу магазина, если она есть
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Магазин пока недоступен")),
        );
        break;
      case 2: // Команда
        _navigateToTeamPage(context);
        break;
      case 3: // Профиль
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ProfilePage()),
        );
        break;
    }
  }

  /// 🔥 Переход на страницу команды
  Future<void> _navigateToTeamPage(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final teams = await FirebaseFirestore.instance
        .collection('teams')
        .where('members', arrayContains: user.uid)
        .get();

    if (teams.docs.isNotEmpty) {
      String teamId = teams.docs.first.id;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => TeamPage(teamId: teamId),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => TeamSelectionPage()),
      );
    }
  }
}