import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme.dart';

class LanguageScreen extends StatelessWidget {
  final Function(Locale) onSelectLocale;

  const LanguageScreen({super.key, required this.onSelectLocale});

  Future<void> _selectLanguage(BuildContext context, String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ql_language', code);
    onSelectLocale(Locale(code));
    if (context.mounted) {
      context.go('/auth');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              const Center(
                child: Text('🎟️', style: TextStyle(fontSize: 56)),
              ),
              const SizedBox(height: 16),
              const Text(
                'QueueLess',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: CivicTheme.primary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Government Service Appointment & Queue System',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: CivicTheme.textSecondary,
                ),
              ),
              const Spacer(),
              const Text(
                'Select Your Language / તમારી ભાષા પસંદ કરો / अपनी भाषा चुनें',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: CivicTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              _LanguageOption(
                label: 'English',
                sublabel: 'Default Civic Language',
                onTap: () => _selectLanguage(context, 'en'),
              ),
              const SizedBox(height: 12),
              _LanguageOption(
                label: 'ગુજરાતી (Gujarati)',
                sublabel: 'ગુજરાત સરકાર સેવાઓ',
                onTap: () => _selectLanguage(context, 'gu'),
              ),
              const SizedBox(height: 12),
              _LanguageOption(
                label: 'हिन्दी (Hindi)',
                sublabel: 'नागरिक सेवा केंद्र',
                onTap: () => _selectLanguage(context, 'hi'),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String label;
  final String sublabel;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.label,
    required this.sublabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 68,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: CivicTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: CivicTheme.border, width: 2),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: CivicTheme.textPrimary,
                    ),
                  ),
                  Text(
                    sublabel,
                    style: const TextStyle(
                      fontSize: 13,
                      color: CivicTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 18, color: CivicTheme.primary),
          ],
        ),
      ),
    );
  }
}
