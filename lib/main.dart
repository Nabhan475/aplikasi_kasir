import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'screens/login_screen.dart';

class NoTransition extends PageTransitionsBuilder {
  const NoTransition();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => child;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const KasirBuburAyamApp());
}

class KasirBuburAyamApp extends StatelessWidget {
  const KasirBuburAyamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kasir Bubur Ayam 72',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6952AE),
          primary: const Color(0xFF6952AE),
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: NoTransition(),
            TargetPlatform.iOS: NoTransition(),
            TargetPlatform.windows: NoTransition(),
            TargetPlatform.macOS: NoTransition(),
            TargetPlatform.linux: NoTransition(),
          },
        ),
      ),
      home: const LoginScreen(),
    );
  }
}