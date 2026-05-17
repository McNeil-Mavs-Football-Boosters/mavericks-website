import "server-only";

import { createServerClient } from "@/lib/supabase/server";
import type { Player, Roster } from "@/lib/types";

type GetRosterArgs = {
  year: string;
  level: "varsity" | "jv" | "freshman";
  designation: string | null;
};

export async function getRosterForTeam({
  year,
  level,
  designation,
}: GetRosterArgs): Promise<Roster | null> {
  const supabase = createServerClient();

  let query = supabase
    .from("rosters")
    .select("*")
    .eq("year", year)
    .eq("team_level", level)
    .eq("active", true);

  query =
    designation === null
      ? query.is("team_designation", null)
      : query.eq("team_designation", designation);

  const { data, error } = await query.limit(1).maybeSingle<Roster>();

  if (error) {
    console.error("[queries/rosters] getRosterForTeam failed", error);
    return null;
  }
  return data ?? null;
}

export async function getPlayersForRoster(
  rosterId: string,
): Promise<Player[]> {
  const supabase = createServerClient();
  const { data, error } = await supabase
    .from("players")
    .select("*")
    .eq("roster_id", rosterId)
    .eq("active", true)
    .order("sort_order", { ascending: true })
    .order("jersey_number", { ascending: true, nullsFirst: false });

  if (error) {
    console.error("[queries/rosters] getPlayersForRoster failed", error);
    return [];
  }
  return (data ?? []) as Player[];
}
