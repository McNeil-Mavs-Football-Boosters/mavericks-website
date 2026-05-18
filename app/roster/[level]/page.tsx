import { notFound } from "next/navigation";
import ReactMarkdown from "react-markdown";
import remarkGfm from "remark-gfm";

import { PlayerTable } from "@/components/roster/player-table";
import { PrintButton } from "@/components/schedule/print-button";
import { PrintFooter } from "@/components/schedule/print-footer";
import { getPlayersForRoster, getRosterForTeam } from "@/lib/queries/rosters";
import { getSiteSettingsCore } from "@/lib/site-settings";

const LEVEL_TITLES: Record<string, string> = {
  varsity: "Varsity",
  jv: "JV",
};

export default async function RosterLevelPage({
  params,
}: {
  params: Promise<{ level: string }>;
}) {
  const { level } = await params;
  const levelTitle = LEVEL_TITLES[level];
  if (!levelTitle) notFound();

  const { current_year } = await getSiteSettingsCore();

  const roster = await getRosterForTeam({
    year: current_year,
    level: level as "varsity" | "jv",
    designation: null,
  });

  const players = roster ? await getPlayersForRoster(roster.id) : [];
  const body = (roster?.body ?? "").trim();
  const sourceNote = (roster?.source_note ?? "").trim();
  const emptyCopy =
    sourceNote || `${current_year} ${levelTitle} roster coming soon.`;

  return (
    <section>
      <header className="mb-6 flex items-start justify-between gap-4">
        <h1 className="text-3xl font-black uppercase tracking-tight sm:text-4xl">
          {current_year} {levelTitle} Roster
        </h1>
        <PrintButton />
      </header>

      {body ? (
        <div className="mb-6 rounded-lg border border-border bg-white p-6 leading-7 [&_h1]:text-2xl [&_h1]:font-semibold [&_h1]:mt-4 [&_h1]:mb-2 [&_h2]:text-xl [&_h2]:font-semibold [&_h2]:mt-4 [&_h2]:mb-2 [&_h3]:font-semibold [&_h3]:mt-3 [&_h3]:mb-1 [&_p]:mb-3 [&_ul]:list-disc [&_ul]:pl-6 [&_ul]:mb-3 [&_ol]:list-decimal [&_ol]:pl-6 [&_ol]:mb-3 [&_a]:text-mavs-navy [&_a]:underline [&_table]:w-full [&_table]:my-3 [&_th]:text-left [&_th]:py-1 [&_td]:py-1 [&_th]:border-b [&_td]:border-b [&_th]:border-border [&_td]:border-border print:[&_a]:text-black print:[&_a]:no-underline">
          <ReactMarkdown remarkPlugins={[remarkGfm]}>{body}</ReactMarkdown>
        </div>
      ) : null}

      {players.length > 0 ? (
        <PlayerTable
          players={players}
          caption={`${current_year} ${levelTitle} Roster`}
        />
      ) : (
        <div className="rounded-lg border border-border bg-white p-8 text-center">
          <p className="text-foreground">{emptyCopy}</p>
        </div>
      )}

      <PrintFooter />
    </section>
  );
}
