import { ExternalLink } from "lucide-react";

import type { Game } from "@/lib/types";
import { cn } from "@/lib/utils";

import { ResultCell } from "./result-cell";

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
          ? "border-mavs-navy/30 bg-mavs-navy/10 text-mavs-navy-dark"
          : "border-border bg-muted text-muted-foreground",
      )}
    >
      {value}
    </span>
  );
}

export function GameCard({ game }: { game: Game }) {
  const isHome = game.home_or_away === "home";
  const hasNotes = game.notes != null && game.notes.trim() !== "";

  return (
    <div
      className={cn(
        "block md:hidden print:hidden rounded-lg border border-border bg-white p-4",
        isHome && "bg-mavs-navy/5",
      )}
    >
      <div className="flex items-start justify-between gap-3">
        <div className="font-semibold">
          {game.opponent_url ? (
            <a
              href={game.opponent_url}
              target="_blank"
              rel="noopener noreferrer"
              className="text-mavs-navy hover:underline"
            >
              {game.opponent}
            </a>
          ) : (
            game.opponent
          )}
        </div>
        <HomeAwayBadge value={game.home_or_away} />
      </div>

      <div className="mt-1 text-sm text-muted-foreground">
        {formatDate(game.game_date)} · {formatTime(game.game_date)}
      </div>

      <div className="mt-1 text-sm">
        {game.location ? (
          game.location_url ? (
            <a
              href={game.location_url}
              target="_blank"
              rel="noopener noreferrer"
              className="text-mavs-navy hover:underline"
            >
              {game.location}
            </a>
          ) : (
            <span>{game.location}</span>
          )
        ) : (
          <span className="text-muted-foreground">—</span>
        )}
      </div>

      <div className="mt-2 flex items-center gap-3 text-sm">
        <ResultCell game={game} />
        {game.watch_url ? (
          <a
            href={game.watch_url}
            target="_blank"
            rel="noopener noreferrer"
            aria-label={`Watch ${game.opponent} game`}
            className="inline-flex text-mavs-navy hover:text-mavs-navy-dark"
          >
            <ExternalLink className="h-4 w-4" />
          </a>
        ) : null}
      </div>

      {hasNotes ? (
        <div className="mt-2 text-xs italic text-muted-foreground">
          {game.notes}
        </div>
      ) : null}
    </div>
  );
}
