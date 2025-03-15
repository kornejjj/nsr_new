import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main_page.dart';
import 'edit_profile_page.dart';
import 'bottom_nav_bar.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Хранение данных профиля
  String userName = "Загрузка...";
  String teamName = "Без команды";
  String avatarUrl = "assets/default_avatar.png";
  int userPoints = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    String newUserName = userName;
    String newTeamName = "Без команды";
    String newAvatarUrl = avatarUrl;
    int newUserPoints = userPoints;
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (userDoc.exists) {
        var data = userDoc.data() as Map<String, dynamic>;
        newUserName = "${data['firstName'] ?? ''} ${data['lastName'] ?? ''}".trim();
        String? avatar = data['avatar'] as String?;
        newAvatarUrl = (avatar != null && avatar.isNotEmpty && avatar.startsWith("http"))
            ? avatar
            : "assets/default_avatar.png";
        newUserPoints = (data['points'] ?? 0) is int
            ? data['points']
            : (data['points'] ?? 0).toInt();
        String? teamId = data['teamId'] as String?;
        if (teamId != null && teamId.isNotEmpty) {
          try {
            DocumentSnapshot teamDoc = await FirebaseFirestore.instance.collection('teams').doc(teamId).get();
            if (teamDoc.exists) {
              newTeamName = (teamDoc.data() as Map<String, dynamic>)['name'] ?? "Без команды";
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Ошибка загрузки команды: $e")),
            );
          }
        }
      } else {
        // Если документ пользователя не найден
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Данные пользователя не найдены")),
        );
        newAvatarUrl = "assets/default_avatar.png";
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ошибка загрузки данных: $e")),
      );
      newAvatarUrl = "assets/default_avatar.png";
    }
    if (!mounted) return;
    setState(() {
      userName = newUserName.isNotEmpty ? newUserName : userName;
      teamName = newTeamName;
      avatarUrl = newAvatarUrl;
      userPoints = newUserPoints;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const _AppBarTitle(),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black, size: 26),
            onPressed: () {
              // После возврата из редактирования профиля перезагружаем данные
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EditProfilePage()),
              ).then((_) => _loadUserData());
            },
          ),
        ],
        backgroundColor: Colors.yellow.shade600,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 3,
        onDestinationSelected: (_) {},
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 20, bottom: 15),
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 56,
                      backgroundImage: avatarUrl.startsWith("http")
                          ? NetworkImage(avatarUrl)
                          : const AssetImage("assets/default_avatar.png") as ImageProvider,
                      child: ClipOval(
                        child: Image(
                          image: avatarUrl.startsWith("http")
                              ? NetworkImage(avatarUrl)
                              : const AssetImage("assets/default_avatar.png") as ImageProvider,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            if (mounted) {
                              setState(() {
                                avatarUrl = "assets/default_avatar.png";
                              });
                            }
                            return Image.asset(
                              "assets/default_avatar.png",
                              fit: BoxFit.cover,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                _buildUserInfo(),
                const SizedBox(height: 10),
                _buildTeamInfo(),
                const SizedBox(height: 20),
                _buildStatsSection(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserInfo() {
    return Column(
      children: [
        Text(
          userName,
          style: const TextStyle(fontSize: 37, fontWeight: FontWeight.bold, color: Colors.black87),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          "$userPoints баллов",
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
        ),
      ],
    );
  }

  Widget _buildTeamInfo() {
    return Column(
      children: [
        Text(
          teamName,
          style: const TextStyle(fontSize: 22, color: Colors.black),
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    return Column(
      children: [
        _buildStatCard("19 Missionen erfüllt", "2680 pts"),
        _buildStatCard("254504 Schritte", "1609 pts"),
        _buildStatCard("5677 Laufen", "109 pts"),
      ],
    );
  }

  Widget _buildStatCard(String title, String points) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(10),
        child: ListTile(
          title: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green[300]!, Colors.green[400]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              points,
              style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}

class _AppBarTitle extends StatelessWidget {
  const _AppBarTitle();

  @override
  Widget build(BuildContext context) {
    return const Text(
      "Мой профиль",
      style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
    );
  }
}
