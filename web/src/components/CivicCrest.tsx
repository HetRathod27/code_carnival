/**
 * Neutral Civic Crest Placeholder Component.
 * Neutral civic symbolism (civic pillars, shield of trust, civic stars).
 * AGENTS.md / Spec: Do not use the national emblem or any official government logo.
 * Designed to be easily swappable with custom municipal crests.
 */

interface CivicCrestProps {
  size?: number;
  className?: string;
}

export function CivicCrest({ size = 38, className = '' }: CivicCrestProps) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 48 48"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      className={className}
      aria-hidden="true"
      style={{ flexShrink: 0 }}
    >
      {/* Outer Civic Shield */}
      <path
        d="M24 4L40 10V22C40 33.2 33.2 41.5 24 44C14.8 41.5 8 33.2 8 22V10L24 4Z"
        fill="var(--color-primary-soft, #e3f0f8)"
        stroke="var(--color-primary, #0e5a8a)"
        strokeWidth="2.5"
        strokeLinejoin="round"
      />
      {/* Inner Decorative Band */}
      <path
        d="M24 9L36 13.5V21C36 29.8 30.9 36.3 24 38.8C17.1 36.3 12 29.8 12 21V13.5L24 9Z"
        stroke="var(--color-primary, #0e5a8a)"
        strokeWidth="1.2"
        strokeDasharray="2 2"
        opacity="0.6"
      />
      {/* Civic Columns Motif */}
      <rect x="18" y="20" width="3" height="11" rx="1" fill="var(--color-primary, #0e5a8a)" />
      <rect x="22.5" y="18" width="3" height="13" rx="1" fill="var(--color-primary, #0e5a8a)" />
      <rect x="27" y="20" width="3" height="11" rx="1" fill="var(--color-primary, #0e5a8a)" />
      {/* Arch Capital */}
      <path
        d="M16 18C16 16.5 19.5 15 24 15C28.5 15 32 16.5 32 18H16Z"
        fill="var(--color-primary, #0e5a8a)"
      />
      {/* Base Plinth */}
      <rect x="16" y="32" width="16" height="2.5" rx="0.5" fill="var(--color-primary, #0e5a8a)" />
      {/* Civic Star of Governance */}
      <circle cx="24" cy="12.5" r="1.5" fill="#f4a21f" />
    </svg>
  );
}
