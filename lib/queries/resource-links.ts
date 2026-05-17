import "server-only";

import { createServerClient } from "@/lib/supabase/server";
import type { ResourceLink } from "@/lib/types";

export async function getResourceLinks(): Promise<ResourceLink[]> {
  const supabase = createServerClient();

  const { data, error } = await supabase
    .from("resource_links")
    .select("*")
    .eq("active", true)
    .order("section")
    .order("sort_order", { ascending: true });

  if (error) {
    console.error("[queries/resource-links] getResourceLinks failed", error);
    return [];
  }
  return (data ?? []) as ResourceLink[];
}
