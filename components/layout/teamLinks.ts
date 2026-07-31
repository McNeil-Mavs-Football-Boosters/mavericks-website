export type NavLink = { href: string; label: string };

// Parents were missing the Game/Practice toggle on the schedule pages and never
// finding practice times, so practice gets its own nav rows rather than relying
// on the toggle. Game and practice rows are interleaved per team so a parent
// sees both of their links together.
//
// Practice has no Green/Blue split: the route is /schedule/practice/[level]
// only (/schedule/practice/freshman/green 404s via the catchall) and the page
// titles itself "Freshmen Green & Blue Practice Schedule". So there is ONE
// freshmen practice row — two rows to an identical URL would just confuse.
export function buildScheduleLinks(freshmanHasBlue: boolean): NavLink[] {
  return [
    { href: "/schedule/games/varsity", label: "Varsity - Game" },
    { href: "/schedule/practice/varsity", label: "Varsity - Practice" },
    { href: "/schedule/games/jv", label: "JV - Game" },
    { href: "/schedule/practice/jv", label: "JV - Practice" },
    ...(freshmanHasBlue
      ? [
          {
            href: "/schedule/games/freshman/green",
            label: "Freshmen Green - Game",
          },
          {
            href: "/schedule/games/freshman/blue",
            label: "Freshmen Blue - Game",
          },
        ]
      : [{ href: "/schedule/games/freshman/green", label: "Freshmen - Game" }]),
    { href: "/schedule/practice/freshman", label: "Freshmen - Practice" },
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
