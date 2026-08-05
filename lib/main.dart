import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const KasirSatSetApp());
}

class KasirSatSetApp extends StatelessWidget {
  const KasirSatSetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kasir Sat-Set',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color.fromARGB(255, 18, 32, 47),
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
