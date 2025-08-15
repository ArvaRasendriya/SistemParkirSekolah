import 'package:flutter/material.dart';
import 'package:tefa_parkir/auth/auth_service.dart';
import 'package:tefa_parkir/pages/login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final authService = AuthService();

  // Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  void signUp() async {
    final email = _emailController.text;
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password don't match")),
      );
      return;
    }

    try {
      await authService.signUpWithEmailPassword(email, password);
      Navigator.pushReplacement(context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 30),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D8BFF), Color(0xFF007BFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 80),
              const Text(
                'ParkirApp',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 200),

              CustomInputField(
                controller: _emailController,
                hintText: 'Email',
              ),
              const SizedBox(height: 15),

              CustomInputField(
                controller: _passwordController,
                hintText: 'Password',
                obscureText: true,
              ),
              const SizedBox(height: 15),

              CustomInputField(
                controller: _confirmPasswordController,
                hintText: 'Confirm Password',
                obscureText: true,
              ),
              const SizedBox(height: 30),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: signUp,
                child: const Text(
                  'Sign Up',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 40),

              const Text(
                "Already have an account?",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  );
                },
                child: const Text(
                  "Sign in here!",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.yellow,
                    letterSpacing: -1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomInputField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;

  const CustomInputField({
    super.key,
    required this.controller,
    required this.hintText,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide.none,
        ),
        hintStyle: const TextStyle(color: Colors.grey),
      ),
    );
  }
}
