export type NavLink = { href: string; label: string };

// Labels advertise "Game and Practice" because parents were missing the
// Game/Practice toggle on the schedule pages and never finding practice times.
// The hrefs still land on the game schedule; the toggle covers the last hop.
const SCHEDULE_SUFFIX = " - Game and Practice";

export function buildScheduleLinks(freshmanHasBlue: boolean): NavLink[] {
  return [
    {
      href: "/schedule/games/varsity",
      label: `Varsity${SCHEDULE_SUFFIX}`,
    },
    { href: "/schedule/games/jv", label: `JV${SCHEDULE_SUFFIX}` },
    ...(freshmanHasBlue
      ? [
          {
            href: "/schedule/games/freshman/green",
            label: `Freshmen Green${SCHEDULE_SUFFIX}`,
          },
          {
            href: "/schedule/games/freshman/blue",
            label: `Freshmen Blue${SCHEDULE_SUFFIX}`,
          },
        ]
      : [
          {
            href: "/schedule/games/freshman/green",
            label: `Freshmen${SCHEDULE_SUFFIX}`,
          },
        ]),
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
  { href: "/boosters/donate", label: "Donate" },
];
