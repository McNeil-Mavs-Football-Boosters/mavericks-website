export type NavLink = { href: string; label: string };

export function buildScheduleLinks(freshmanHasBlue: boolean): NavLink[] {
  return [
    { href: "/schedule/games/varsity", label: "Varsity" },
    { href: "/schedule/games/jv", label: "JV" },
    ...(freshmanHasBlue
      ? [
          { href: "/schedule/games/freshman/green", label: "Freshmen Green" },
          { href: "/schedule/games/freshman/blue", label: "Freshmen Blue" },
        ]
      : [{ href: "/schedule/games/freshman/green", label: "Freshmen" }]),
  ];
}

export function buildRosterLinks(freshmanHasBlue: boolean): NavLink[] {
  return [
    { href: "/roster/varsity", label: "Varsity" },
    { href: "/roster/jv", label: "JV" },
    ...(freshmanHasBlue
      ? [
          { href: "/roster/freshman/green", label: "Freshmen Green" },
          { href: "/roster/freshman/blue", label: "Freshmen Blue" },
        ]
      : [{ href: "/roster/freshman/green", label: "Freshmen" }]),
  ];
}

export const BOOSTER_LINKS: NavLink[] = [
  { href: "/boosters", label: "About the Booster Club" },
  { href: "/boosters/join", label: "Join the Club!" },
  { href: "/boosters/members", label: "Members" },
  { href: "/boosters/sponsor", label: "Sponsorship Opportunities" },
  { href: "/boosters/volunteer", label: "Volunteer" },
  { href: "/boosters/committees", label: "Committees" },
  { href: "/boosters/events", label: "Calendar / Events" },
  { href: "/boosters/documents", label: "Documents" },
  { href: "/boosters/donate", label: "Donate" },
];
