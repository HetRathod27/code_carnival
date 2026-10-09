/// Human-readable Civic Office name resolution for Citizen App.
/// AGENTS.md / Spec: Never expose technical/internal IDs such as ward-central-01 to citizens.
/// Supports English, Gujarati, and Hindi.
library;

class OfficeNames {
  static const Map<String, Map<String, String>> _knownOffices = {
    'ward-central-01': {
      'en': 'Central Municipal Civic Centre (Sector 11)',
      'gu': 'સેન્ટ્રલ મ્યુનિસિપલ સિવિક સેન્ટર (સેક્ટર 11)',
      'hi': 'केंद्रीय नगर नागरिक केंद्र (सेक्टर 11)',
    },
    'ward-east-02': {
      'en': 'East Zone Civic Centre',
      'gu': 'પૂર્વ ઝોન સિવિક સેન્ટર',
      'hi': 'पूर्व जोन नागरिक केंद्र',
    },
    'ward-west-03': {
      'en': 'West Zone Civic Centre',
      'gu': 'પશ્ચિમ ઝોન સિવિક સેન્ટર',
      'hi': 'पश्चिम जोन नागरिक केंद्र',
    },
    'ward-south-04': {
      'en': 'South Municipal Ward Office',
      'gu': 'દક્ષિણ મ્યુનિસિપલ વોર્ડ કચેરી',
      'hi': 'दक्षिण नगर वार्ड कार्यालय',
    },
    'ward-north-05': {
      'en': 'North Municipal Ward Office',
      'gu': 'ઉત્તર મ્યુનિસિપલ વોર્ડ કચેરી',
      'hi': 'उत्तर नगर वार्ड कार्यालय',
    },
  };

  static String getHumanOfficeName(
    String? officeId, {
    String? rawName,
    String lang = 'en',
  }) {
    final normalizedLang = lang.startsWith('gu')
        ? 'gu'
        : (lang.startsWith('hi') ? 'hi' : 'en');

    if (rawName != null &&
        rawName.trim().isNotEmpty &&
        !rawName.toLowerCase().startsWith('ward-') &&
        !rawName.contains('-01')) {
      return rawName;
    }

    if (officeId != null && _knownOffices.containsKey(officeId)) {
      return _knownOffices[officeId]![normalizedLang] ??
          _knownOffices[officeId]!['en']!;
    }

    if (officeId != null && officeId.isNotEmpty) {
      final formatted = officeId
          .replaceAll(RegExp(r'^ward-'), '')
          .replaceAll(RegExp(r'-\d+$'), '')
          .replaceAll('-', ' ');
      final titled = formatted
          .split(' ')
          .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
          .join(' ');

      if (normalizedLang == 'gu') {
        return '$titled મ્યુનિસિપલ સિવિક સેન્ટર';
      }
      if (normalizedLang == 'hi') {
        return '$titled नगर नागरिक केंद्र';
      }
      return '$titled Municipal Civic Centre';
    }

    if (normalizedLang == 'gu') {
      return 'મ્યુનિસિપલ સિવિક સેન્ટર';
    }
    if (normalizedLang == 'hi') {
      return 'नगर नागरिक केंद्र';
    }
    return 'Municipal Civic Centre';
  }
}
