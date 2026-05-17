"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";

type ScheduleType = "games" | "practice";
type Level = "varsity" | "jv" | "freshman";
type Designation = "green" | "blue";

type ParsedRoute = {
  type: ScheduleType;
  level: Level;
  designation: Designation | null;
};

function parseRoute(pathname: string): ParsedRoute {
  const parts = pathname.replace(/\/$/, "").split("/").filter(Boolean);
  // parts ~ ["schedule", "games" | "practice", "varsity" | "jv" | "freshman", "green" | "blue"?]

  let type: ScheduleType = "games";
  let level: Level = "varsity";
  let designation: Designation | null = null;

  if (parts[1] === "practice") type = "practice";

  if (parts[2] === "jv") level = "jv";
  else if (parts[2] === "freshman") level = "freshman";

  if (level === "freshman" && parts[3] === "blue") designation = "blue";
  else if (level === "freshman" && parts[3] === "green") designation = "green";

  return { type, level, designation };
}

function gamesUrl(level: Level, designation: Designation | null): string {
  if (level === "freshman") {
    return `/schedule/games/freshman/${designation ?? "green"}`;
  }
  return `/schedule/games/${level}`;
}

function practiceUrl(level: Level): string {
  return `/schedule/practice/${level}`;
}

const TAB_BASE =
  "inline-flex items-center px-3 py-1.5 text-sm rounded-md transition-colors";
const TAB_ACTIVE = "bg-mavs-green text-white font-semibold";
const TAB_INACTIVE = "text-foreground hover:bg-muted";

function Tab({
  href,
  active,
  label,
}: {
  href: string;
  active: boolean;
  label: string;
}) {
  return (
    <li>
      <Link
        href={href}
        aria-current={active ? "page" : undefined}
        className={`${TAB_BASE} ${active ? TAB_ACTIVE : TAB_INACTIVE}`}
      >
        {label}
      </Link>
    </li>
  );
}

export function ScheduleNav({
  freshmanHasBlue,
}: {
  freshmanHasBlue: boolean;
}) {
  const pathname = usePathname();
  const current = parseRoute(pathname);

  const typeHrefs: Record<ScheduleType, string> = {
    games: gamesUrl(
      current.level,
      current.level === "freshman" ? current.designation : null,
    ),
    practice: practiceUrl(current.level),
  };

  const levelHrefs: Record<Level, string> = {
    varsity:
      current.type === "games" ? gamesUrl("varsity", null) : practiceUrl("varsity"),
    jv: current.type === "games" ? gamesUrl("jv", null) : practiceUrl("jv"),
    freshman:
      current.type === "games"
        ? gamesUrl(
            "freshman",
            current.level === "freshman" ? current.designation : null,
          )
        : practiceUrl("freshman"),
  };

  const showDesignation =
    current.type === "games" &&
    current.level === "freshman" &&
    freshmanHasBlue;

  return (
    <nav
      aria-label="Schedule navigation"
      className="sticky top-16 z-30 w-full bg-white border-b border-border"
    >
      <div className="mx-auto max-w-6xl px-4 sm:px-6 lg:px-8">
        <ul
          aria-label="Type"
          className="flex gap-1 border-b border-border/40 py-2 list-none p-0"
        >
          <Tab
            href={typeHrefs.games}
            active={current.type === "games"}
            label="Games"
          />
          <Tab
            href={typeHrefs.practice}
            active={current.type === "practice"}
            label="Practice"
          />
        </ul>
        <ul
          aria-label="Level"
          className={`flex gap-1 py-2 list-none p-0 ${
            showDesignation ? "border-b border-border/40" : ""
          }`}
        >
          <Tab
            href={levelHrefs.varsity}
            active={current.level === "varsity"}
            label="Varsity"
          />
          <Tab
            href={levelHrefs.jv}
            active={current.level === "jv"}
            label="JV"
          />
          <Tab
            href={levelHrefs.freshman}
            active={current.level === "freshman"}
            label="Freshman"
          />
        </ul>
        {showDesignation ? (
          <ul
            aria-label="Designation"
            className="flex gap-1 py-2 list-none p-0"
          >
            <Tab
              href="/schedule/games/freshman/green"
              active={current.designation === "green"}
              label="Green"
            />
            <Tab
              href="/schedule/games/freshman/blue"
              active={current.designation === "blue"}
              label="Blue"
            />
          </ul>
        ) : null}
      </div>
    </nav>
  );
}
