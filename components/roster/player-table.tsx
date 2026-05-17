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

function weightCell(weight: number | null): string {
  return weight == null ? "—" : `${weight} lbs`;
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
                <th scope="col" className="py-2 pr-4 font-medium">
                  Height
                </th>
                <th scope="col" className="py-2 pr-4 font-medium">
                  Weight
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
                  <td className="py-3 pr-4 align-top whitespace-nowrap">
                    {dash(player.height)}
                  </td>
                  <td className="py-3 pr-4 align-top whitespace-nowrap">
                    {weightCell(player.weight)}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      <div className="space-y-3 md:hidden print:hidden">
        {sorted.map((player) => {
          const line2 = mobileSep([player.position, player.grade]);
          const weightText =
            player.weight == null ? null : `${player.weight} lbs`;
          const line3 = mobileSep([player.height, weightText]);
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
              {line3 ? (
                <div className="mt-1 text-sm text-muted-foreground">
                  {line3}
                </div>
              ) : null}
            </div>
          );
        })}
      </div>
    </>
  );
}
