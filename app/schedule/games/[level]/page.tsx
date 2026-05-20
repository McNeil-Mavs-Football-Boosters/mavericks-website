import { notFound } from "next/navigation";
import { ExternalLink } from "lucide-react";

import { GameCard } from "@/components/schedule/game-card";
import { GamesTable } from "@/components/schedule/games-table";
import { PrintViewLink } from "@/components/shared/PrintViewLink";
import { getGamesForTeam } from "@/lib/queries/games";
import { getRosterForTeam } from "@/lib/queries/rosters";
import { getSiteSettingsCore } from "@/lib/site-settings";

const LEVEL_TITLES: Record<string, string> = {
  varsity: "Varsity",
  jv: "JV",
};

export default async function GameSchedulePage({
  params,
}: {
  params: Promise<{ level: string }>;
}) {
  const { level } = await params;
  const levelTitle = LEVEL_TITLES[level];
  if (!levelTitle) notFound();

  const { current_year, maxpreps_team_url } = await getSiteSettingsCore();

  const [games, roster] = await Promise.all([
    getGamesForTeam({
      year: current_year,
      level: level as "varsity" | "jv",
      designation: null,
    }),
    getRosterForTeam({
      year: current_year,
      level: level as "varsity" | "jv",
      designation: null,
    }),
  ]);

  return (
    <section>
      <header className="mb-6 flex items-start justify-between gap-4">
        <div>
          <h1 className="text-3xl font-black uppercase tracking-tight sm:text-4xl">
            {current_year} {levelTitle} Game Schedule
          </h1>
          {maxpreps_team_url ? (
            <p className="mt-2 text-sm print:hidden">
              <a
                href={maxpreps_team_url}
                target="_blank"
                rel="noopener noreferrer"
                className="text-mavs-navy hover:underline"
              >
                Live scores and stats →
              </a>
            </p>
          ) : null}
        </div>
        <PrintViewLink
          storagePath={roster?.schedule_pdf_storage_path ?? null}
        />
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
            {levelTitle} game schedule coming soon. Check MaxPreps for current
            details.
          </p>
          {maxpreps_team_url ? (
            <div className="mt-6 print:hidden">
              <a
                href={maxpreps_team_url}
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center gap-2 rounded-md bg-mavs-navy px-4 py-2 text-sm font-medium text-white hover:bg-mavs-navy-dark"
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
