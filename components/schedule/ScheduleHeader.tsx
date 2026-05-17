import { ExternalLink } from "lucide-react";

import { getSiteSettingsCore } from "@/lib/site-settings";

type ScheduleType = "games" | "practice";
type Level = "varsity" | "jv" | "freshman";
type Designation = "green" | "blue";

const LEVEL_LABELS: Record<Level, string> = {
  varsity: "Varsity",
  jv: "JV",
  freshman: "Freshman",
};

const DESIGNATION_LABELS: Record<Designation, string> = {
  green: "Green",
  blue: "Blue",
};

export async function ScheduleHeader({
  type,
  level,
  designation,
}: {
  type: ScheduleType;
  level: Level;
  designation?: Designation;
}) {
  const { current_year, maxpreps_team_url } = await getSiteSettingsCore();

  const levelPart = designation
    ? `${LEVEL_LABELS[level]} ${DESIGNATION_LABELS[designation]}`
    : LEVEL_LABELS[level];
  const typePart = type === "games" ? "Schedule" : "Practice";
  const title = `${current_year} ${levelPart} ${typePart}`;

  return (
    <header className="mb-6">
      <h1 className="text-2xl font-bold tracking-tight sm:text-3xl">{title}</h1>
      {type === "games" && maxpreps_team_url ? (
        <p className="mt-2 text-sm">
          <a
            href={maxpreps_team_url}
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex items-center gap-1 text-mavs-green hover:underline"
          >
            Live scores and stats
            <ExternalLink size={14} aria-hidden="true" />
          </a>
        </p>
      ) : null}
    </header>
  );
}
