import { formatInTimeZone } from "date-fns-tz";

import { MCNEIL_TICKETS_URL } from "@/lib/constants";
import { CHICAGO_TZ } from "@/lib/events-format";
import type { Game, GameBroadcast } from "@/lib/types";

/**
 * The schedule's right-hand action column: "Tickets →" before a game, and any
 * broadcast links ("YouTube →", "VYPE →") the game carries.
 *
 * ── WHY THESE SHARE ONE COLUMN, AND WHY THERE IS NO "WATCH" COLUMN ──
 * There was one. It was spec'd (`commit_b_spec.md`), built, and removed by
 * Jeremy's review on 2026-05-26 (commit b4590af) because it was empty on all 11
 * rows and read as dead weight. VYPE broadcasts VARSITY ONLY, so a dedicated
 * column would be empty on every JV and freshman page and on most varsity rows
 * too — the same dead weight, reintroduced. Broadcast links go here instead,
 * where the column already exists and already earns its width.
 *
 * The old stopgap — "Watch →" rendered inside the RESULT cell for non-final
 * games — is gone as of migration 165. It could only ever show one link, and it
 * could not coexist with a score, so a replay had nowhere to go once the game
 * was final. `content_map_v2.md` line 156 left exactly that as an open question
 * deferred "until a real use case arises". VYPE is the use case.
 */

/**
 * Resolve the ticket link for a game, or null if it should not show one.
 *
 * THE ONE DECISION SITE for ticket visibility. It was inline in `TicketCell`;
 * splitting it out is what lets this cell decide whether the row has anything
 * at all to render without duplicating the rules.
 *
 * ── RESOLUTION ORDER (migrations 161, 162) ──
 *   1. `game.ticket_url` — per-game override, normally null.
 *   2. HOME game -> `MCNEIL_TICKETS_URL`, our own box office page.
 *   3. AWAY/neutral -> `venue.ticket_url`, whoever is hosting.
 *
 * Home and away are split because Kelly Reeves and Dragon Stadium host BOTH, so
 * the venue alone cannot decide it.
 *
 * Null renders NOTHING and never a link. There is deliberately no placeholder
 * and no guessed URL: Belton ISD's box office was never supplied, so the JV
 * game at Lake Belton shows nothing rather than something wrong.
 *
 * ⚠️ Hidden for any game that is over. `result_status` alone is NOT enough to
 * decide that: both 2026 scrimmages sat at `scheduled` with dates in the past,
 * so a status-only check put a "Tickets" link on two games that had already been
 * played (caught live 2026-08-25). So this also compares CALENDAR DATES.
 *
 * Compared by Chicago calendar date rather than by instant, deliberately — the
 * link stays up through the whole of game day, including during the game, when
 * somebody standing at the gate is exactly the person who still needs it.
 *
 * The destination is a box office LISTING, not a checkout for this one game.
 * That is deliberate and unavoidable: RRISD only publishes a per-event ticket
 * page the week of the game (varsity 8:00 AM the Monday before, JV and freshman
 * on game day), so per-event URLs cannot be stored ahead of time. The event page
 * itself displays its own on-sale time, so an early click is informative rather
 * than broken.
 */
export function ticketUrlFor(game: Game): string | null {
  const url =
    game.ticket_url ??
    (game.home_or_away === "home"
      ? MCNEIL_TICKETS_URL
      : (game.venue?.ticket_url ?? null));

  if (!url) return null;

  const concluded =
    game.result_status === "final" ||
    game.result_status === "cancelled" ||
    game.result_status === "postponed";
  if (concluded) return null;

  const dayKey = (d: Date) => formatInTimeZone(d, CHICAGO_TZ, "yyyy-MM-dd");
  if (dayKey(new Date(game.game_date)) < dayKey(new Date())) return null;

  return url;
}

/**
 * The broadcast links a game should show right now, in display order.
 *
 * ⚠️ A final game keeps only the rows flagged `keep_after_final`. That flag is
 * per-row rather than per-vendor because the two links VYPE gives us age
 * differently: a YouTube live URL normally survives as a replay, while a
 * per-game VYPE page is likely to rot. Deciding that in code would mean
 * hardcoding vendor names; deciding it in data means next season's provider
 * needs no code change.
 *
 * Unlike tickets, this does NOT hide on a past calendar date — that is the whole
 * point of a replay. Only `result_status === "final"` narrows the list.
 */
export function broadcastsFor(game: Game): GameBroadcast[] {
  const rows = (game.broadcasts ?? []).filter((b) => b.active);
  const visible =
    game.result_status === "final" ? rows.filter((b) => b.keep_after_final) : rows;

  return visible
    .slice()
    .sort((a, b) => a.sort_order - b.sort_order || a.label.localeCompare(b.label));
}

const LINK_CLASS =
  "font-semibold text-mavs-navy hover:underline print:text-black print:no-underline";

function ExternalLink({ href, children }: { href: string; children: string }) {
  return (
    <a href={href} target="_blank" rel="noopener noreferrer" className={LINK_CLASS}>
      {children}
    </a>
  );
}

/**
 * `stacked` is how the desktop table renders (one link per line inside the
 * cell); the mobile card lays its links out inline in its own flex row, so it
 * passes false and spaces them itself.
 */
export function LinksCell({ game, stacked = true }: { game: Game; stacked?: boolean }) {
  const ticket = ticketUrlFor(game);
  const broadcasts = broadcastsFor(game);

  if (!ticket && broadcasts.length === 0) {
    return <span className="text-muted-foreground print:text-black">—</span>;
  }

  const links = [
    ...(ticket ? [{ key: "tickets", label: "Tickets", url: ticket }] : []),
    ...broadcasts.map((b) => ({ key: b.url, label: b.label, url: b.url })),
  ];

  return (
    <span className={stacked ? "flex flex-col items-start gap-1" : "contents"}>
      {links.map((l) => (
        <ExternalLink key={l.key} href={l.url}>
          {`${l.label} →`}
        </ExternalLink>
      ))}
    </span>
  );
}
