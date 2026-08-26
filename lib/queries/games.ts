import "server-only";

import { createServerClient } from "@/lib/supabase/server";
import type { Game } from "@/lib/types";

type GetGamesForTeamArgs = {
  year: string;
  level: "varsity" | "jv" | "freshman";
  designation: string | null;
};

export async function getGamesForTeam({
  year,
  level,
  designation,
}: GetGamesForTeamArgs): Promise<Game[]> {
  const supabase = createServerClient();

  // `broadcasts.active` is selected and filtered in the component rather than
  // with `.eq("broadcasts.active", true)`. A PostgREST filter on an embedded
  // resource can turn the embed into an inner join, which would drop every game
  // that has no broadcast rows at all — i.e. almost the whole schedule. Row
  // counts here are tiny, so filtering in TS is the safe shape.
  let query = supabase
    .from("games")
    // ⚠️ Keep this as ONE string literal. Building it by concatenation defeats
    // supabase-js's type inference, which parses the select at the type level:
    // it falls back to GenericStringError[] and the cast below stops compiling.
    .select(
      "*, venue:venues(name, address, maps_url, latitude, longitude, ticket_url), broadcasts:game_broadcasts(label, url, sort_order, keep_after_final, active)",
    )
    .eq("year", year)
    .eq("team_level", level);

  query =
    designation === null
      ? query.is("team_designation", null)
      : query.eq("team_designation", designation);

  const { data, error } = await query.order("game_date", { ascending: true });

  if (error) {
    console.error("[queries/games] getGamesForTeam failed", error);
    return [];
  }
  return (data ?? []) as Game[];
}
