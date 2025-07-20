import 'package:event_reminder_flutter/screens/home_screen.dart';
import 'package:event_reminder_flutter/screens/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:event_reminder_flutter/screens/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("🔔 [Background] Notification Title: ${message.notification?.title}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const EventReminderApp());
}

class EventReminderApp extends StatefulWidget {
  const EventReminderApp({super.key});

  @override
  State<EventReminderApp> createState() => _EventReminderAppState();
}

class _EventReminderAppState extends State<EventReminderApp> {
  @override
  void initState() {
    super.initState();
    setupFCM();
  }

  void setupFCM() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    await messaging.requestPermission();
    String? token = await messaging.getToken();
    print("✅ FCM Token: $token");
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("fcm_token", token!);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("🔔 [Foreground] ${message.notification?.title}");

      final context = navigatorKey.currentContext;
      if (context != null && message.notification != null) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(message.notification!.title ?? 'Notification'),
            content: Text(message.notification!.body ?? ''),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("🔁 [Opened from notification] ${message.notification?.title}");
      // Optionally navigate or show UI here too
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Event Reminder',
      navigatorKey: navigatorKey, // 🗝️ Add global navigator key
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(), // 👇 We'll make this now
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}
