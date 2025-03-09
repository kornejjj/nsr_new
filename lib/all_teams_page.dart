import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main_page.dart';
import 'team_page.dart'; // Импортируем TeamPage
import 'bottom_nav_bar.dart'; // Импортируем BottomNavBar

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
        centerTitle: true, // Выравниваем текст по центру
        automaticallyImplyLeading: false, // Убираем стрелку назад
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: 2, onDestinationSelected: (_) {}), // Убираем const
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

            // Сортируем команды по количеству баллов (по убыванию)
            final teams = snapshot.data!.docs;
            teams.sort((a, b) {
              final aPoints = (a['points'] ?? 0).toInt();
              final bPoints = (b['points'] ?? 0).toInt();
              return bPoints.compareTo(aPoints);
            });

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: teams.length,
              itemBuilder: (context, index) {
                final team = teams[index].data() as Map<String, dynamic>;

                // Место команды в рейтинге (индекс + 1)
                final teamPlace = index + 1;

                return _TeamCard(
                  name: team['name'] ?? 'Без названия',
                  points: team['points']?.toString() ?? '0',
                  teamId: teams[index].id, // Передаем teamId
                  avatarUrl: team['avatar'] ?? 'assets/team_logo.png', // Добавляем аватар
                  teamPlace: teamPlace, // Передаем место команды
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// 📌 **Карточка команды**
class _TeamCard extends StatelessWidget {
  final String name;
  final String points;
  final String teamId; // Добавляем teamId
  final String avatarUrl; // Добавляем аватар
  final int teamPlace; // Место команды в рейтинге

  const _TeamCard({
    required this.name,
    required this.points,
    required this.teamId, // Принимаем teamId
    required this.avatarUrl, // Принимаем аватар
    required this.teamPlace, // Принимаем место команды
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 5,
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          // Переход на страницу команды
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TeamPage(teamId: teamId), // Передаем teamId
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Место команды в рейтинге
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.amber[800],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$teamPlace',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Аватар команды
              CircleAvatar(
                radius: 30,
                backgroundImage: avatarUrl.startsWith("http")
                    ? NetworkImage(avatarUrl)
                    : AssetImage(avatarUrl) as ImageProvider,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _buildInfoItem(Icons.star, '$points очков'),
                  ],
                ),
              ),
            ],
          ),
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