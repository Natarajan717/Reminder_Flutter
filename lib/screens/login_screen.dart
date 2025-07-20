import 'package:flutter/material.dart';
import 'package:event_reminder_flutter/screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? error;

  void _login() async {
    final success = await ApiService().login(
      _emailController.text,
      _passwordController.text,
    );

    if (success) {
      await setupFCM(); // 📌 Send token to backend
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      setState(() => error = "Login failed. Check your credentials.");
    }
  }

  Future<void> setupFCM() async {
    final prefs = await SharedPreferences.getInstance();
    final fcm_token = prefs.getString("fcm_token");
    final access_token = prefs.getString("access_token");
    print("🔥 FCM Token: $fcm_token");
    print("🔥 access Token: $access_token");

    if (fcm_token != null) {
      await ApiService().sendFcmTokenToBackend(fcm_token);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: "Email")),
            TextField(controller: _passwordController, decoration: const InputDecoration(labelText: "Password"), obscureText: true),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _login, child: const Text("Login")),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                );
              },
              child: const Text("Don't have an account? Register"),
            ),
            if (error != null) Text(error!, style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }
}
