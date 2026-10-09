/**
 * Utility for mapping technical office IDs to citizen/staff facing civic names.
 * AGENTS.md / Spec: Never show internal IDs such as ward-central-01 on civic staff portals.
 */

const KNOWN_OFFICES: Record<string, string> = {
  'ward-central-01': 'Central Municipal Civic Centre (Sector 11)',
  'ward-east-02': 'East Zone Civic Centre',
  'ward-west-03': 'West Zone Civic Centre',
  'ward-south-04': 'South Municipal Ward Office',
  'ward-north-05': 'North Municipal Ward Office',
};

export function getHumanOfficeName(
  officeId?: string | null,
  rawName?: string | null,
): string {
  if (rawName && !rawName.toLowerCase().startsWith('ward-') && !rawName.includes('-01')) {
    return rawName;
  }
  if (officeId && KNOWN_OFFICES[officeId]) {
    return KNOWN_OFFICES[officeId];
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
    return `${titled} Municipal Civic Centre`;
  }
  return 'Central Municipal Civic Centre (Sector 11)';
}
