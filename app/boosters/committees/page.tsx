import Image from "next/image";
import Link from "next/link";

import type { Committee } from "@/lib/types";
import { createServerClient } from "@/lib/supabase/server";

export const dynamic = "force-dynamic";

export const metadata = {
  title: "Booster Club Committees | McNeil Mavericks Football",
  description:
    "11 committees keep the Booster Club running. Year-round, football season, and signature events — find where you fit.",
};

const CADENCE_LABELS: Record<Committee["cadence"], string> = {
  ongoing: "Year-Round",
  seasonal: "Football Season",
  one_time: "Signature Event",
};

function CadenceBadge({ cadence }: { cadence: Committee["cadence"] }) {
  return (
    <span className="inline-block bg-mavs-green/10 text-mavs-green text-xs font-bold uppercase tracking-wider px-2.5 py-1 rounded">
      {CADENCE_LABELS[cadence]}
    </span>
  );
}

function CommitteeCard({ committee }: { committee: Committee }) {
  // TODO: when chair_board_member_id is populated, join board_members and render chair name
  return (
    <div className="bg-white border-2 border-mavs-navy/20 rounded-lg p-6 flex flex-col hover:border-mavs-navy/40 transition-colors">
      <div className="flex items-start justify-between gap-3 mb-3">
        <h3 className="text-xl font-bold uppercase text-mavs-navy">
          {committee.name}
        </h3>
        <CadenceBadge cadence={committee.cadence} />
      </div>
      <p className="text-gray-800 leading-relaxed flex-grow">
        {committee.description}
      </p>
      {committee.contact_email ? (
        <a
          href={`mailto:${committee.contact_email}`}
          className="text-mavs-navy text-sm font-semibold mt-4 hover:text-mavs-green transition-colors"
        >
          Contact: {committee.contact_email}
        </a>
      ) : null}
    </div>
  );
}

export default async function BoostersCommitteesPage() {
  // Copy editable. Verbatim from spec 2026-05-23.
  const supabase = createServerClient();

  const { data, error } = await supabase
    .from("committees")
    .select("id, name, description, cadence, contact_email, sort_order")
    .eq("active", true)
    .order("sort_order", { ascending: true });

  if (error) {
    console.error("[boosters/committees] fetch failed", error);
  }

  const committees: Committee[] = (data ?? []) as Committee[];
  const ongoingCommittees = committees.filter((c) => c.cadence === "ongoing");
  const seasonalCommittees = committees.filter((c) => c.cadence === "seasonal");
  const oneTimeCommittees = committees.filter((c) => c.cadence === "one_time");

  return (
    <>
      {/* 1. Hero */}
      <section className="bg-mavs-navy text-white py-12 md:py-16 relative overflow-hidden">
        <div className="container mx-auto px-4 relative z-10">
          <div className="text-center md:text-left md:max-w-3xl">
            <h1 className="text-3xl md:text-5xl font-black uppercase tracking-tight">
              Booster Club Committees
            </h1>
            <div className="h-1 w-20 bg-mavs-green mt-3 mx-auto md:mx-0"></div>
            <p className="text-lg md:text-xl mt-4 text-white/90">
              Ongoing, seasonal, and one-time roles. Every committee needs help
              — find where you fit.
            </p>
          </div>
        </div>

        {/* Horseshoe accent — decorative, right side, hidden on mobile */}
        <div className="hidden md:block absolute right-8 top-1/2 -translate-y-1/2 opacity-20 pointer-events-none">
          <Image
            src="/brand/mhs-horseshoe.jpg"
            alt=""
            width={180}
            height={180}
            className="object-contain"
          />
        </div>
      </section>

      {/* 2. Intro / context band */}
      <section className="container mx-auto px-4 py-10 md:py-12 max-w-3xl">
        <div className="space-y-4 text-lg leading-relaxed text-gray-800">
          <p>
            The Booster Club runs on volunteer effort across 11 committees.
            Some operate year-round, some only during football season, and some
            come together for a single signature event.
          </p>
          <p>
            Browse the committees below to see what each one does. When you&apos;re
            ready to step up, head to{" "}
            <Link
              href="/boosters/volunteer"
              className="text-mavs-navy font-semibold underline hover:text-mavs-green transition-colors"
            >
              Volunteer
            </Link>{" "}
            to sign up.
          </p>
          <p className="text-sm text-gray-600 italic pt-2">
            Committees coordinate via GroupMe. New volunteers receive the
            invite link after signing up.
          </p>
        </div>
      </section>

      {/* 3. Cards grouped by cadence */}
      <section className="container mx-auto px-4 py-8 md:py-12 space-y-12 md:space-y-16">
        {/* Year-Round */}
        <div>
          <div className="text-center mb-8">
            <h2 className="text-2xl md:text-3xl font-black uppercase tracking-tight text-mavs-navy">
              Year-Round Committees
            </h2>
            <div className="h-1 w-16 bg-mavs-green mx-auto mt-3"></div>
            <p className="text-base text-gray-600 mt-3 max-w-2xl mx-auto">
              Active throughout the school year. Steady, recurring work.
            </p>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6 max-w-5xl mx-auto">
            {ongoingCommittees.map((c) => (
              <CommitteeCard key={c.id} committee={c} />
            ))}
          </div>
        </div>

        {/* Football Season */}
        <div>
          <div className="text-center mb-8">
            <h2 className="text-2xl md:text-3xl font-black uppercase tracking-tight text-mavs-navy">
              Football Season Committees
            </h2>
            <div className="h-1 w-16 bg-mavs-green mx-auto mt-3"></div>
            <p className="text-base text-gray-600 mt-3 max-w-2xl mx-auto">
              Active August through November. Ramp up and wind down with the
              schedule.
            </p>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6 max-w-5xl mx-auto">
            {seasonalCommittees.map((c) => (
              <CommitteeCard key={c.id} committee={c} />
            ))}
          </div>
        </div>

        {/* Signature Events */}
        <div>
          <div className="text-center mb-8">
            <h2 className="text-2xl md:text-3xl font-black uppercase tracking-tight text-mavs-navy">
              Signature Events
            </h2>
            <div className="h-1 w-16 bg-mavs-green mx-auto mt-3"></div>
            <p className="text-base text-gray-600 mt-3 max-w-2xl mx-auto">
              One-time-per-year events. Concentrated effort, big payoff.
            </p>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6 max-w-5xl mx-auto">
            {oneTimeCommittees.map((c) => (
              <CommitteeCard key={c.id} committee={c} />
            ))}
          </div>
        </div>
      </section>

      {/* 4. Volunteer CTA */}
      <section className="container mx-auto px-4 py-12 md:py-16">
        <div className="bg-mavs-navy text-white rounded-lg p-8 md:p-12 text-center relative overflow-hidden max-w-3xl mx-auto">
          <div className="absolute top-0 left-0 right-0 h-1 bg-mavs-green"></div>
          <h2 className="text-2xl md:text-3xl font-black uppercase tracking-tight">
            Ready to Get Involved?
          </h2>
          <p className="text-lg text-white/90 mt-4 max-w-xl mx-auto">
            Sign up to volunteer with a committee. Every parent has something
            to offer — from one event a year to year-round help.
          </p>
          <Link
            href="/boosters/volunteer"
            className="inline-block mt-8 bg-mavs-green text-white px-8 py-4 font-bold uppercase hover:bg-mavs-green/90 transition-colors text-lg"
          >
            Volunteer with the Mavs
          </Link>
        </div>
      </section>
    </>
  );
}
