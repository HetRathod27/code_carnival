import 'package:flutter/material.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme.dart';
import 'features/language/language_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/home/home_screen.dart';
import 'features/browse/offices_screen.dart';
import 'features/browse/services_screen.dart';
import 'features/book/book_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString('ql_language');
    if (savedCode != null && mounted) {
      setState(() {
        _currentLocale = Locale(savedCode);
      });
    }
  }

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
      GoRoute(
        path: '/offices',
        builder: (context, state) => const OfficesScreen(),
      ),
      GoRoute(
        path: '/offices/:officeId/services',
        builder: (context, state) {
          final officeId = state.pathParameters['officeId'] ?? '';
          return ServicesScreen(officeId: officeId);
        },
      ),
      GoRoute(
        path: '/book/:officeId/:serviceId',
        builder: (context, state) {
          final officeId = state.pathParameters['officeId'] ?? '';
          final serviceId = state.pathParameters['serviceId'] ?? '';
          return BookScreen(officeId: officeId, serviceId: serviceId);
        },
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
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: _router,
    );
  }
}
