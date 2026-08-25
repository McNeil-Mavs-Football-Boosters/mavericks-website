import { notFound } from "next/navigation";
import { ExternalLink } from "lucide-react";

import { GameCard } from "@/components/schedule/game-card";
import { GamesTable } from "@/components/schedule/games-table";
import { PrintViewLink } from "@/components/shared/PrintViewLink";
import { CLEAR_BAG_POLICY_URL } from "@/lib/constants";
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

  // Schedule pages display the decoupled schedule year (current_schedule_year),
  // not current_year. Rosters/practice/sponsors stay on current_year. The roster
  // lookup below is only for the Print View PDF, which lives on a rosters row at
  // the schedule year (stub rows seeded at the schedule year carry the PDF path).
  const { current_schedule_year: current_year, maxpreps_team_url } =
    await getSiteSettingsCore();

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
          <p className="mt-1 text-xs print:hidden">
            <a
              href={CLEAR_BAG_POLICY_URL}
              target="_blank"
              rel="noopener noreferrer"
              className="text-muted-foreground hover:text-mavs-navy hover:underline"
            >
              Clear bag policy →
            </a>
          </p>
          {/* Tickets are digital and each game goes on sale on its own schedule,
              so a Tickets link clicked early lands on a listing that is not
              buyable yet. Saying so here is the difference between "not on sale
              until Monday" and "your link is broken". Same principle as
              publishing the freshman kickoff caveat: explain what the site
              cannot control. */}
          <p className="mt-1 text-xs text-muted-foreground print:hidden">
            Tickets are digital, no cash at the gate. Varsity goes on sale 8:00
            a.m. the Monday before each game; JV and freshman on game day. Each
            listing shows its own on-sale time.
          </p>
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
