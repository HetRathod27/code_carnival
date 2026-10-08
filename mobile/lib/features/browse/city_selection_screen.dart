import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme.dart';

class CityItem {
  final String nameEn;
  final String nameGu;
  final String subtitle;
  final int activeCentres;
  final bool isAvailable;
  final IconData icon;

  const CityItem({
    required this.nameEn,
    required this.nameGu,
    required this.subtitle,
    required this.activeCentres,
    this.isAvailable = true,
    this.icon = Icons.location_city,
  });
}

class CitySelectionScreen extends StatefulWidget {
  final bool allowBack;

  const CitySelectionScreen({super.key, this.allowBack = true});

  @override
  State<CitySelectionScreen> createState() => _CitySelectionScreenState();
}

class _CitySelectionScreenState extends State<CitySelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _currentlySelectedCity;

  static const List<CityItem> _cities = [
    CityItem(
      nameEn: 'Gandhinagar',
      nameGu: 'ગાંધીનગર',
      subtitle: 'Capital Zone • Jan Seva & Ward Offices',
      activeCentres: 6,
      isAvailable: true,
      icon: Icons.account_balance,
    ),
    CityItem(
      nameEn: 'Ahmedabad',
      nameGu: 'અમદાવાદ',
      subtitle: 'AMC Mega City • West, Central & South Zones',
      activeCentres: 3,
      isAvailable: true,
      icon: Icons.location_city,
    ),
    CityItem(
      nameEn: 'Surat',
      nameGu: 'સુરત',
      subtitle: 'SMC Diamond & Textile Hub',
      activeCentres: 0,
      isAvailable: false,
      icon: Icons.business,
    ),
    CityItem(
      nameEn: 'Vadodara',
      nameGu: 'વડોદરા',
      subtitle: 'VMC Cultural Capital',
      activeCentres: 0,
      isAvailable: false,
      icon: Icons.museum_outlined,
    ),
    CityItem(
      nameEn: 'Rajkot',
      nameGu: 'રાજકોટ',
      subtitle: 'RMC Saurashtra Hub',
      activeCentres: 0,
      isAvailable: false,
      icon: Icons.domain,
    ),
    CityItem(
      nameEn: 'Bhavnagar',
      nameGu: 'ભાવનગર',
      subtitle: 'BMC Coastal Gateway',
      activeCentres: 0,
      isAvailable: false,
      icon: Icons.store_mall_directory_outlined,
    ),
    CityItem(
      nameEn: 'Jamnagar',
      nameGu: 'જામનગર',
      subtitle: 'JMC Brass City',
      activeCentres: 0,
      isAvailable: false,
      icon: Icons.location_city_outlined,
    ),
    CityItem(
      nameEn: 'Junagadh',
      nameGu: 'જૂનાગઢ',
      subtitle: 'JMC Historical Heritage',
      activeCentres: 0,
      isAvailable: false,
      icon: Icons.park_outlined,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentCity();
  }

  Future<void> _loadCurrentCity() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _currentlySelectedCity = prefs.getString('ql_selected_city');
      });
    }
  }

  Future<void> _selectCity(String cityName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ql_selected_city', cityName);

    if (mounted) {
      try {
        if (context.canPop() && widget.allowBack) {
          context.pop(true);
        } else {
          context.go('/offices');
        }
      } catch (_) {
        // Fallback for tests or standard Navigator
        if (widget.allowBack && Navigator.canPop(context)) {
          Navigator.pop(context, true);
        }
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredCities = _cities.where((c) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return c.nameEn.toLowerCase().contains(q) ||
          c.nameGu.toLowerCase().contains(q) ||
          c.subtitle.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: CivicTheme.canvas,
      appBar: AppBar(
        title: const Text('Select City / શહેર પસંદ કરો'),
        centerTitle: true,
        leading: widget.allowBack && context.canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              )
            : null,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: CivicTheme.primarySoft.withValues(alpha: 0.5),
                border: const Border(
                  bottom: BorderSide(color: CivicTheme.border, width: 1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: CivicTheme.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Where are you located?',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: CivicTheme.textPrimary,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'તમારું શહેર પસંદ કરો અને નજીકનું કેન્દ્ર જુઓ',
                              style: TextStyle(
                                fontSize: 13,
                                color: CivicTheme.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Search TextField
                  TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val.trim();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search city / શહેર શોધો (e.g. Gandhinagar)',
                      hintStyle: const TextStyle(fontSize: 14, color: CivicTheme.textSecondary),
                      prefixIcon: const Icon(Icons.search, color: CivicTheme.primary),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: CivicTheme.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: CivicTheme.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: CivicTheme.primary, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // City List
            Expanded(
              child: filteredCities.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.search_off, size: 48, color: CivicTheme.textSecondary),
                          const SizedBox(height: 12),
                          Text(
                            'No cities matching "$_searchQuery"',
                            style: const TextStyle(fontSize: 16, color: CivicTheme.textSecondary),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      itemCount: filteredCities.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final city = filteredCities[index];
                        final isCurrent = _currentlySelectedCity?.toLowerCase() == city.nameEn.toLowerCase();

                        return _buildCityCard(city, isCurrent);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCityCard(CityItem city, bool isCurrent) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: city.isAvailable
            ? () => _selectCity(city.nameEn)
            : () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${city.nameEn} services are coming soon! Please select Gandhinagar or Ahmedabad.',
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCurrent
                  ? CivicTheme.primary
                  : (city.isAvailable ? CivicTheme.border : Colors.grey.shade200),
              width: isCurrent ? 2 : 1.2,
            ),
            boxShadow: isCurrent
                ? [
                    BoxShadow(
                      color: CivicTheme.primary.withValues(alpha: 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : const [
                    BoxShadow(
                      color: Color(0x06000000),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            children: [
              // Icon Container
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: city.isAvailable
                      ? CivicTheme.primarySoft
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  city.icon,
                  color: city.isAvailable ? CivicTheme.primary : Colors.grey.shade400,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              // City Names and details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          city.nameEn,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: city.isAvailable ? CivicTheme.textPrimary : Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${city.nameGu})',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: city.isAvailable ? CivicTheme.primary : Colors.grey.shade500,
                          ),
                        ),
                        const Spacer(),
                        if (isCurrent)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: CivicTheme.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check, size: 12, color: Colors.white),
                                SizedBox(width: 4),
                                Text(
                                  'Selected',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else if (city.isAvailable)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green.shade300),
                            ),
                            child: Text(
                              '${city.activeCentres} Centres',
                              style: TextStyle(
                                color: Colors.green.shade800,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Coming Soon',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      city.subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: city.isAvailable ? CivicTheme.textSecondary : Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: city.isAvailable ? CivicTheme.primary : Colors.grey.shade300,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
