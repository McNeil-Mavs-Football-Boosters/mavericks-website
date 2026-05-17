import Link from "next/link";
import {
  Handshake,
  HandHelping,
  HeartHandshake,
  UserPlus,
} from "lucide-react";

import { getSiteSettingsCore } from "@/lib/site-settings";
import { createServerClient } from "@/lib/supabase/server";
import type { BoardMember, SiteSettings } from "@/lib/types";

export const revalidate = 60;

export const metadata = {
  title: "Booster Club",
};

const SETTINGS_DEFAULTS: Pick<
  SiteSettings,
  "legal_name" | "ein" | "primary_contact_email" | "mailing_address"
> = {
  legal_name: "McNeil Maverick Football Booster Club",
  ein: "26-4231242",
  primary_contact_email: "boosters@mcneilmavericks.org",
  mailing_address: null,
};

function initialsFor(name: string): string {
  return name
    .split(/\s+/)
    .filter(Boolean)
    .slice(0, 2)
    .map((w) => (w[0] ?? "").toUpperCase())
    .join("");
}

async function loadPageData(boardYear: string): Promise<{
  settings: Pick<
    SiteSettings,
    "legal_name" | "ein" | "primary_contact_email" | "mailing_address"
  >;
  boardMembers: BoardMember[];
}> {
  try {
    const supabase = createServerClient();
    const [settingsRes, boardRes] = await Promise.all([
      supabase
        .from("site_settings")
        .select("legal_name, ein, primary_contact_email, mailing_address")
        .eq("id", 1)
        .single<
          Pick<
            SiteSettings,
            "legal_name" | "ein" | "primary_contact_email" | "mailing_address"
          >
        >(),
      supabase
        .from("board_members")
        .select("*")
        .eq("active", true)
        .eq("year", boardYear)
        .order("sort_order", { ascending: true })
        .returns<BoardMember[]>(),
    ]);

    const settings =
      settingsRes.error || !settingsRes.data
        ? SETTINGS_DEFAULTS
        : {
            legal_name:
              settingsRes.data.legal_name || SETTINGS_DEFAULTS.legal_name,
            ein: settingsRes.data.ein || SETTINGS_DEFAULTS.ein,
            primary_contact_email:
              settingsRes.data.primary_contact_email ||
              SETTINGS_DEFAULTS.primary_contact_email,
            mailing_address: settingsRes.data.mailing_address,
          };
    const boardMembers =
      boardRes.error || !boardRes.data ? [] : boardRes.data;
    return { settings, boardMembers };
  } catch {
    return { settings: SETTINGS_DEFAULTS, boardMembers: [] };
  }
}

export default async function BoostersPage() {
  const { current_board_year: boardYear } = await getSiteSettingsCore();
  const { settings, boardMembers } = await loadPageData(boardYear);
  const legalName = settings.legal_name;
  const ein = settings.ein;
  const primaryContactEmail = settings.primary_contact_email;
  const mailingAddress =
    settings.mailing_address && settings.mailing_address.trim().length > 0
      ? settings.mailing_address
      : null;

  return (
    <div className="mx-auto max-w-5xl px-4 sm:px-6 lg:px-8 py-12">
      <header className="mb-12 text-center">
        <h1 className="text-3xl font-bold tracking-tight sm:text-4xl">
          McNeil Maverick Football Booster Club
        </h1>
        <p className="mt-3 text-muted-foreground">
          A 501(c)(3) supporting McNeil Mavericks football.
        </p>
      </header>

      <section className="mb-12">
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
        <h2 className="text-xl font-semibold mb-6">Get Involved</h2>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <Link
            href="/boosters/join"
            className="flex flex-col items-center text-center gap-2 rounded-lg border border-border bg-white p-4 hover:border-mavs-green hover:shadow-md transition-all"
          >
            <UserPlus size={24} />
            <span className="font-semibold text-foreground">
              Become a Member
            </span>
          </Link>
          <Link
            href="/boosters/sponsor"
            className="flex flex-col items-center text-center gap-2 rounded-lg border border-border bg-white p-4 hover:border-mavs-green hover:shadow-md transition-all"
          >
            <Handshake size={24} />
            <span className="font-semibold text-foreground">
              Become a Sponsor
            </span>
          </Link>
          <Link
            href="/boosters/donate"
            className="flex flex-col items-center text-center gap-2 rounded-lg border border-border bg-white p-4 hover:border-mavs-green hover:shadow-md transition-all"
          >
            <HeartHandshake size={24} />
            <span className="font-semibold text-foreground">
              Make a Donation
            </span>
          </Link>
          <Link
            href="/boosters/volunteer"
            className="flex flex-col items-center text-center gap-2 rounded-lg border border-border bg-white p-4 hover:border-mavs-green hover:shadow-md transition-all"
          >
            <HandHelping size={24} />
            <span className="font-semibold text-foreground">Volunteer</span>
          </Link>
        </div>
      </section>

      <section className="mb-12">
        <h2 className="text-xl font-semibold mb-6">{boardYear} Board</h2>
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
        <h2 className="text-xl font-semibold mb-3">Affiliations & Contact</h2>
        <p className="text-foreground">
          The {legalName} is a Texas 501(c)(3) nonprofit, EIN {ein}. We operate
          independently of McNeil High School and Round Rock ISD.
        </p>
        <dl className="mt-4 space-y-2 text-sm">
          <div>
            <dt className="font-semibold text-foreground">Email</dt>
            <dd>
              <a
                href={`mailto:${primaryContactEmail}`}
                className="text-mavs-green hover:underline"
              >
                {primaryContactEmail}
              </a>
            </dd>
          </div>
          {mailingAddress ? (
            <div>
              <dt className="font-semibold text-foreground">Mailing address</dt>
              <dd className="whitespace-pre-line text-muted-foreground">
                {mailingAddress}
              </dd>
            </div>
          ) : null}
          <div>
            <dt className="font-semibold text-foreground">Physical address</dt>
            <dd className="text-muted-foreground">
              McNeil High School, 5720 McNeil Dr, Austin, TX 78727
            </dd>
          </div>
        </dl>
        <p className="mt-6 text-sm text-muted-foreground">
          See our{" "}
          <Link href="/privacy" className="text-mavs-green hover:underline">
            Privacy Policy
          </Link>{" "}
          for details on how we handle personal information.
        </p>
      </section>

      <section className="mt-12 pt-8 border-t border-border">
        <h2 className="text-xl font-semibold mb-3">Booster Section</h2>
        <ul className="grid grid-cols-2 sm:grid-cols-3 gap-x-6 gap-y-2 text-sm list-none p-0">
          <li>
            <Link
              href="/boosters/join"
              className="text-mavs-green hover:underline"
            >
              Join
            </Link>
          </li>
          <li>
            <Link
              href="/boosters/members"
              className="text-mavs-green hover:underline"
            >
              Members
            </Link>
          </li>
          <li>
            <Link
              href="/boosters/sponsor"
              className="text-mavs-green hover:underline"
            >
              Sponsorship Opportunities
            </Link>
          </li>
          <li>
            <Link
              href="/boosters/volunteer"
              className="text-mavs-green hover:underline"
            >
              Volunteer
            </Link>
          </li>
          <li>
            <Link
              href="/boosters/committees"
              className="text-mavs-green hover:underline"
            >
              Committees
            </Link>
          </li>
          <li>
            <Link
              href="/boosters/board"
              className="text-mavs-green hover:underline"
            >
              Board
            </Link>
          </li>
          <li>
            <Link
              href="/boosters/events"
              className="text-mavs-green hover:underline"
            >
              Calendar / Events
            </Link>
          </li>
          <li>
            <Link
              href="/boosters/documents"
              className="text-mavs-green hover:underline"
            >
              Documents
            </Link>
          </li>
          <li>
            <Link
              href="/boosters/donate"
              className="text-mavs-green hover:underline"
            >
              Donate
            </Link>
          </li>
        </ul>
      </section>
    </div>
  );
}
