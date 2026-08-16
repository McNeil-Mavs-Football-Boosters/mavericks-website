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

  let query = supabase
    .from("games")
    .select("*, venue:venues(name, address, maps_url, latitude, longitude)")
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
