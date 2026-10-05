import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme.dart';
import 'features/language/language_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/home/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: QueueLessCitizenApp()));
}

class QueueLessCitizenApp extends StatefulWidget {
  const QueueLessCitizenApp({super.key});

  @override
  State<QueueLessCitizenApp> createState() => _QueueLessCitizenAppState();
}

class _QueueLessCitizenAppState extends State<QueueLessCitizenApp> {
  Locale _currentLocale = const Locale('en');

  void _setLocale(Locale locale) {
    setState(() {
      _currentLocale = locale;
    });
  }

  late final GoRouter _router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => LanguageScreen(onSelectLocale: _setLocale),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'QueueLess',
      debugShowCheckedModeBanner: false,
      theme: CivicTheme.lightTheme,
      locale: _currentLocale,
      supportedLocales: const [
        Locale('en'),
        Locale('gu'),
        Locale('hi'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: _router,
    );
  }
}
