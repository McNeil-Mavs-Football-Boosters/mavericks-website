import Link from "next/link";

import { createServerClient } from "@/lib/supabase/server";
import type { BoardMember, SiteSettings } from "@/lib/types";

export const revalidate = 60;

export const metadata = {
  title: "About",
};

const AFFILIATION_DEFAULTS = {
  legal_name: "McNeil Maverick Football Booster Club",
  ein: "26-4231242",
};

function initialsFor(name: string): string {
  return name
    .split(/\s+/)
    .filter(Boolean)
    .slice(0, 2)
    .map((word) => (word[0] ?? "").toUpperCase())
    .join("");
}

async function loadPageData(): Promise<{
  settings: Pick<SiteSettings, "legal_name" | "ein">;
  boardMembers: BoardMember[];
}> {
  try {
    const supabase = createServerClient();
    const [settingsRes, boardRes] = await Promise.all([
      supabase
        .from("site_settings")
        .select("legal_name, ein")
        .eq("id", 1)
        .single<Pick<SiteSettings, "legal_name" | "ein">>(),
      supabase
        .from("board_members")
        .select("*")
        .eq("active", true)
        .eq("year", "2026-27")
        .order("sort_order", { ascending: true })
        .returns<BoardMember[]>(),
    ]);

    const settings =
      settingsRes.error || !settingsRes.data
        ? AFFILIATION_DEFAULTS
        : {
            legal_name:
              settingsRes.data.legal_name || AFFILIATION_DEFAULTS.legal_name,
            ein: settingsRes.data.ein || AFFILIATION_DEFAULTS.ein,
          };
    const boardMembers =
      boardRes.error || !boardRes.data ? [] : boardRes.data;
    return { settings, boardMembers };
  } catch {
    return { settings: AFFILIATION_DEFAULTS, boardMembers: [] };
  }
}

export default async function AboutPage() {
  const { settings, boardMembers } = await loadPageData();

  return (
    <div className="mx-auto max-w-4xl px-4 sm:px-6 lg:px-8 py-12">
      <section className="mb-12">
        <h1 className="text-3xl font-bold tracking-tight sm:text-4xl mb-6">
          About the Booster Club
        </h1>
        <h2 className="text-xl font-semibold mb-3">Our Mission</h2>
        <blockquote className="border-l-4 border-mavs-green pl-4 py-1 text-foreground space-y-3">
          <p>
            The purpose of the Booster Club is to provide encouragement and
            generate support for the football program at McNeil High School.
            The Booster Club is a 501(c)(3) organization that works to support
            and improve the football program through activities for the teams
            and improvement of facilities and equipment. Activities in the
            Booster Club will include, but may not be limited to:
          </p>
          <p>
            Support and improve the McNeil Mavericks Football program and
            teams through:
          </p>
          <ul className="list-disc pl-6 space-y-1">
            <li>
              Positive interaction between the Booster Club, school officials,
              the coaching staff, the student body, and the community.
            </li>
            <li>
              Hosting and sponsoring events to build team spirit and morale
              amongst athletes, student body, parents, and community including
              pre-game and post-game gatherings, dinners, and rallies as well
              as an EOY awards ceremony.
            </li>
            <li>
              Hosting and sponsoring events to bring the community and school
              together in support of the McNeil Football program.
            </li>
            <li>
              Fundraising activities to provide upgrades and benefits to the
              teams, athletes, and program.
            </li>
            <li>
              Working for the development of a constructive attitude by all
              students towards all levels of athletic endeavors.
            </li>
          </ul>
        </blockquote>
      </section>

      <section className="mb-12">
        <h2 className="text-xl font-semibold mb-3">What dues fund</h2>
        {/* PLACEHOLDER — replace once Chevon delivers copy (spec_review.md G5) */}
        <p className="text-foreground">
          Membership dues directly fund the Mavericks football program — team
          meals, banquet costs, senior recognition, facility improvements, and
          equipment the school budget doesn&apos;t cover. The board will share
          a detailed allocation breakdown each season.
        </p>
      </section>

      <section className="mb-12">
        <h2 className="text-xl font-semibold mb-6">2026-27 Board</h2>
        {boardMembers.length === 0 ? (
          <p className="text-muted-foreground">
            Board roster will be posted soon.
          </p>
        ) : (
          <ul className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6 list-none p-0">
            {boardMembers.map((member) => {
              const initials = initialsFor(member.name);
              return (
                <li key={member.id}>
                  {member.photo_url ? (
                    <div className="aspect-square w-full overflow-hidden rounded-lg bg-muted">
                      {/* eslint-disable-next-line @next/next/no-img-element */}
                      <img
                        src={member.photo_url}
                        alt=""
                        className="h-full w-full object-cover"
                      />
                    </div>
                  ) : (
                    <div className="aspect-square w-full rounded-lg bg-muted flex items-center justify-center text-muted-foreground text-3xl font-semibold">
                      {initials}
                    </div>
                  )}
                  <p className="mt-3 font-semibold text-foreground">
                    {member.name}
                  </p>
                  <p className="text-sm text-muted-foreground">{member.role}</p>
                  {member.email_alias ? (
                    <a
                      href={`mailto:${member.email_alias}`}
                      className="mt-1 inline-block text-sm text-mavs-green hover:underline"
                    >
                      {member.email_alias}
                    </a>
                  ) : null}
                </li>
              );
            })}
          </ul>
        )}
      </section>

      <section className="mt-12 pt-8 border-t border-border">
        <h2 className="text-xl font-semibold mb-3">Affiliations</h2>
        <p className="text-foreground">
          The {settings.legal_name} is a Texas 501(c)(3) nonprofit, EIN{" "}
          {settings.ein}. We operate independently of McNeil High School and
          Round Rock ISD. See our{" "}
          <Link
            href="/privacy"
            className="text-mavs-green hover:underline"
          >
            Privacy Policy
          </Link>{" "}
          for details on how we handle personal information.
        </p>
      </section>
    </div>
  );
}
