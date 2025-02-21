import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main_page.dart';

class AllTeamsPage extends StatelessWidget {
  const AllTeamsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Все команды',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.yellow[600],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      bottomNavigationBar: _buildBottomNavBar(context),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFD54F), Color(0xFFFFE082), Color(0xFFFFF9C4)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('teams').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.black));
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Ошибка: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
              );
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text(
                  'Команды не найдены',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
              );
            }

            final teams = snapshot.data!.docs;

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: teams.length,
              itemBuilder: (context, index) {
                final team = teams[index].data() as Map<String, dynamic>;
                return _TeamCard(
                  name: team['name'] ?? 'Без названия',
                  points: team['points']?.toString() ?? '0',
                  membersCount: (team['members'] as List?)?.length.toString() ?? '0',
                );
              },
            );
          },
        ),
      ),
    );
  }

  /// 📌 **Закреплённая нижняя панель**
  Widget _buildBottomNavBar(BuildContext context) {
    return NavigationBar(
      selectedIndex: 2, // Выбрана вкладка Team
      onDestinationSelected: (index) {
        if (index == 0) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MainPage()));
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

/// 📌 **Карточка команды**
class _TeamCard extends StatelessWidget {
  final String name;
  final String points;
  final String membersCount;

  const _TeamCard({
    required this.name,
    required this.points,
    required this.membersCount,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 5,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildInfoItem(Icons.people, '$membersCount участников'),
                const SizedBox(width: 16),
                _buildInfoItem(Icons.star, '$points очков'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.amber[800]),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 16)),
      ],
    );
  }
}
