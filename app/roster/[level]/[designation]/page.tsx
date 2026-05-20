import { notFound } from "next/navigation";
import ReactMarkdown from "react-markdown";
import remarkGfm from "remark-gfm";

import { PlayerTable } from "@/components/roster/player-table";
import { PrintViewLink } from "@/components/shared/PrintViewLink";
import { getPlayersForRoster, getRosterForTeam } from "@/lib/queries/rosters";
import { getSiteSettingsCore } from "@/lib/site-settings";

const DESIGNATION_TITLES: Record<string, string> = {
  green: "Green",
  blue: "Blue",
};

export default async function FreshmanRosterPage({
  params,
}: {
  params: Promise<{ level: string; designation: string }>;
}) {
  const { level, designation } = await params;
  if (level !== "freshman") notFound();

  const designationTitle = DESIGNATION_TITLES[designation];
  if (!designationTitle) notFound();

  const { current_year, freshman_has_blue } = await getSiteSettingsCore();

  if (designation === "blue" && !freshman_has_blue) notFound();

  const showDesignation = freshman_has_blue;
  const teamLabel = showDesignation
    ? `Freshmen ${designationTitle}`
    : "Freshmen";

  const roster = await getRosterForTeam({
    year: current_year,
    level: "freshman",
    designation: designationTitle,
  });

  const players = roster ? await getPlayersForRoster(roster.id) : [];
  const body = (roster?.body ?? "").trim();
  const sourceNote = (roster?.source_note ?? "").trim();
  const emptyCopy =
    sourceNote || `${current_year} ${teamLabel} roster coming soon.`;

  return (
    <section>
      <header className="mb-6 flex items-start justify-between gap-4">
        <h1 className="text-3xl font-black uppercase tracking-tight sm:text-4xl">
          {current_year} {teamLabel} Roster
        </h1>
        <PrintViewLink storagePath={roster?.pdf_storage_path ?? null} />
      </header>

      {body ? (
        <div className="mb-6 rounded-lg border border-border bg-white p-6 leading-7 [&_h1]:text-2xl [&_h1]:font-semibold [&_h1]:mt-4 [&_h1]:mb-2 [&_h2]:text-xl [&_h2]:font-semibold [&_h2]:mt-4 [&_h2]:mb-2 [&_h3]:font-semibold [&_h3]:mt-3 [&_h3]:mb-1 [&_p]:mb-3 [&_ul]:list-disc [&_ul]:pl-6 [&_ul]:mb-3 [&_ol]:list-decimal [&_ol]:pl-6 [&_ol]:mb-3 [&_a]:text-mavs-navy [&_a]:underline [&_table]:w-full [&_table]:my-3 [&_th]:text-left [&_th]:py-1 [&_td]:py-1 [&_th]:border-b [&_td]:border-b [&_th]:border-border [&_td]:border-border print:[&_a]:text-black print:[&_a]:no-underline">
          <ReactMarkdown remarkPlugins={[remarkGfm]}>{body}</ReactMarkdown>
        </div>
      ) : null}

      {players.length > 0 ? (
        <PlayerTable
          players={players}
          caption={`${current_year} ${teamLabel} Roster`}
        />
      ) : (
        <div className="rounded-lg border border-border bg-white p-8 text-center">
          <p className="text-foreground">{emptyCopy}</p>
        </div>
      )}

    </section>
  );
}
