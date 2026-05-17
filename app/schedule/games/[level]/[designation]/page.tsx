import { notFound } from "next/navigation";
import { ExternalLink } from "lucide-react";

import { GameCard } from "@/components/schedule/game-card";
import { GamesTable } from "@/components/schedule/games-table";
import { getGamesForTeam } from "@/lib/queries/games";
import { getSiteSettingsCore } from "@/lib/site-settings";

const DESIGNATION_TITLES: Record<string, string> = {
  green: "Green",
  blue: "Blue",
};

export default async function FreshmanGameSchedulePage({
  params,
}: {
  params: Promise<{ level: string; designation: string }>;
}) {
  const { level, designation } = await params;
  if (level !== "freshman") notFound();

  const designationTitle = DESIGNATION_TITLES[designation];
  if (!designationTitle) notFound();

  const { current_year, maxpreps_team_url, freshman_has_blue } =
    await getSiteSettingsCore();

  if (designation === "blue" && !freshman_has_blue) notFound();

  const showDesignation = freshman_has_blue;
  const teamLabel = showDesignation
    ? `Freshman ${designationTitle}`
    : "Freshman";

  const games = await getGamesForTeam({
    year: current_year,
    level: "freshman",
    designation: designationTitle,
  });

  return (
    <section>
      <header className="mb-6">
        <h1 className="text-3xl font-bold tracking-tight sm:text-4xl">
          {current_year} {teamLabel} Game Schedule
        </h1>
        {maxpreps_team_url ? (
          <p className="mt-2 text-sm">
            <a
              href={maxpreps_team_url}
              target="_blank"
              rel="noopener noreferrer"
              className="text-mavs-green hover:underline"
            >
              Live scores and stats →
            </a>
          </p>
        ) : null}
      </header>

      {games.length > 0 ? (
        <>
          <GamesTable games={games} />
          <div className="space-y-3 md:hidden">
            {games.map((game) => (
              <GameCard key={game.id} game={game} />
            ))}
          </div>
        </>
      ) : (
        <div className="rounded-lg border border-border bg-white p-8 text-center">
          <p className="text-foreground">
            {teamLabel} game schedule coming soon. Check MaxPreps for current
            details.
          </p>
          {maxpreps_team_url ? (
            <div className="mt-6">
              <a
                href={maxpreps_team_url}
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center gap-2 rounded-md bg-mavs-green px-4 py-2 text-sm font-medium text-white hover:bg-mavs-green-dark"
              >
                MaxPreps
                <ExternalLink className="h-4 w-4" />
              </a>
            </div>
          ) : null}
        </div>
      )}
    </section>
  );
}
