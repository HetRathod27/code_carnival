import 'package:flutter/material.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../api/client.dart';
import '../../core/theme.dart';

class OfficesScreen extends StatefulWidget {
  final ApiClient? client;

  const OfficesScreen({super.key, this.client});

  @override
  State<OfficesScreen> createState() => _OfficesScreenState();
}

class _OfficesScreenState extends State<OfficesScreen> {
  late final ApiClient _client = widget.client ?? ApiClient();
  List<OfficeModel> _offices = [];
  Map<String, List<ServiceModel>> _officeServices = {};
  TokenModel? _activeToken;
  String? _selectedCity;
  bool _loading = true;
  String? _error;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(_onFocusChange);
    _loadOffices();
  }

  void _onFocusChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _searchFocusNode.removeListener(_onFocusChange);
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<OfficeModel> _filterOfficesByCity(List<OfficeModel> offices, String? city) {
    if (city == null || city.isEmpty || city == 'All') {
      return offices;
    }
    return offices.where((o) {
      final text = '${o.name} ${o.address}'.toLowerCase();
      return text.contains(city.toLowerCase());
    }).toList();
  }

  List<OfficeModel> get _cityOffices => _filterOfficesByCity(_offices, _selectedCity);

  bool get _isSearchActive => _searchQuery.trim().isNotEmpty;

  List<OfficeModel> get _displayedOffices {
    final baseOffices = _cityOffices;
    final trimmedQuery = _searchQuery.trim().toLowerCase();
    if (trimmedQuery.isEmpty) {
      return baseOffices;
    }

    return baseOffices.where((office) {
      final services = _officeServices[office.id] ?? [];
      return services.any((s) => _serviceMatchesQuery(s, trimmedQuery));
    }).toList();
  }

  bool _serviceMatchesQuery(ServiceModel s, String query) {
    if (s.code.toLowerCase().contains(query)) return true;
    for (final val in s.names.values) {
      if (val != null && val.toString().toLowerCase().contains(query)) {
        return true;
      }
    }
    return false;
  }

  ServiceModel? _getMatchingServiceForOffice(String officeId, String query, String lang) {
    final trimmedQuery = query.trim().toLowerCase();
    if (trimmedQuery.isEmpty) return null;
    final services = _officeServices[officeId] ?? [];
    try {
      return services.firstWhere((s) => _serviceMatchesQuery(s, trimmedQuery));
    } catch (_) {
      return null;
    }
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
    });
  }

  Future<void> _loadOffices() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final list = await _client.fetchOffices();
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('ql_token');
      final city = prefs.getString('ql_selected_city');

      // Before selecting centres, user must select their city first
      if ((city == null || city.isEmpty) && widget.client == null) {
        if (mounted) {
          try {
            context.go('/select-city');
            return;
          } catch (_) {}
        }
      }

      TokenModel? active;
      if (token != null) {
        try {
          active = await _client.getActiveToken(token);
        } catch (_) {
          active = null;
        }
      }

      // If city changed or upon fresh load with different city, reset search appropriately
      if (city != _selectedCity) {
        _searchController.clear();
        _searchQuery = '';
      }

      if (mounted) {
        setState(() {
          _offices = list;
          _selectedCity = city;
          _activeToken = active;
          _loading = false;
        });
      }

      // Concurrently fetch services for offices in the selected city
      final cityOffices = _filterOfficesByCity(list, city);
      final serviceEntries = await Future.wait(
        cityOffices.map((office) async {
          try {
            final services = await _client.fetchServices(office.id);
            return MapEntry(office.id, services);
          } catch (_) {
            return MapEntry(office.id, <ServiceModel>[]);
          }
        }),
      );

      if (mounted) {
        setState(() {
          _officeServices = Map.fromEntries(serviceEntries);
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

  Widget _buildSearchField(BuildContext context, AppLocalizations l10n) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final double searchWidth = screenWidth > 700
        ? 240.0
        : screenWidth > 500
            ? 190.0
            : (screenWidth * 0.40).clamp(130.0, 170.0);

    const outlineBorder = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(20)),
      borderSide: BorderSide(color: CivicTheme.border, width: 1.2),
    );
    const focusedOutlineBorder = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(20)),
      borderSide: BorderSide(color: CivicTheme.primary, width: 1.8),
    );

    return SizedBox(
      width: searchWidth,
      height: 38,
      child: Semantics(
        label: l10n.searchServicesTooltip,
        textField: true,
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          textInputAction: TextInputAction.search,
          textAlignVertical: TextAlignVertical.center,
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
          style: const TextStyle(
            fontSize: 14,
            color: CivicTheme.textPrimary,
          ),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: CivicTheme.surface,
            border: outlineBorder,
            enabledBorder: outlineBorder,
            focusedBorder: focusedOutlineBorder,
            disabledBorder: outlineBorder,
            errorBorder: outlineBorder,
            focusedErrorBorder: focusedOutlineBorder,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
            hintText: l10n.searchServicesPlaceholder,
            hintStyle: const TextStyle(
              fontSize: 13,
              color: CivicTheme.textSecondary,
            ),
            prefixIcon: const Icon(
              Icons.search,
              size: 18,
              color: CivicTheme.textSecondary,
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 16, color: CivicTheme.textSecondary),
                    tooltip: l10n.clearSearchTooltip,
                    splashRadius: 16,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                    onPressed: _clearSearch,
                  )
                : null,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedCity != null && _selectedCity != 'All'
              ? '$_selectedCity Civic Centres'
              : l10n.officesTitle,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        titleSpacing: 8,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Select City / શહેર પસંદ કરો',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/select-city');
            }
          },
        ),
        actions: [
          if (_activeToken != null)
            IconButton(
              icon: const Icon(Icons.confirmation_number_outlined),
              tooltip: l10n.myToken,
              onPressed: () => context.push('/home'),
            ),
          // Search field in top bar area, positioned to the left of Account button
          Center(
            child: _buildSearchField(context, l10n),
          ),
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: l10n.visitHistoryTitle,
            onPressed: () => context.push('/history'),
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: 'My Account',
            onPressed: () async {
              await context.push('/account');
              _loadOffices();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.retryAction,
            onPressed: _loadOffices,
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 56, color: CivicTheme.error),
                          const SizedBox(height: 16),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 16, color: CivicTheme.textPrimary),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.refresh),
                            label: Text(l10n.retryAction),
                            onPressed: _loadOffices,
                          ),
                        ],
                      ),
                    ),
                  )
                : _cityOffices.isEmpty
                    ? Center(
                        child: Text(
                          l10n.noOfficesFound,
                          style: const TextStyle(fontSize: 18, color: CivicTheme.textSecondary),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadOffices,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(20),
                          itemCount: _displayedOffices.isEmpty ? 2 : _displayedOffices.length + 1,
                          separatorBuilder: (context, index) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (_activeToken != null) ...[
                                    InkWell(
                                      onTap: () => context.push('/home'),
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: CivicTheme.primary.withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: CivicTheme.primary, width: 1.5),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.confirmation_number, color: CivicTheme.primary, size: 28),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    l10n.activeAppointmentBanner,
                                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: CivicTheme.primary),
                                                  ),
                                                  Text(
                                                    l10n.tapToViewEta(_activeToken!.displayCode),
                                                    style: const TextStyle(fontSize: 13, color: CivicTheme.textSecondary),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const Icon(Icons.arrow_forward_ios, size: 16, color: CivicTheme.primary),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            _isSearchActive
                                                ? l10n.centresOfferService(_displayedOffices.length)
                                                : l10n.selectOfficePrompt,
                                            style: TextStyle(
                                              fontSize: _isSearchActive ? 16 : 18,
                                              fontWeight: FontWeight.w600,
                                              color: _isSearchActive ? CivicTheme.primary : CivicTheme.textSecondary,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: CivicTheme.primarySoft,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            '${_displayedOffices.length} Centres',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: CivicTheme.primary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }

                            if (_displayedOffices.isEmpty) {
                              if (_isSearchActive) {
                                return Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: CivicTheme.border),
                                  ),
                                  child: Column(
                                    children: [
                                      const Icon(Icons.search_off, size: 48, color: CivicTheme.textSecondary),
                                      const SizedBox(height: 12),
                                      Text(
                                        l10n.noCentresOfferService,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: CivicTheme.textPrimary,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Try searching for another service name, or clear the search to view all civic centres in ${_selectedCity ?? "this city"}.',
                                        style: const TextStyle(fontSize: 14, color: CivicTheme.textSecondary),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                );
                              }

                              return Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: CivicTheme.border),
                                ),
                                child: Column(
                                  children: [
                                    const Icon(Icons.location_off, size: 48, color: CivicTheme.textSecondary),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No civic centres found in ${_selectedCity ?? "this city"}.',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: CivicTheme.textPrimary,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Active centres are currently available in Gandhinagar and Ahmedabad.',
                                      style: TextStyle(fontSize: 14, color: CivicTheme.textSecondary),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.swap_horiz),
                                      label: const Text('Switch City / અન્ય શહેર પસંદ કરો'),
                                      onPressed: () async {
                                        await context.push('/select-city');
                                        _loadOffices();
                                      },
                                    ),
                                  ],
                                ),
                              );
                            }

                            final office = _displayedOffices[index - 1];
                            final matchingService = _isSearchActive
                                ? _getMatchingServiceForOffice(office.id, _searchQuery, currentLocale)
                                : null;
                            final matchingServiceName = matchingService?.localizedName(currentLocale);

                            return _OfficeCard(
                              office: office,
                              matchingServiceName: matchingServiceName,
                              onTap: () {
                                context.push('/offices/${office.id}/services');
                              },
                            );
                          },
                        ),
                      ),
      ),
    );
  }
}

class _OfficeCard extends StatelessWidget {
  final OfficeModel office;
  final String? matchingServiceName;
  final VoidCallback onTap;

  const _OfficeCard({
    required this.office,
    this.matchingServiceName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: CivicTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: CivicTheme.border, width: 2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A0E5A8A),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: CivicTheme.primarySoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.account_balance,
                    color: CivicTheme.primary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        office.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: CivicTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on_outlined, size: 18, color: CivicTheme.textSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              office.address,
                              style: const TextStyle(
                                fontSize: 15,
                                color: CivicTheme.textSecondary,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 18,
                  color: CivicTheme.primary,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: CivicTheme.border),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: CivicTheme.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${l10n.officeHoursLabel}: ${office.openTime} – ${office.closeTime}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: CivicTheme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (matchingServiceName != null && matchingServiceName!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: CivicTheme.primarySoft,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: CivicTheme.primary.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      size: 16,
                      color: CivicTheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.serviceAvailableNotice(matchingServiceName!),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: CivicTheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
