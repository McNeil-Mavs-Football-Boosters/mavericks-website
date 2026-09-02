/**
 * ⚠️ TWO DIFFERENT COLUMN RULES LIVE HERE AND THEY POINT OPPOSITE WAYS. Do not
 * collapse them into one "hide what is empty" rule.
 *
 *  - POSITION and GRADE render even when every player is missing them, and show
 *    an em-dash. Jeremy, 2026-08-26, asked and declined: "let's leave
 *    them...maybe it will make the coaches want to step up their game on
 *    getting me data!" The dashes are the only public evidence that the staff
 *    stopped supplying positions. Tidying them away hides the ask. KEEP THEM.
 *
 *  - HEIGHT and WEIGHT are NOT RENDERED AT ALL, on any roster surface, and this
 *    has nothing to do with whether they are populated. Coach, relayed by
 *    Jeremy 2026-09-01: "this coach doesn't like to announce that info to other
 *    teams." It is a competitive call, not a data-quality one. The `height` and
 *    `weight` columns are still in the database and still on the `Player` type,
 *    deliberately — this is display-only so Coach can reverse it without any
 *    data loss.
 *
 * So: an empty Position is a prompt to the coaches; a missing Height is the
 * point. If a future task says "restore the suppressed roster columns", check
 * which of these two it actually means.
 */
import type { Player } from "@/lib/types";

function jerseyKey(value: string | null): {
  numeric: number;
  text: string;
} {
  if (value === null) return { numeric: Number.POSITIVE_INFINITY, text: "" };
  const trimmed = value.trim();
  const parsed = trimmed === "" ? NaN : Number(trimmed);
  return {
    numeric: Number.isFinite(parsed) ? parsed : Number.POSITIVE_INFINITY,
    text: trimmed,
  };
}

function sortPlayers(players: Player[]): Player[] {
  return [...players].sort((a, b) => {
    if (a.sort_order !== b.sort_order) return a.sort_order - b.sort_order;
    const ka = jerseyKey(a.jersey_number);
    const kb = jerseyKey(b.jersey_number);
    if (ka.numeric !== kb.numeric) return ka.numeric - kb.numeric;
    return ka.text.localeCompare(kb.text);
  });
}

function dash(value: string | null | undefined): string {
  return value && value.trim() !== "" ? value : "—";
}

function mobileSep(parts: Array<string | null | undefined>): string {
  return parts
    .map((p) => (p && p.trim() !== "" ? p : null))
    .filter((p): p is string => p !== null)
    .join(" · ");
}

export function PlayerTable({
  players,
  caption,
}: {
  players: Player[];
  caption: string;
}) {
  const sorted = sortPlayers(players);

  return (
    <>
      <div className="hidden md:block print:block">
        <div className="overflow-x-auto">
          <table className="w-full border-collapse text-sm">
            <caption className="sr-only">{caption}</caption>
            <thead>
              <tr className="border-b border-border text-left text-muted-foreground print:text-black">
                <th scope="col" className="py-2 pr-4 font-medium">
                  Jersey #
                </th>
                <th scope="col" className="py-2 pr-4 font-medium">
                  Name
                </th>
                <th scope="col" className="py-2 pr-4 font-medium">
                  Position
                </th>
                <th scope="col" className="py-2 pr-4 font-medium">
                  Grade
                </th>
              </tr>
            </thead>
            <tbody>
              {sorted.map((player) => (
                <tr key={player.id} className="border-b border-border">
                  <td className="py-3 pr-4 align-top whitespace-nowrap font-medium">
                    {dash(player.jersey_number)}
                  </td>
                  <td className="py-3 pr-4 align-top">
                    {player.first_name} {player.last_name}
                  </td>
                  <td className="py-3 pr-4 align-top">
                    {dash(player.position)}
                  </td>
                  <td className="py-3 pr-4 align-top whitespace-nowrap">
                    {dash(player.grade)}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      <div className="space-y-3 md:hidden print:hidden">
        {sorted.map((player) => {
          // Height and weight are suppressed here too — the card variant is a
          // separate render, so hiding the desktop columns alone would have
          // left them published on every phone. See the note at the top.
          const line2 = mobileSep([player.position, player.grade]);
          return (
            <div
              key={player.id}
              className="rounded-lg border border-border bg-white p-4"
            >
              <div className="text-sm font-semibold">
                {player.jersey_number != null && player.jersey_number !== "" ? (
                  <span className="text-muted-foreground">
                    #{player.jersey_number}
                  </span>
                ) : null}{" "}
                {player.first_name} {player.last_name}
              </div>
              {line2 ? (
                <div className="mt-1 text-sm text-muted-foreground">
                  {line2}
                </div>
              ) : null}
            </div>
          );
        })}
      </div>
    </>
  );
}
