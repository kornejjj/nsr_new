import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'bottom_nav_bar.dart';
import 'login_page.dart';

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
  String appLanguage = "Русский";
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => null); // Обновляем состояние, чтобы показать индикатор загрузки
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

  Future<void> _connectSportsApp() async {
    await showDialog(
      context: context,
      builder: (context) => _buildDialog(
        title: "Подключить спортивное приложение",
        content: const Text("Подключиться к Google Fit или Apple Health?"),
        onCancel: () => Navigator.pop(context),
        onConfirm: () async {
          try {
            await _firestore.collection('users').doc(_auth.currentUser!.uid).set(
              {'sportsAppConnected': true},
              SetOptions(merge: true),
            );
            if (mounted) {
              setState(() {
                isSportsAppConnected = true;
              });
            }
            Navigator.pop(context);
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Ошибка подключения: $e")),
              );
            }
          }
        },
        confirmText: "Подключить",
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
        TextButton(
          onPressed: onConfirm,
          child: Text(confirmText, style: TextStyle(color: confirmTextColor ?? Colors.blue)),
        ),
      ],
    );
  }

  Widget _buildOptionCard({required String title, required String subtitle, required IconData icon, VoidCallback? onTap, Color iconColor = Colors.grey}) {
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
      bottomNavigationBar: BottomNavBar(currentIndex: 3, onDestinationSelected: (index) {}),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 20),
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
                        return Image.asset("assets/default_avatar.png", fit: BoxFit.cover);
                      },
                    ),
                  ),
                ),
              ),
            ),
            TextButton(
              onPressed: _pickImage,
              child: const Text("Изменить аватар", style: TextStyle(color: Colors.blue, fontSize: 16)),
            ),
            const SizedBox(height: 20),
            _buildOptionCard(
              title: "Имя",
              subtitle: "$firstName $lastName",
              icon: Icons.edit,
              onTap: _updateName,
            ),
            const SizedBox(height: 10),
            _buildOptionCard(
              title: "Email",
              subtitle: userEmail,
              icon: Icons.edit,
              onTap: _updateEmail,
            ),
            const SizedBox(height: 10),
            _buildOptionCard(
              title: "Пароль",
              subtitle: "••••••••",
              icon: Icons.edit,
              onTap: _updatePassword,
            ),
            const SizedBox(height: 10),
            _buildOptionCard(
              title: "Язык приложения",
              subtitle: appLanguage,
              icon: Icons.edit,
              onTap: _updateLanguage,
            ),
            const SizedBox(height: 10),
            _buildOptionCard(
              title: "Спортивное приложение",
              subtitle: isSportsAppConnected ? "Подключено" : "Не подключено",
              icon: Icons.link,
              onTap: _connectSportsApp,
            ),
            const SizedBox(height: 10),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: 5,
              child: ListTile(
                title: const Text("Баллы", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("$userPoints баллов"),
                trailing: const Icon(Icons.star, color: Colors.yellow),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _logout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text("Выйти", style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _deleteAccount,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text("Удалить аккаунт", style: TextStyle(fontSize: 16, color: Colors.red)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
