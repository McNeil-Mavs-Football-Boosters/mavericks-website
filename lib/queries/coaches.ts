import "server-only";

import { createServerClient } from "@/lib/supabase/server";
import type { Coach } from "@/lib/types";

export async function getCoachesForYear(year: string): Promise<Coach[]> {
  const supabase = createServerClient();

  const { data, error } = await supabase
    .from("coaches")
    .select("*")
    .eq("year", year)
    .eq("active", true)
    .order("role_category", { ascending: true })
    .order("sort_order", { ascending: true });

  if (error) {
    console.error("[queries/coaches] getCoachesForYear failed", error);
    return [];
  }
  return (data ?? []) as Coach[];
}
