import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main_page.dart';
import 'team_page.dart';
import 'team_selection_page.dart';
import 'profile_page.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onDestinationSelected;

  const BottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onDestinationSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (index) {
        // Избегаем повторной навигации на ту же страницу
        if (index == currentIndex) {
          onDestinationSelected(index);
          return;
        }
        onDestinationSelected(index);
        _navigateToPage(context, index);
      },
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home), label: 'Главная'),
        NavigationDestination(icon: Icon(Icons.shopping_cart), label: 'Магазин'),
        NavigationDestination(icon: Icon(Icons.group), label: 'Команда'),
        NavigationDestination(icon: Icon(Icons.person), label: 'Профиль'),
      ],
    );
  }

  void _navigateToPage(BuildContext context, int index) {
    switch (index) {
      case 0: // Главная
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainPage()),
        );
        break;
      case 1: // Магазин
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
          MaterialPageRoute(builder: (context) => const ProfilePage()),
        );
        break;
    }
  }

  Future<void> _navigateToTeamPage(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (userDoc.exists && (userDoc['teamId'] ?? null) != null) {
      String teamId = userDoc['teamId'];
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => TeamPage(teamId: teamId)),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const TeamSelectionPage()),
      );
    }
  }
}
