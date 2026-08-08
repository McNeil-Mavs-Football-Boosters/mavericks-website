import "server-only";

import { formatInTimeZone, fromZonedTime } from "date-fns-tz";

import { CHICAGO_TZ } from "@/lib/events-format";
import { createServerClient } from "@/lib/supabase/server";
import type { EventRow } from "@/lib/types";

/**
 * An event counts as upcoming until it has ENDED, not until it has started.
 *
 * The original split was `starts_at >= now`, which pushed an event into "Past"
 * the moment it began — the pool party moved to Past at 5:01pm while people were
 * still on their way to it. Jeremy 2026-08-08.
 *
 * Effective end = ends_at, falling back to the END OF THE EVENT'S DAY (Chicago)
 * when ends_at is null. That fallback is deliberate and load-bearing: `ends_at`
 * is genuinely nullable and left null on purpose where the club knows a start
 * time but not a finish (e.g. the equipment pickups in migration 102, where
 * inventing a close time would have been fabrication). Treating those as ending
 * instantly would reintroduce the exact bug for precisely the events with the
 * least information. Falling back to end-of-day keeps them listed all day.
 *
 * Expressed against PostgREST, "effective end >= now" becomes:
 *     ends_at >= now  OR  (ends_at IS NULL AND starts_at >= start-of-today)
 * because for a null-end event, "end of its day >= now" is the same statement as
 * "its day is today or later".
 *
 * ⚠️ Start-of-today must be computed in AMERICA/CHICAGO, not from the server
 * clock. Vercel runs UTC, so at 8pm CDT the server is already on tomorrow's UTC
 * date; a naive local midnight would drop the evening's events a few hours early.
 */
function dayBoundsChicago(): { nowIso: string; startOfTodayIso: string } {
  const now = new Date();
  const todayChicago = formatInTimeZone(now, CHICAGO_TZ, "yyyy-MM-dd");
  return {
    nowIso: now.toISOString(),
    startOfTodayIso: fromZonedTime(
      `${todayChicago}T00:00:00`,
      CHICAGO_TZ,
    ).toISOString(),
  };
}

/** PostgREST `or` expression for "has not ended yet". */
function upcomingFilter(): string {
  const { nowIso, startOfTodayIso } = dayBoundsChicago();
  return `ends_at.gte.${nowIso},and(ends_at.is.null,starts_at.gte.${startOfTodayIso})`;
}

/** Exact complement of upcomingFilter — every published event lands in one or the other. */
function pastFilter(): string {
  const { nowIso, startOfTodayIso } = dayBoundsChicago();
  return `ends_at.lt.${nowIso},and(ends_at.is.null,starts_at.lt.${startOfTodayIso})`;
}

export async function getUpcomingEvents(limit?: number): Promise<EventRow[]> {
  const supabase = createServerClient();
  let query = supabase
    .from("events")
    .select("*")
    .eq("status", "published")
    .or(upcomingFilter())
    .order("starts_at", { ascending: true });

  if (typeof limit === "number") query = query.limit(limit);

  const { data, error } = await query;

  if (error) {
    console.error("[queries/events] getUpcomingEvents failed", error);
    return [];
  }
  return (data ?? []) as EventRow[];
}

export async function getPastEvents(limit = 10): Promise<EventRow[]> {
  const supabase = createServerClient();
  const { data, error } = await supabase
    .from("events")
    .select("*")
    .eq("status", "published")
    .or(pastFilter())
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

export async function getEventsForIcsFeed(): Promise<EventRow[]> {
  const supabase = createServerClient();
  const now = new Date();
  const oneYearAgo = new Date(
    now.getFullYear() - 1,
    now.getMonth(),
    now.getDate(),
  ).toISOString();
  const twoYearsAhead = new Date(
    now.getFullYear() + 2,
    now.getMonth(),
    now.getDate(),
  ).toISOString();
  const { data, error } = await supabase
    .from("events")
    .select("*")
    .eq("status", "published")
    .gte("starts_at", oneYearAgo)
    .lte("starts_at", twoYearsAhead)
    .order("starts_at", { ascending: true });

  if (error) {
    console.error("[queries/events] getEventsForIcsFeed failed", error);
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
