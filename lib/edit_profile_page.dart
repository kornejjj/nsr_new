import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'bottom_nav_bar.dart';
import 'login_page.dart';
import 'strava_service.dart'; // Импортируем наш новый сервис

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({Key? key}) : super(key: key);

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  String avatarUrl = "";
  String firstName = "";
  String lastName = "";
  String userEmail = "";
  int userPoints = 0;
  bool isSportsAppConnected = false;
  bool isStravaConnected = false; // Добавляем флаг для Strava
  String appLanguage = "Русский";
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StravaService _stravaService = StravaService(); // Инициализируем StravaService

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      String userId = _auth.currentUser!.uid;
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists && mounted) {
        var data = userDoc.data() as Map<String, dynamic>;
        setState(() {
          firstName = data['firstName'] ?? "";
          lastName = data['lastName'] ?? "";
          userEmail = data['email'] ?? "";
          avatarUrl = data['avatar'] ?? "assets/default_avatar.png";
          userPoints = (data['points'] ?? 0) is int ? data['points'] : (data['points'] ?? 0).toInt();
          isSportsAppConnected = data['sportsAppConnected'] ?? false;
          isStravaConnected = data['stravaConnected'] ?? false; // Загружаем статус Strava
          appLanguage = data['language'] ?? "Русский";
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Ошибка загрузки данных: $e")),
        );
      }
    }
  }

  Future<void> _connectSportsApp() async {
    await showDialog(
      context: context,
      builder: (context) => _buildDialog(
        title: "Подключить спортивное приложение",
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Выберите приложение для подключения:"),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: isStravaConnected
                  ? null
                  : () async {
                Navigator.pop(context);
                await _connectStrava();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                isStravaConnected ? "Strava уже подключен" : "Подключить Strava",
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: isSportsAppConnected && !isStravaConnected
                  ? null
                  : () async {
                Navigator.pop(context);
                await _connectGoogleFitOrAppleHealth();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                isSportsAppConnected && !isStravaConnected
                    ? "Google Fit / Apple Health уже подключен"
                    : "Подключить Google Fit / Apple Health",
              ),
            ),
          ],
        ),
        onCancel: () => Navigator.pop(context),
        onConfirm: () {},
        confirmText: "",
      ),
    );
  }

  Future<void> _connectStrava() async {
    try {
      // Вызываем авторизацию в Strava и получаем access_token, refresh_token, expires_at
      final authResult = await _stravaService.authenticate();
      if (authResult != null) {
        final tokenData = authResult as Map<String, dynamic>;
        var accessToken = tokenData['access_token'] as String;
        var refreshToken = tokenData['refresh_token'] as String;
        var expiresAt = (tokenData['expires_at'] as num).toInt();

        // Сохраняем статус подключения и токены в Firestore
        await _firestore.collection('users').doc(_auth.currentUser!.uid).set(
          {
            'sportsAppConnected': true,
            'stravaConnected': true,
            'stravaAccessToken': accessToken,
            'stravaRefreshToken': refreshToken,
            'stravaExpiresAt': expiresAt,
          },
          SetOptions(merge: true),
        );

        // Проверяем срок действия access_token и обновляем его при необходимости
        final currentTimeSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        if (expiresAt <= currentTimeSec) {
          final refreshResult = await _stravaService.refreshAccessToken(refreshToken);
          if (refreshResult != null) {
            final refreshData = refreshResult as Map<String, dynamic>;
            accessToken = refreshData['access_token'] as String;
            refreshToken = refreshData['refresh_token'] as String;
            expiresAt = (refreshData['expires_at'] as num).toInt();
            // Обновляем токены в Firestore после рефреша
            await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
              'stravaAccessToken': accessToken,
              'stravaRefreshToken': refreshToken,
              'stravaExpiresAt': expiresAt,
            });
          } else {
            // Если не удалось обновить токен
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Не удалось обновить токен Strava. Попробуйте снова.")),
            );
            return;
          }
        }

        // Получаем очки активности пользователя из Strava
        final int newPoints = await _stravaService.fetchActivityPoints(accessToken);
        if (newPoints != null) {
          // Начисляем полученные очки и обновляем поле points в Firestore
          await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
            'points': FieldValue.increment(newPoints),
          });
          if (mounted) {
            setState(() {
              userPoints += newPoints;
            });
          }
        }

        // Обновляем флаги подключения в состоянии
        if (mounted) {
          setState(() {
            isSportsAppConnected = true;
            isStravaConnected = true;
          });
        }
        // Уведомляем об успешном подключении Strava
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Strava успешно подключен")),
        );
      } else {
        // Пользователь отменил авторизацию или произошла ошибка
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Не удалось подключить Strava")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Ошибка подключения Strava: $e")),
        );
      }
    }
  }


  Future<void> _connectGoogleFitOrAppleHealth() async {
    try {
      await _firestore.collection('users').doc(_auth.currentUser!.uid).set(
        {'sportsAppConnected': true, 'stravaConnected': false},
        SetOptions(merge: true),
      );
      if (mounted) {
        setState(() {
          isSportsAppConnected = true;
          isStravaConnected = false;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Google Fit / Apple Health подключен")),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Ошибка подключения: $e")),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => null);
      try {
        File imageFile = File(pickedFile.path);
        String userId = _auth.currentUser!.uid;
        Reference storageRef = FirebaseStorage.instance.ref().child('avatars/$userId.jpg');
        await storageRef.putFile(imageFile);
        String downloadUrl = await storageRef.getDownloadURL();
        if (mounted) {
          await _firestore.collection('users').doc(userId).update({'avatar': downloadUrl});
          setState(() {
            avatarUrl = downloadUrl;
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Аватар успешно обновлён")),
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Ошибка загрузки аватара: $e")),
          );
        }
      }
    }
  }

  Future<void> _updateName() async {
    String newFirstName = firstName;
    String newLastName = lastName;
    await showDialog(
      context: context,
      builder: (context) => _buildDialog(
        title: "Изменить имя",
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: "Имя"),
              onChanged: (value) => newFirstName = value,
              controller: TextEditingController(text: firstName),
            ),
            const SizedBox(height: 10),
            TextField(
              decoration: const InputDecoration(labelText: "Фамилия"),
              onChanged: (value) => newLastName = value,
              controller: TextEditingController(text: lastName),
            ),
          ],
        ),
        onCancel: () => Navigator.pop(context),
        onConfirm: () async {
          if (newFirstName.isNotEmpty && newLastName.isNotEmpty) {
            await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
              'firstName': newFirstName,
              'lastName': newLastName,
            });
            if (mounted) {
              setState(() {
                firstName = newFirstName;
                lastName = newLastName;
              });
            }
            Navigator.pop(context);
          }
        },
        confirmText: "Сохранить",
      ),
    );
  }

  Future<void> _updateEmail() async {
    String oldEmail = userEmail;
    String newEmail = userEmail;
    String confirmEmail = userEmail;
    final currentContext = context;
    await showDialog(
      context: currentContext,
      builder: (context) => _buildDialog(
        title: "Изменить email",
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: "Текущий email"),
              controller: TextEditingController(text: oldEmail),
              enabled: false,
            ),
            const SizedBox(height: 10),
            TextField(
              decoration: const InputDecoration(labelText: "Новый email"),
              onChanged: (value) => newEmail = value,
            ),
            const SizedBox(height: 10),
            TextField(
              decoration: const InputDecoration(labelText: "Подтвердите email"),
              onChanged: (value) => confirmEmail = value,
            ),
          ],
        ),
        onCancel: () => Navigator.pop(context),
        onConfirm: () async {
          if (newEmail.isNotEmpty &&
              confirmEmail.isNotEmpty &&
              newEmail == confirmEmail &&
              RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$").hasMatch(newEmail)) {
            try {
              await _auth.currentUser!.verifyBeforeUpdateEmail(newEmail);
              await _firestore.collection('users').doc(_auth.currentUser!.uid).update({'email': newEmail});
              if (mounted) {
                setState(() {
                  userEmail = newEmail;
                });
              }
              Navigator.pop(context);
              ScaffoldMessenger.of(currentContext).showSnackBar(
                const SnackBar(content: Text("Проверьте вашу почту для подтверждения нового email")),
              );
            } catch (e) {
              ScaffoldMessenger.of(currentContext).showSnackBar(
                SnackBar(content: Text("Ошибка: $e")),
              );
            }
          } else {
            ScaffoldMessenger.of(currentContext).showSnackBar(
              const SnackBar(content: Text("Email не совпадают или введён некорректно")),
            );
          }
        },
        confirmText: "Сохранить",
      ),
    );
  }

  Future<void> _updatePassword() async {
    String oldPassword = "";
    String newPassword = "";
    String confirmPassword = "";
    final currentContext = context;
    await showDialog(
      context: currentContext,
      builder: (context) => _buildDialog(
        title: "Изменить пароль",
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: "Текущий пароль"),
              obscureText: true,
              onChanged: (value) => oldPassword = value,
            ),
            const SizedBox(height: 10),
            TextField(
              decoration: const InputDecoration(labelText: "Новый пароль"),
              obscureText: true,
              onChanged: (value) => newPassword = value,
            ),
            const SizedBox(height: 10),
            TextField(
              decoration: const InputDecoration(labelText: "Подтвердите пароль"),
              obscureText: true,
              onChanged: (value) => confirmPassword = value,
            ),
          ],
        ),
        onCancel: () => Navigator.pop(context),
        onConfirm: () async {
          if (newPassword.isNotEmpty &&
              confirmPassword.isNotEmpty &&
              newPassword == confirmPassword &&
              newPassword.length >= 6) {
            try {
              await _auth.signInWithEmailAndPassword(
                email: _auth.currentUser!.email!,
                password: oldPassword,
              );
              await _auth.currentUser!.updatePassword(newPassword);
              Navigator.pop(context);
              ScaffoldMessenger.of(currentContext).showSnackBar(
                const SnackBar(content: Text("Пароль обновлён")),
              );
            } catch (e) {
              ScaffoldMessenger.of(currentContext).showSnackBar(
                SnackBar(content: Text("Ошибка: $e")),
              );
            }
          } else {
            ScaffoldMessenger.of(currentContext).showSnackBar(
              const SnackBar(content: Text("Пароли не совпадают или слишком короткие")),
            );
          }
        },
        confirmText: "Сохранить",
      ),
    );
  }

  Future<void> _updateLanguage() async {
    String newLanguage = appLanguage;
    await showDialog(
      context: context,
      builder: (context) => _buildDialog(
        title: "Выберите язык",
        content: StatefulBuilder(
          builder: (context, setStateDialog) {
            return DropdownButton<String>(
              value: newLanguage,
              items: ["Русский", "English", "Deutsch"].map((value) {
                return DropdownMenuItem(value: value, child: Text(value));
              }).toList(),
              onChanged: (value) {
                setStateDialog(() {
                  newLanguage = value!;
                });
              },
            );
          },
        ),
        onCancel: () => Navigator.pop(context),
        onConfirm: () async {
          await _firestore.collection('users').doc(_auth.currentUser!.uid).update({'language': newLanguage});
          if (mounted) {
            setState(() {
              appLanguage = newLanguage;
            });
          }
          Navigator.pop(context);
        },
        confirmText: "Сохранить",
      ),
    );
  }

  Future<void> _logout() async {
    await _auth.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  Future<void> _deleteAccount() async {
    final currentContext = context;
    await showDialog(
      context: currentContext,
      builder: (context) => _buildDialog(
        title: "Удалить аккаунт",
        content: const Text("Вы уверены? Это действие необратимо."),
        onCancel: () => Navigator.pop(context),
        onConfirm: () async {
          try {
            String userId = _auth.currentUser!.uid;
            await _firestore.collection('users').doc(userId).delete();
            await _auth.currentUser!.delete();
            Navigator.pop(context);
            Navigator.pushReplacement(
              currentContext,
              MaterialPageRoute(builder: (context) => const LoginPage()),
            );
          } catch (e) {
            Navigator.pop(context);
            ScaffoldMessenger.of(currentContext).showSnackBar(
              SnackBar(content: Text("Ошибка удаления аккаунта: $e")),
            );
          }
        },
        confirmText: "Удалить",
        confirmTextColor: Colors.red,
      ),
    );
  }

  Widget _buildDialog({
    required String title,
    required Widget content,
    required VoidCallback onCancel,
    required VoidCallback onConfirm,
    required String confirmText,
    Color? confirmTextColor,
  }) {
    return AlertDialog(
      title: Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      backgroundColor: Colors.white,
      content: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey[200]!, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: content,
      ),
      actions: [
        TextButton(onPressed: onCancel, child: const Text("Отмена")),
        if (confirmText.isNotEmpty)
          TextButton(
            onPressed: onConfirm,
            child: Text(confirmText, style: TextStyle(color: confirmTextColor ?? Colors.blue)),
          ),
      ],
    );
  }

  Widget _buildOptionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    VoidCallback? onTap,
    Color iconColor = Colors.grey,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 5,
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: Icon(icon, color: iconColor),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)),
        title: const Text(
          "Редактировать профиль",
          style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.yellow.shade600,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: 3, onDestinationSelected: (_) {}),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: 56,
                    backgroundImage: avatarUrl.startsWith("http")
                        ? NetworkImage(avatarUrl)
                        : const AssetImage("assets/default_avatar.png") as ImageProvider,
                  ),
                ),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.amber,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.black, size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Text(
              "$firstName $lastName",
              style: const TextStyle(fontSize: 31, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text(
              userEmail,
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 5),
            Text(
              "$userPoints баллов",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
            ),
            const SizedBox(height: 20),
            _buildOptionCard(
              title: "Изменить имя",
              subtitle: "$firstName $lastName",
              icon: Icons.edit,
              onTap: _updateName,
            ),
            _buildOptionCard(
              title: "Изменить email",
              subtitle: userEmail,
              icon: Icons.email,
              onTap: _updateEmail,
            ),
            _buildOptionCard(
              title: "Изменить пароль",
              subtitle: "••••••••",
              icon: Icons.lock,
              onTap: _updatePassword,
            ),
            _buildOptionCard(
              title: "Подключить спортивное приложение",
              subtitle: isSportsAppConnected
                  ? (isStravaConnected ? "Strava подключен" : "Google Fit / Apple Health подключен")
                  : "Не подключено",
              icon: Icons.directions_run,
              onTap: _connectSportsApp,
              iconColor: isSportsAppConnected ? Colors.green : Colors.grey,
            ),
            _buildOptionCard(
              title: "Язык приложения",
              subtitle: appLanguage,
              icon: Icons.language,
              onTap: _updateLanguage,
            ),
            _buildOptionCard(
              title: "Выйти из аккаунта",
              subtitle: "Выход",
              icon: Icons.logout,
              onTap: _logout,
              iconColor: Colors.red,
            ),
            _buildOptionCard(
              title: "Удалить аккаунт",
              subtitle: "Удаление",
              icon: Icons.delete_forever,
              onTap: _deleteAccount,
              iconColor: Colors.red,
            ),
          ],
        ),
      ),
    );
  }
}