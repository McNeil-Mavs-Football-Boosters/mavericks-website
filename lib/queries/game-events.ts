import "server-only";

import { getSiteSettingsCore } from "@/lib/site-settings";
import { createServerClient } from "@/lib/supabase/server";
import type { EventRow, Game, Venue } from "@/lib/types";

/**
 * Games, rendered as calendar rows.
 *
 * The season schedule lives in `games` and is edited there. /events, the month
 * view and the ICS feed read it THROUGH this module rather than from copies in
 * the `events` table. That choice is the whole point: a game's time or venue
 * changes often (the Aug 20 Eastview scrimmage moved from "TBD at KRAC" to
 * "5:30/7:00 at Maverick Stadium" the same week it was played), and duplicated
 * rows mean every one of those edits has to be made twice or the two surfaces
 * quietly disagree. This project has already been bitten by exactly that with
 * the Meet the Mavs time, which lives in an `events` row AND in the practice
 * markdown. One source, derived at read time, cannot drift.
 *
 * Nothing here writes. There are no game rows in the `events` table and there
 * should never be; if you find one, it is a duplicate and it is wrong.
 */

/** Columns needed to build a calendar row. `updated_at` drives the ICS DTSTAMP. */
type GameCalendarRow = Pick<
  Game,
  | "id"
  | "team_level"
  | "team_designation"
  | "opponent"
  | "game_date"
  | "location"
  | "location_url"
  | "home_or_away"
  | "notes"
> & { updated_at: string; venue: Venue | null };

const SELECT_COLUMNS =
  "id, team_level, team_designation, opponent, game_date, location, location_url, home_or_away, notes, updated_at, venue:venues(name, address, maps_url, latitude, longitude)";

/**
 * Only these two statuses reach a calendar.
 *
 * `tbd` is excluded ON PURPOSE and it is the important one: a TBD game still
 * carries a `game_date`, but that time is an explicit placeholder (migration 078
 * seeded the Eastview scrimmage as 6:00 PM purely because the column is NOT
 * NULL). The games TABLE can render "TBD" in its time cell; a calendar cannot —
 * it would put a confident, wrong 6:00 PM alarm on a parent's phone. A missing
 * entry sends someone to the schedule page; a wrong entry sends them to an empty
 * stadium. `cancelled` and `postponed` are excluded for the same reason: the
 * stored time no longer describes anything real.
 */
const CALENDAR_STATUSES = ["scheduled", "final"];

const LEVEL_LABELS: Record<Game["team_level"], string> = {
  varsity: "Varsity",
  jv: "JV",
  freshman: "Freshmen",
};

/** "Freshmen Green" / "Varsity". Matches the wording on the schedule pages. */
function teamLabel(game: GameCalendarRow, showDesignation: boolean): string {
  const base = LEVEL_LABELS[game.team_level];
  if (game.team_level !== "freshman" || !showDesignation) return base;
  return game.team_designation ? `${base} ${game.team_designation}` : base;
}

/**
 * The games page this row links to. Freshmen have no bare level page — that
 * route 404s, because every freshman row carries a Green/Blue designation — so
 * they link to their designation page.
 */
function gameHref(game: GameCalendarRow): string {
  if (game.team_level !== "freshman") return `/schedule/games/${game.team_level}`;
  const designation = (game.team_designation ?? "").toLowerCase();
  return `/schedule/games/freshman/${designation}`;
}

/**
 * "Varsity Scrimmage vs Eastview High School", "JV at Lake Belton High School",
 * "Varsity vs Round Rock High School (Homecoming)".
 *
 * `notes` carries two different kinds of thing in this table: the literal string
 * 'Scrimmage', which belongs in the middle of the title, and occasion markers
 * like Homecoming / Senior Night, which belong at the end. Both matter enough to
 * be in the title rather than the description: the month view renders the title
 * and nothing else.
 */
function gameTitle(game: GameCalendarRow, showDesignation: boolean): string {
  const label = teamLabel(game, showDesignation);
  const preposition = game.home_or_away === "away" ? "at" : "vs";
  const note = (game.notes ?? "").trim();
  const isScrimmage = note.toLowerCase() === "scrimmage";
  const head = isScrimmage ? `${label} Scrimmage` : label;
  const title = `${head} ${preposition} ${game.opponent}`;
  return !note || isScrimmage ? title : `${title} (${note})`;
}

function toCalendarEvent(
  game: GameCalendarRow,
  showDesignation: boolean,
): EventRow {
  return {
    id: game.id,
    title: gameTitle(game, showDesignation),
    // Synthetic and deliberately not a real events slug. Nothing links by it —
    // `href` below is what every render site uses — but it stays stable and
    // obviously game-shaped if anything ever keys on it.
    slug: `game-${game.id}`,
    description: null,
    starts_at: game.game_date,
    // Games have no end time in the schema, and inventing one would be
    // fabrication. Downstream this is already handled: the upcoming/past split
    // treats a null end as end-of-day (so a 7 PM game stays "upcoming" all day)
    // and the ICS feed falls back to start + 1 hour.
    ends_at: null,
    location: game.location,
    location_url: game.location_url,
    venue: game.venue,
    signup_url: null,
    cover_image_url: null,
    photos_url: null,
    status: "published",
    featured: false,
    updated_at: game.updated_at,
    href: gameHref(game),
  };
}

/**
 * Games in [from, to) as calendar rows, ascending. Both bounds are optional;
 * omitting them returns the whole season.
 */
export async function getGamesAsEvents(
  range: { from?: Date; to?: Date } = {},
): Promise<EventRow[]> {
  const { current_schedule_year, freshman_has_blue } =
    await getSiteSettingsCore();
  const supabase = createServerClient();

  let query = supabase
    .from("games")
    .select(SELECT_COLUMNS)
    .eq("year", current_schedule_year)
    .in("result_status", CALENDAR_STATUSES);

  if (range.from) query = query.gte("game_date", range.from.toISOString());
  if (range.to) query = query.lt("game_date", range.to.toISOString());

  const { data, error } = await query.order("game_date", { ascending: true });

  if (error) {
    // Deliberately degrade to "no games" rather than throwing: a games-table
    // problem must not take down the whole events page, which also carries
    // booster events that have nothing to do with the schedule.
    console.error("[queries/game-events] getGamesAsEvents failed", error);
    return [];
  }

  const rows = (data ?? []) as unknown as GameCalendarRow[];

  return rows
    .filter(
      // When the club is not fielding a Blue team, its designation page 404s
      // (see app/schedule/games/[level]/[designation]/page.tsx). Publishing a
      // calendar entry that links into a 404 is worse than omitting it.
      (game) =>
        freshman_has_blue ||
        game.team_level !== "freshman" ||
        (game.team_designation ?? "").toLowerCase() !== "blue",
    )
    .map((game) => toCalendarEvent(game, freshman_has_blue));
}
