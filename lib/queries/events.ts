import "server-only";

import { createServerClient } from "@/lib/supabase/server";
import type { EventRow } from "@/lib/types";

export async function getUpcomingEvents(): Promise<EventRow[]> {
  const supabase = createServerClient();
  const nowIso = new Date().toISOString();
  const { data, error } = await supabase
    .from("events")
    .select("*")
    .eq("status", "published")
    .gte("starts_at", nowIso)
    .order("starts_at", { ascending: true });

  if (error) {
    console.error("[queries/events] getUpcomingEvents failed", error);
    return [];
  }
  return (data ?? []) as EventRow[];
}

export async function getPastEvents(limit = 10): Promise<EventRow[]> {
  const supabase = createServerClient();
  const nowIso = new Date().toISOString();
  const { data, error } = await supabase
    .from("events")
    .select("*")
    .eq("status", "published")
    .lt("starts_at", nowIso)
    .order("starts_at", { ascending: false })
    .limit(limit);

  if (error) {
    console.error("[queries/events] getPastEvents failed", error);
    return [];
  }
  return (data ?? []) as EventRow[];
}

export async function getEventsInRange(
  rangeStart: Date,
  rangeEnd: Date,
): Promise<EventRow[]> {
  const supabase = createServerClient();
  const { data, error } = await supabase
    .from("events")
    .select("*")
    .eq("status", "published")
    .gte("starts_at", rangeStart.toISOString())
    .lt("starts_at", rangeEnd.toISOString())
    .order("starts_at", { ascending: true });

  if (error) {
    console.error("[queries/events] getEventsInRange failed", error);
    return [];
  }
  return (data ?? []) as EventRow[];
}

export async function getEventBySlug(slug: string): Promise<EventRow | null> {
  const supabase = createServerClient();
  const { data, error } = await supabase
    .from("events")
    .select("*")
    .eq("slug", slug)
    .eq("status", "published")
    .maybeSingle();

  if (error) {
    console.error("[queries/events] getEventBySlug failed", error);
    return null;
  }
  return (data as EventRow | null) ?? null;
}
