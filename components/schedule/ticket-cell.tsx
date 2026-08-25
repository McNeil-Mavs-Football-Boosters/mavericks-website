import { MCNEIL_TICKETS_URL } from "@/lib/constants";
import type { Game } from "@/lib/types";

/**
 * "Tickets →" for a game that has not been played yet.
 *
 * Mirrors ResultCell's conditional-external-link shape, including the `print:`
 * variants, but is kept separate so ResultCell stays about the result.
 *
 * ── RESOLUTION ORDER (migrations 161, 162) ──
 *   1. `game.ticket_url` — per-game override, normally null.
 *   2. HOME game -> `MCNEIL_TICKETS_URL`, our own box office page.
 *   3. AWAY/neutral -> `venue.ticket_url`, whoever is hosting.
 *
 * Home and away are split because Kelly Reeves and Dragon Stadium host BOTH, so
 * the venue alone cannot decide it.
 *
 * Null renders an em-dash and NEVER a link. There is deliberately no placeholder
 * and no guessed URL: Belton ISD's box office was never supplied, so the JV game
 * at Lake Belton shows nothing rather than something wrong.
 *
 * ⚠️ Hidden once the game is final. Nobody buys a ticket to a game that has been
 * played, and a live link on a finished game reads as a bug.
 *
 * The destination is a box office LISTING, not a checkout for this one game.
 * That is deliberate and unavoidable: RRISD only publishes a per-event ticket
 * page the week of the game (varsity 8:00 AM the Monday before, JV and freshman
 * on game day), so per-event URLs cannot be stored ahead of time. The event page
 * itself displays its own on-sale time, so an early click is informative rather
 * than broken.
 */
export function TicketCell({ game }: { game: Game }) {
  const url =
    game.ticket_url ??
    (game.home_or_away === "home"
      ? MCNEIL_TICKETS_URL
      : (game.venue?.ticket_url ?? null));

  if (!url || game.result_status === "final") {
    return <span className="text-muted-foreground print:text-black">—</span>;
  }

  return (
    <a
      href={url}
      target="_blank"
      rel="noopener noreferrer"
      className="font-semibold text-mavs-navy hover:underline print:text-black print:no-underline"
    >
      Tickets →
    </a>
  );
}
