import { Fragment } from "react";

import type { Game } from "@/lib/types";
import { cn } from "@/lib/utils";

import { ResultCell } from "./result-cell";
import { TicketCell } from "./ticket-cell";

const DATE_FMT = new Intl.DateTimeFormat("en-US", {
  timeZone: "America/Chicago",
  weekday: "short",
  month: "short",
  day: "numeric",
});

const TIME_FMT = new Intl.DateTimeFormat("en-US", {
  timeZone: "America/Chicago",
  hour: "numeric",
  minute: "2-digit",
  hour12: true,
});

function formatDate(iso: string): string {
  return DATE_FMT.format(new Date(iso));
}

function formatTime(iso: string): string {
  return TIME_FMT.format(new Date(iso)).replace(/\s?AM$/, "am").replace(/\s?PM$/, "pm");
}

function HomeAwayBadge({ value }: { value: Game["home_or_away"] }) {
  const isHome = value === "home";
  return (
    <span
      className={cn(
        "inline-flex items-center rounded-full border px-2 py-0.5 text-xs font-medium uppercase tracking-wide",
        isHome
          ? "border-mavs-navy/30 bg-mavs-navy/10 text-mavs-navy-dark print:border-black print:bg-transparent print:text-black"
          : "border-border bg-muted text-muted-foreground print:border-black print:bg-transparent print:text-black",
      )}
    >
      {value}
    </span>
  );
}

export function GamesTable({ games }: { games: Game[] }) {
  return (
    <div className="hidden md:block print:block">
      <div className="overflow-x-auto">
        <table className="w-full border-collapse text-sm">
          <thead>
            <tr className="border-b border-border text-left text-muted-foreground print:text-black">
              <th scope="col" className="py-2 pr-4 font-medium">Date</th>
              <th scope="col" className="py-2 pr-4 font-medium">Opponent</th>
              <th scope="col" className="py-2 pr-4 font-medium">Location</th>
              <th scope="col" className="py-2 pr-4 font-medium">Home/Away</th>
              <th scope="col" className="py-2 pr-4 font-medium">Time</th>
              <th scope="col" className="py-2 pr-4 font-medium">Result</th>
              <th scope="col" className="py-2 pr-4 font-medium print:hidden">Tickets</th>
            </tr>
          </thead>
          <tbody>
            {games.map((game) => {
              const isHome = game.home_or_away === "home";
              const rowTint = isHome ? "bg-mavs-navy/5 print:bg-transparent" : "";
              const hasNotes = game.notes != null && game.notes.trim() !== "";

              return (
                <Fragment key={game.id}>
                  <tr
                    className={cn(
                      "border-b border-border",
                      rowTint,
                    )}
                  >
                    <td className="py-3 pr-4 align-top whitespace-nowrap">
                      {formatDate(game.game_date)}
                    </td>
                    <td className="py-3 pr-4 align-top">
                      {game.opponent_url ? (
                        <a
                          href={game.opponent_url}
                          target="_blank"
                          rel="noopener noreferrer"
                          className="text-mavs-navy hover:underline print:text-black print:no-underline"
                        >
                          {game.opponent}
                        </a>
                      ) : (
                        game.opponent
                      )}
                    </td>
                    <td className="py-3 pr-4 align-top">
                      {game.location ? (
                        game.venue?.maps_url ? (
                          <a
                            href={game.venue.maps_url}
                            target="_blank"
                            rel="noopener noreferrer"
                            className="text-mavs-navy hover:underline print:text-black print:no-underline"
                          >
                            {game.location}
                          </a>
                        ) : (
                          game.location
                        )
                      ) : (
                        <span className="text-muted-foreground">—</span>
                      )}
                    </td>
                    <td className="py-3 pr-4 align-top">
                      <HomeAwayBadge value={game.home_or_away} />
                    </td>
                    <td className="py-3 pr-4 align-top whitespace-nowrap">
                      {game.result_status === "tbd"
                        ? "TBD"
                        : formatTime(game.game_date)}
                    </td>
                    <td className="py-3 pr-4 align-top whitespace-nowrap">
                      <ResultCell game={game} />
                    </td>
                    {/* print:hidden -- a printed schedule cannot be clicked, and
                        the Print View is the artefact handed out on paper. */}
                    <td className="py-3 pr-4 align-top whitespace-nowrap print:hidden">
                      <TicketCell game={game} />
                    </td>
                  </tr>
                  {hasNotes ? (
                    <tr className={cn("border-b border-border", rowTint)}>
                      <td
                        colSpan={7}
                        className="pb-3 pr-4 pl-0 text-xs italic text-muted-foreground print:text-black"
                      >
                        {game.notes}
                      </td>
                    </tr>
                  ) : null}
                </Fragment>
              );
            })}
          </tbody>
        </table>
      </div>
    </div>
  );
}
