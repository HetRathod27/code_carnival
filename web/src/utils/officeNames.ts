/**
 * Utility for mapping technical office IDs to citizen/staff facing civic names.
 * AGENTS.md / Spec: Never show internal IDs such as ward-central-01 on civic staff portals.
 * Fully localized across English (en), Gujarati (gu), and Hindi (hi).
 */

const KNOWN_OFFICES: Record<string, Record<string, string>> = {
  'ward-central-01': {
    en: 'Central Municipal Civic Centre (Sector 11)',
    gu: 'સેન્ટ્રલ મ્યુનિસિપલ સિવિક સેન્ટર (સેક્ટર 11)',
    hi: 'केंद्रीय नगर नागरिक केंद्र (सेक्टर 11)',
  },
  'ward-east-02': {
    en: 'East Zone Civic Centre',
    gu: 'પૂર્વ ઝોન સિવિક સેન્ટર',
    hi: 'पूर्व जोन नागरिक केंद्र',
  },
  'ward-west-03': {
    en: 'West Zone Civic Centre',
    gu: 'પશ્ચિમ ઝોન સિવિક સેન્ટર',
    hi: 'पश्चिम जोन नागरिक केंद्र',
  },
  'ward-south-04': {
    en: 'South Municipal Ward Office',
    gu: 'દક્ષિણ મ્યુનિસિપલ વોર્ડ કચેરી',
    hi: 'दक्षिण नगर वार्ड कार्यालय',
  },
  'ward-north-05': {
    en: 'North Municipal Ward Office',
    gu: 'ઉત્તર મ્યુનિસિપલ વોર્ડ કચેરી',
    hi: 'उत्तर नगर वार्ड कार्यालय',
  },
};

export function getHumanOfficeName(
  officeId?: string | null,
  rawName?: string | null,
  lang: string = 'en',
): string {
  const normalizedLang = lang.startsWith('gu') ? 'gu' : lang.startsWith('hi') ? 'hi' : 'en';

  if (rawName && !rawName.toLowerCase().startsWith('ward-') && !rawName.includes('-01')) {
    return rawName;
  }
  if (officeId && KNOWN_OFFICES[officeId]) {
    return KNOWN_OFFICES[officeId][normalizedLang] || KNOWN_OFFICES[officeId].en;
  }
  if (officeId) {
    const formatted = officeId
      .replace(/^ward-/, '')
      .replace(/-\d+$/, '')
      .replace(/-/g, ' ');
    const titled = formatted
      .split(' ')
      .map((w) => w.charAt(0).toUpperCase() + w.slice(1))
      .join(' ');

    if (normalizedLang === 'gu') {
      return `${titled} મ્યુનિસિપલ સિવિક સેન્ટર`;
    }
    if (normalizedLang === 'hi') {
      return `${titled} नगर नागरिक केंद्र`;
    }
    return `${titled} Municipal Civic Centre`;
  }

  if (normalizedLang === 'gu') {
    return 'સેન્ટ્રલ મ્યુનિસિપલ સિવિક સેન્ટર (સેક્ટર 11)';
  }
  if (normalizedLang === 'hi') {
    return 'केंद्रीय नगर नागरिक केंद्र (सेक्टर 11)';
  }
  return 'Central Municipal Civic Centre (Sector 11)';
}
