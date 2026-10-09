/**
 * Central navigation configuration for all staff roles in QueueLess.
 * Follows AGENTS.md / UI architecture rules: navigation driven from one config list.
 */

export type StaffRole = 'OFFICER' | 'DESK' | 'ADMIN' | 'SUPER_ADMIN';

export type NavTabId =
  | 'queue'           // Officer: My queue
  | 'activity'        // Officer: Today's activity
  | 'desk'            // Desk: New token
  | 'desk_queue'      // Desk: Queue
  | 'admin'           // Admin: Overview
  | 'admin_counters'  // Admin: Counters & services
  | 'admin_settings'  // Admin: Settings
  | 'reports'         // Admin: Reports
  | 'sim'             // Admin: Simulation
  | 'display'         // All: Lobby display (opens in new tab)
  | 'account';        // All: My account

export interface NavItemConfig {
  id: NavTabId;
  labelKey: string;
  defaultLabel: string;
  icon: string;
  isExternalTab?: boolean;
}

export interface NavSectionConfig {
  sectionKey: string;
  defaultTitle: string;
  items: NavItemConfig[];
}

export const ROLE_NAVIGATION: Record<StaffRole, NavSectionConfig[]> = {
  OFFICER: [
    {
      sectionKey: 'nav.section_workspace',
      defaultTitle: 'Workspace',
      items: [
        {
          id: 'queue',
          labelKey: 'nav.my_queue',
          defaultLabel: 'My queue',
          icon: 'queue',
        },
      ],
    },
    {
      sectionKey: 'nav.section_activity',
      defaultTitle: 'Activity',
      items: [
        {
          id: 'activity',
          labelKey: 'nav.today_activity',
          defaultLabel: "Today's activity",
          icon: 'history',
        },
      ],
    },
    {
      sectionKey: 'nav.section_tools',
      defaultTitle: 'Tools',
      items: [
        {
          id: 'display',
          labelKey: 'nav.lobby_display',
          defaultLabel: 'Lobby display',
          icon: 'tv',
          isExternalTab: true,
        },
      ],
    },
    {
      sectionKey: 'nav.section_account',
      defaultTitle: 'Account',
      items: [
        {
          id: 'account',
          labelKey: 'nav.my_account',
          defaultLabel: 'My account',
          icon: 'account_circle',
        },
      ],
    },
  ],
  DESK: [
    {
      sectionKey: 'nav.section_workspace',
      defaultTitle: 'Workspace',
      items: [
        {
          id: 'desk',
          labelKey: 'nav.new_token',
          defaultLabel: 'New token',
          icon: 'receipt_long',
        },
        {
          id: 'desk_queue',
          labelKey: 'nav.queue',
          defaultLabel: 'Queue',
          icon: 'format_list_bulleted',
        },
      ],
    },
    {
      sectionKey: 'nav.section_tools',
      defaultTitle: 'Tools',
      items: [
        {
          id: 'display',
          labelKey: 'nav.lobby_display',
          defaultLabel: 'Lobby display',
          icon: 'tv',
          isExternalTab: true,
        },
      ],
    },
    {
      sectionKey: 'nav.section_account',
      defaultTitle: 'Account',
      items: [
        {
          id: 'account',
          labelKey: 'nav.my_account',
          defaultLabel: 'My account',
          icon: 'account_circle',
        },
      ],
    },
  ],
  ADMIN: [
    {
      sectionKey: 'nav.section_workspace',
      defaultTitle: 'Workspace',
      items: [
        {
          id: 'admin',
          labelKey: 'nav.overview',
          defaultLabel: 'Overview',
          icon: 'dashboard',
        },
        {
          id: 'admin_counters',
          labelKey: 'nav.counters_services',
          defaultLabel: 'Counters and services',
          icon: 'meeting_room',
        },
        {
          id: 'admin_settings',
          labelKey: 'nav.settings',
          defaultLabel: 'Settings',
          icon: 'settings',
        },
      ],
    },
    {
      sectionKey: 'nav.section_analysis',
      defaultTitle: 'Analysis & Proof',
      items: [
        {
          id: 'reports',
          labelKey: 'nav.reports',
          defaultLabel: 'Reports',
          icon: 'bar_chart',
        },
        {
          id: 'sim',
          labelKey: 'nav.simulation_demo',
          defaultLabel: 'Simulation (demo only)',
          icon: 'science',
        },
      ],
    },
    {
      sectionKey: 'nav.section_tools',
      defaultTitle: 'Tools',
      items: [
        {
          id: 'display',
          labelKey: 'nav.lobby_display',
          defaultLabel: 'Lobby display',
          icon: 'tv',
          isExternalTab: true,
        },
      ],
    },
    {
      sectionKey: 'nav.section_account',
      defaultTitle: 'Account',
      items: [
        {
          id: 'account',
          labelKey: 'nav.my_account',
          defaultLabel: 'My account',
          icon: 'account_circle',
        },
      ],
    },
  ],
  SUPER_ADMIN: [
    {
      sectionKey: 'nav.section_workspace',
      defaultTitle: 'Workspace',
      items: [
        {
          id: 'admin',
          labelKey: 'nav.overview',
          defaultLabel: 'Overview',
          icon: 'dashboard',
        },
        {
          id: 'admin_counters',
          labelKey: 'nav.counters_services',
          defaultLabel: 'Counters and services',
          icon: 'meeting_room',
        },
        {
          id: 'admin_settings',
          labelKey: 'nav.settings',
          defaultLabel: 'Settings',
          icon: 'settings',
        },
      ],
    },
    {
      sectionKey: 'nav.section_analysis',
      defaultTitle: 'Analysis & Proof',
      items: [
        {
          id: 'reports',
          labelKey: 'nav.reports',
          defaultLabel: 'Reports',
          icon: 'bar_chart',
        },
        {
          id: 'sim',
          labelKey: 'nav.simulation_demo',
          defaultLabel: 'Simulation (demo only)',
          icon: 'science',
        },
      ],
    },
    {
      sectionKey: 'nav.section_tools',
      defaultTitle: 'Tools',
      items: [
        {
          id: 'display',
          labelKey: 'nav.lobby_display',
          defaultLabel: 'Lobby display',
          icon: 'tv',
          isExternalTab: true,
        },
      ],
    },
    {
      sectionKey: 'nav.section_account',
      defaultTitle: 'Account',
      items: [
        {
          id: 'account',
          labelKey: 'nav.my_account',
          defaultLabel: 'My account',
          icon: 'account_circle',
        },
      ],
    },
  ],
};

export function getNavigationForRole(role?: string | null): NavSectionConfig[] {
  const normRole = (role || 'OFFICER').toUpperCase() as StaffRole;
  return ROLE_NAVIGATION[normRole] || ROLE_NAVIGATION.OFFICER;
}
