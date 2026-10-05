import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme.dart';
import '../../api/client.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiClient _client = ApiClient();
  TokenModel? _activeToken;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadActiveToken();
  }

  Future<void> _loadActiveToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('ql_token');
    if (token == null) {
      if (mounted) context.go('/auth');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final active = await _client.getActiveToken(token);
      if (mounted) {
        setState(() {
          _activeToken = active;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('ql_token');
    if (mounted) context.go('/auth');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QueueLess'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadActiveToken,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: CivicTheme.error),
                          const SizedBox(height: 12),
                          Text(_error!, textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadActiveToken,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : _activeToken != null
                      ? _buildActiveTokenCard(_activeToken!)
                      : _buildNoActiveTokenView(),
        ),
      ),
    );
  }

  Widget _buildActiveTokenCard(TokenModel token) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: CivicTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: CivicTheme.primary, width: 2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x110E5A8A),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                'YOUR ACTIVE TOKEN',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: CivicTheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                token.displayCode,
                style: const TextStyle(
                  fontSize: 54,
                  fontWeight: FontWeight.w900,
                  color: CivicTheme.textPrimary,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: CivicTheme.primarySoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  token.state,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: CivicTheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Divider(color: CivicTheme.border),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Citizens Ahead:'),
                  Text(
                    '${token.waitingAhead}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Estimated Turn:'),
                  Text(
                    token.lastEtaMinutes != null
                        ? '~${token.lastEtaMinutes!.round()} min'
                        : 'Calculating…',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNoActiveTokenView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.confirmation_number_outlined, size: 72, color: CivicTheme.border),
          const SizedBox(height: 16),
          const Text(
            'No Active Appointment',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'Book an appointment at your local civic centre to avoid waiting in queues.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: CivicTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}
