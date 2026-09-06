// Row shapes for the Supabase tables the public site reads.
// Keep in sync with db/migrations/.

export interface SiteSettings {
  id: number;
  legal_name: string;
  display_name: string;
  ein: string;
  mailing_address: string | null;
  primary_contact_email: string;
  school_affiliation_disclaimer: string;
  facebook_football_url: string | null;
  facebook_boosters_url: string | null;
  x_football_url: string | null;
  x_boosters_url: string | null;
  instagram_url: string | null;
  youtube_url: string | null;
  hero_image_url: string | null;
  hero_headline: string;
  hero_subhead: string | null;
  primary_cta_label: string;
  primary_cta_url: string;
  quick_action_card_1: string;
  quick_action_card_2: string;
  quick_action_card_3: string;
  alias_boosters: string | null;
  alias_president: string | null;
  alias_treasurer: string | null;
  alias_secretary: string | null;
  alias_webmaster: string | null;
  alias_sponsorship: string | null;
  current_year: string;
  current_board_year: string;
  maxpreps_team_url: string | null;
  freshman_has_blue: boolean;
  last_edited_by: string | null;
  updated_at: string;
}

/**
 * A physical place (migration 134). One row per venue; games and events point at
 * it by id. `address` exists so the ICS feed can emit "Name, address" — a phone
 * can navigate from that, it cannot navigate from "Burger Stadium".
 */
export interface Venue {
  name: string;
  address: string;
  maps_url: string;
  /**
   * The HOST district's box office page for events at this venue (migration
   * 161), or null when nobody has supplied one.
   *
   * This is a per-venue value rather than a per-game one because per-EVENT
   * ticket URLs cannot be stored: RRISD publishes varsity tickets at 8:00 AM the
   * Monday before each game and JV/freshman on game day, so most of the season
   * has no event id yet. The host follows the VENUE, not home/away -- the Cedar
   * Ridge, Westwood and Round Rock games are away games at RRISD venues.
   *
   * ⚠️ Not all hosts use the same platform. Lake Travis (Cavalier Stadium) sells
   * through Hudl, everyone else here through HomeTown. Never compute this URL
   * from a district slug.
   */
  ticket_url: string | null;
  /**
   * Decimal degrees, or null. NULL is the normal state and means "nobody has
   * opened this pin" — the ICS feed then omits GEO and the client geocodes the
   * address, exactly as it did before migration 137. Never populate these by
   * geocoding an address: an unverified point published as an exact one is
   * worse than the vague address it replaced.
   */
  latitude: number | null;
  longitude: number | null;
}

/**
 * The three squads. Single source for the union: `games` and `rosters` both
 * key off it, and `gameLevels` in lib/queries/events.ts narrows against it.
 */
export type TeamLevel = "varsity" | "jv" | "freshman";

/**
 * One broadcast / stream link on a game (migration 165). Zero or more per game
 * — VYPE typically supplies two, their watch page plus the YouTube live URL it
 * embeds, and some weeks supplies none.
 *
 * Supersedes `Game.watch_url`, which is inert. Do not add new readers of that.
 */
export interface GameBroadcast {
  label: string;
  url: string;
  sort_order: number;
  /**
   * Whether the link stays visible once the game is final. True for a YouTube
   * live URL, which persists as a replay and is exactly what a parent who
   * missed the game wants on Saturday. False for a per-game vendor page that is
   * likely to rot.
   */
  keep_after_final: boolean;
  active: boolean;
}

export interface Game {
  id: string;
  year: string;
  team_level: TeamLevel;
  team_designation: string | null;
  opponent: string;
  opponent_url: string | null;
  game_date: string;
  location: string | null;
  location_url: string | null;
  home_or_away: "home" | "away" | "neutral";
  our_score: number | null;
  their_score: number | null;
  result_status: "scheduled" | "final" | "cancelled" | "postponed" | "tbd";
  /**
   * DEPRECATED and emptied by migration 165. Broadcast links live in
   * `broadcasts` now, because VYPE supplies two per game and a single column
   * cannot hold them. Nothing reads this; the column is dropped in a later
   * migration. Do not set it.
   */
  watch_url: string | null;
  maxpreps_game_url: string | null;
  notes: string | null;
  featured: boolean;
  /**
   * Joined from `venues` via venue_id. Null where the venue is unknown — last
   * season's away sites were deliberately left unmapped (migration 134). Render
   * sites must fall back to plain text, never to a guessed link.
   */
  venue?: Venue | null;
  /**
   * Per-game ticket override (migration 161). Normally null; the link comes from
   * `venue.ticket_url`. Set this only for a one-off -- a playoff at a neutral
   * site, or an away-at-RRISD game that is not listed on McNeil's own entity
   * page (use the district-wide box office there).
   *
   * Resolution order is `game.ticket_url ?? venue?.ticket_url ?? null`, and null
   * renders NOTHING. Never render a guessed or placeholder ticket link.
   */
  ticket_url: string | null;
  /**
   * Joined from `game_broadcasts` (migration 165). Absent on any query that did
   * not ask for it, which is why it is optional — `LinksCell` treats undefined
   * and [] the same, so a caller that forgets the join shows no links rather
   * than crashing. Includes inactive rows; filter before rendering.
   */
  broadcasts?: GameBroadcast[] | null;
}

export interface Roster {
  id: string;
  year: string;
  team_level: TeamLevel;
  team_designation: string | null;
  body: string;
  source_note: string | null;
  active: boolean;
  pdf_storage_path: string | null;
  schedule_pdf_storage_path: string | null;
}

export interface Player {
  id: string;
  roster_id: string;
  jersey_number: string | null;
  first_name: string;
  last_name: string;
  position: string | null;
  grade: string | null;
  height: string | null;
  weight: number | null;
  sort_order: number;
  active: boolean;
}

export interface ResourceLink {
  id: string;
  section:
    | "registration_forms"
    | "communications"
    | "resources"
    | "stadiums"
    | "other";
  label: string;
  url: string;
  description: string | null;
  icon_hint: string | null;
  sort_order: number;
  active: boolean;
}

export interface Coach {
  id: string;
  year: string;
  name: string;
  role: string;
  role_category: "head" | "coordinator" | "position_coach" | "trainer" | "staff";
  teaching_role: string | null;
  phone: string | null;
  email: string | null;
  photo_url: string | null;
  bio: string | null;
  sort_order: number;
  active: boolean;
  last_edited_by: string | null;
  created_at: string;
  updated_at: string;
}

export interface MembershipTier {
  id: string;
  name: string;
  price_cents: number;
  description: string | null;
  perks: string[];
  sort_order: number;
  year: string;
  requires_tshirt_size: boolean;
  requires_second_tshirt_size: boolean;
  badge_label: string | null;
  active: boolean;
}

export interface BoardMember {
  id: string;
  name: string;
  role: string;
  email_alias: string | null;
  bio: string | null;
  photo_url: string | null;
  sort_order: number;
  year: string;
  active: boolean;
  is_vacant: boolean;
  last_edited_by: string | null;
  created_at: string;
  updated_at: string;
}

export interface Committee {
  id: string;
  name: string;
  description: string;
  cadence: "ongoing" | "seasonal" | "one_time";
  contact_email: string | null;
  sort_order: number;
}

export interface HeadlineCtaPayload {
  headline: string;
  subhead: string;
  cta_label: string;
  cta_url: string;
}

export interface SponsorSpotlightPayload {
  sponsor_name: string;
  logo_storage_path: string;
  logo_bucket?: string | null;
  tagline?: string | null;
  website_url?: string | null;
}

export type HeroForegroundTilePayload =
  | HeadlineCtaPayload
  | SponsorSpotlightPayload;

export interface HeroBackgroundImage {
  id: string;
  storage_path: string;
  alt_text: string;
  sort_order: number;
  active: boolean;
  // Where the photo anchors when the browser crops it (migration 187). The hero
  // box takes its aspect ratio from the VIEWPORT, so how much gets cut differs
  // on every device and this cannot be baked into the file. DB CHECK constrains
  // it to these three; `HERO_OBJECT_POSITION` in HeroCarousel maps them to
  // literal Tailwind classes.
  object_position: "top" | "center" | "bottom";
}

export interface HeroForegroundTile {
  id: string;
  tile_type: "headline_cta" | "sponsor_spotlight";
  payload: HeroForegroundTilePayload;
  sort_order: number;
  active: boolean;
  expires_at: string | null;
}

export interface EventRow {
  id: string;
  title: string;
  slug: string;
  description: string | null;
  starts_at: string;
  ends_at: string | null;
  location: string | null;
  location_url: string | null;
  signup_url: string | null;
  /**
   * CTA label for `signup_url` (migration 149). NULL means "Sign Up" — the
   * default for the Google Form signups. Set it when the destination is not a
   * signup: Picture Day points at the photographer's STORE, and a checkout
   * button that says "Sign Up" misdescribes what clicking it does.
   *
   * Always read as `signup_label ?? "Sign Up"`. Meaningless without
   * `signup_url`, and never rendered on its own.
   */
  signup_label: string | null;
  cover_image_url: string | null;
  /**
   * Public photo-album URL (migration 114). NULL for most events — every render
   * site must hide its affordance when null rather than showing a dead control.
   */
  photos_url: string | null;
  status: "draft" | "published" | "cancelled";
  featured: boolean;
  updated_at: string;
  /** Joined from `venues` via venue_id — see Game.venue. */
  venue?: Venue | null;
  /**
   * Where this row's title links. NOT a column — absent on everything that comes
   * out of the `events` table, which links to `/events/<slug>`.
   *
   * Rows DERIVED from the `games` table (lib/queries/game-events.ts) set this to
   * the relevant games-schedule page, because they have no `/events/<slug>`
   * detail page to link to and never will. Always read it through `eventHref()`
   * rather than branching on it at the call site — that helper is the one place
   * that knows the fallback, and the ICS feed's URL: line depends on it too.
   */
  href?: string;
}
