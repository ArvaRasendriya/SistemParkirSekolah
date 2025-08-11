import 'package:flutter/material.dart';
import 'package:tefa_parkir/auth/auth_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {

  final authservice = AuthService();
  void logout() async{
    await authservice.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        actions: [
          IconButton(
            onPressed: logout, 
            icon: Icon(Icons.logout),
          )
        ],
      ),
    );
  }
}