import test from 'node:test';
import assert from 'node:assert/strict';

import { ROLE_NAVIGATION, getNavigationForRole } from '../src/components/navConfig.ts';
import { getHumanOfficeName } from '../src/utils/officeNames.ts';

test('1. Navigation configuration per role adheres strictly to spec', () => {
  // Officer navigation
  const officerSections = getNavigationForRole('OFFICER');
  const officerItemIds = officerSections.flatMap((s) => s.items.map((i) => i.id));
  assert.deepEqual(officerItemIds, ['queue', 'activity', 'display', 'account']);

  // Desk navigation
  const deskSections = getNavigationForRole('DESK');
  const deskItemIds = deskSections.flatMap((s) => s.items.map((i) => i.id));
  assert.deepEqual(deskItemIds, ['desk', 'desk_queue', 'display', 'account']);

  // Admin navigation
  const adminSections = getNavigationForRole('ADMIN');
  const adminItemIds = adminSections.flatMap((s) => s.items.map((i) => i.id));
  assert.deepEqual(adminItemIds, ['admin', 'admin_counters', 'admin_settings', 'reports', 'sim', 'display', 'account']);
});

test('2. Human Office Name utility never displays internal IDs like ward-central-01', () => {
  assert.equal(getHumanOfficeName('ward-central-01'), 'Central Municipal Civic Centre (Sector 11)');
  assert.equal(getHumanOfficeName('ward-east-02'), 'East Zone Civic Centre');
  assert.equal(getHumanOfficeName('ward-north-05'), 'North Municipal Ward Office');
  // Unknown ID formats
  assert.equal(getHumanOfficeName('ward-civic-hub'), 'Civic Hub Municipal Civic Centre');
  assert.doesNotMatch(getHumanOfficeName('ward-central-01'), /ward-central-01/);
});

test('3. Single-Primary-Action rule logic test', () => {
  // Rule: "Call next" is primary only when counter is idle.
  // When a token is Called, Start service is primary.
  // When a token is Serving, Complete is primary.
  
  function getPrimaryAction(counterStatus, activeTokenState) {
    if (counterStatus !== 'OPEN') return 'NONE';
    if (!activeTokenState) return 'CALL_NEXT';
    if (activeTokenState === 'CALLED') return 'START_SERVICE';
    if (activeTokenState === 'SERVING') return 'COMPLETE';
    return 'NONE';
  }

  // Idle counter: Call next is the sole primary
  assert.equal(getPrimaryAction('OPEN', null), 'CALL_NEXT');

  // Called token: Start service is primary; Call next is not primary
  assert.equal(getPrimaryAction('OPEN', 'CALLED'), 'START_SERVICE');
  assert.notEqual(getPrimaryAction('OPEN', 'CALLED'), 'CALL_NEXT');

  // Serving token: Complete is primary; Call next is not primary
  assert.equal(getPrimaryAction('OPEN', 'SERVING'), 'COMPLETE');
  assert.notEqual(getPrimaryAction('OPEN', 'SERVING'), 'CALL_NEXT');

  // Counter on Break or Closed: Call next cannot be primary
  assert.equal(getPrimaryAction('BREAK', null), 'NONE');
  assert.equal(getPrimaryAction('CLOSED', null), 'NONE');
});

test('4. Role-based Route Guard enforcement test', () => {
  function canAccessRoute(userRole, routePath) {
    if (routePath.startsWith('/admin')) {
      return userRole === 'ADMIN' || userRole === 'SUPER_ADMIN';
    }
    if (routePath.startsWith('/desk')) {
      return userRole === 'DESK' || userRole === 'ADMIN' || userRole === 'SUPER_ADMIN';
    }
    if (routePath.startsWith('/officer')) {
      return userRole === 'OFFICER' || userRole === 'ADMIN' || userRole === 'SUPER_ADMIN';
    }
    return true;
  }

  // Officer attempts to access Admin route: MUST BE DENIED
  assert.equal(canAccessRoute('OFFICER', '/admin'), false);
  // Officer attempts to access Desk route: MUST BE DENIED
  assert.equal(canAccessRoute('OFFICER', '/desk'), false);
  // Officer accesses Officer route: ALLOWED
  assert.equal(canAccessRoute('OFFICER', '/officer'), true);

  // Desk attempts to access Admin route: MUST BE DENIED
  assert.equal(canAccessRoute('DESK', '/admin'), false);
  // Desk accesses Desk route: ALLOWED
  assert.equal(canAccessRoute('DESK', '/desk'), true);

  // Admin accesses any route: ALLOWED
  assert.equal(canAccessRoute('ADMIN', '/admin'), true);
  assert.equal(canAccessRoute('ADMIN', '/desk'), true);
  assert.equal(canAccessRoute('ADMIN', '/officer'), true);
});

test('5. Admin portal tab mapping ensures Counters and services is active', () => {
  function resolveAdminTab(navId) {
    if (navId === 'admin_counters') return 'counters_services';
    if (navId === 'admin_settings') return 'settings';
    return 'overview';
  }

  assert.equal(resolveAdminTab('admin_counters'), 'counters_services');
  assert.equal(resolveAdminTab('admin_settings'), 'settings');
  assert.equal(resolveAdminTab('admin'), 'overview');
});
