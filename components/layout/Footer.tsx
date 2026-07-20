import { Fragment } from "react";
import Image from "next/image";
import Link from "next/link";

import { BOOSTER_FORM_URL } from "@/lib/constants";
import { createServerClient } from "@/lib/supabase/server";
import type { SiteSettings } from "@/lib/types";

// lucide-react v1.x dropped brand glyphs (trademark reasons). Inline SVGs keep
// the icon-only social row working without adding another icon dep.
function Facebook({ className }: { className?: string }) {
  return (
    <svg
      xmlns="http://www.w3.org/2000/svg"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
      className={className}
      aria-hidden="true"
    >
      <path d="M18 2h-3a5 5 0 0 0-5 5v3H7v4h3v8h4v-8h3l1-4h-4V7a1 1 0 0 1 1-1h3z" />
    </svg>
  );
}

function Instagram({ className }: { className?: string }) {
  return (
    <svg
      xmlns="http://www.w3.org/2000/svg"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
      className={className}
      aria-hidden="true"
    >
      <rect x="2" y="2" width="20" height="20" rx="5" ry="5" />
      <path d="M16 11.37A4 4 0 1 1 12.63 8 4 4 0 0 1 16 11.37z" />
      <line x1="17.5" y1="6.5" x2="17.51" y2="6.5" />
    </svg>
  );
}

function Youtube({ className }: { className?: string }) {
  return (
    <svg
      xmlns="http://www.w3.org/2000/svg"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
      className={className}
      aria-hidden="true"
    >
      <path d="M22.54 6.42a2.78 2.78 0 0 0-1.94-2C18.88 4 12 4 12 4s-6.88 0-8.6.46a2.78 2.78 0 0 0-1.94 2A29 29 0 0 0 1 11.75a29 29 0 0 0 .46 5.33A2.78 2.78 0 0 0 3.4 19c1.72.46 8.6.46 8.6.46s6.88 0 8.6-.46a2.78 2.78 0 0 0 1.94-2 29 29 0 0 0 .46-5.25 29 29 0 0 0-.46-5.33z" />
      <polygon points="9.75 15.02 15.5 11.75 9.75 8.48 9.75 15.02" />
    </svg>
  );
}

const FALLBACK_SETTINGS: SiteSettings = {
  id: 1,
  legal_name: "McNeil Maverick Football Booster Club",
  display_name: "McNeil Mavericks Football Booster Club",
  ein: "",
  mailing_address: null,
  primary_contact_email: "boosters@mcneilmavericks.org",
  school_affiliation_disclaimer:
    "This website is maintained by the McNeil Maverick Football Booster Club and is not a part of McNeil High School or Round Rock ISD. Neither McNeil High School nor Round Rock ISD is responsible for the content or opinions within this website.",
  facebook_football_url: null,
  facebook_boosters_url: null,
  x_football_url: null,
  x_boosters_url: null,
  instagram_url: null,
  youtube_url: null,
  hero_image_url: null,
  hero_headline: "",
  hero_subhead: null,
  primary_cta_label: "",
  primary_cta_url: "",
  quick_action_card_1: "",
  quick_action_card_2: "",
  quick_action_card_3: "",
  alias_boosters: null,
  alias_president: null,
  alias_treasurer: null,
  alias_secretary: null,
  alias_webmaster: null,
  alias_sponsorship: null,
  current_year: "2025-26",
  current_board_year: "2026-27",
  maxpreps_team_url: null,
  freshman_has_blue: false,
  last_edited_by: null,
  updated_at: "",
};

async function loadSettings(): Promise<SiteSettings> {
  try {
    const supabase = createServerClient();
    const { data, error } = await supabase
      .from("site_settings")
      .select("*")
      .eq("id", 1)
      .single();
    if (error || !data) return FALLBACK_SETTINGS;
    return data as SiteSettings;
  } catch {
    return FALLBACK_SETTINGS;
  }
}

const SITE_LINKS: { href: string; label: string }[] = [
  { href: "/schedule", label: "Schedule" },
  { href: "/boosters", label: "Boosters" },
  { href: "/boosters/join", label: "Join the Booster Club" },
  { href: "/sponsors", label: "Sponsors" },
  { href: "/boosters/donate", label: "Donate" },
  { href: "/privacy", label: "Privacy" },
];

export async function Footer() {
  const settings = await loadSettings();

  return (
    <footer className="border-t border-border bg-muted/30 mt-8 print:hidden">
      <div className="mx-auto max-w-screen-2xl px-4 sm:px-6 lg:px-8 py-6 text-xs leading-snug">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4 md:items-start">
          {/* Address (left) */}
          <div className="flex items-start gap-3">
            <Image
              src="/brand/mhs-logo.png"
              alt=""
              width={56}
              height={56}
              className="h-12 w-12 object-contain shrink-0"
            />
            <div>
              <p className="font-bold uppercase tracking-wide text-mavs-navy">
                {settings.display_name}
              </p>
              <p className="text-muted-foreground">
                Supporting Mavericks football since 2009.
              </p>
              {settings.mailing_address ? (
                <address className="not-italic text-muted-foreground whitespace-pre-line mt-1">
                  {settings.mailing_address}
                </address>
              ) : null}
            </div>
          </div>

          {/* Site links (center) */}
          <nav aria-label="Footer site links" className="md:text-center font-bold uppercase tracking-wide">
            {SITE_LINKS.map((link, i) => (
              <Fragment key={link.href}>
                <Link
                  href={link.href}
                  className="text-muted-foreground hover:text-mavs-navy"
                >
                  {link.label}
                </Link>
                {i < SITE_LINKS.length - 1 ? (
                  <span
                    aria-hidden="true"
                    className="mx-2 text-muted-foreground/60"
                  >
                    ·
                  </span>
                ) : null}
              </Fragment>
            ))}
          </nav>

          {/* Connect (right) */}
          <div className="md:text-right">
            <a
              href={`mailto:${settings.primary_contact_email}`}
              className="text-muted-foreground hover:text-mavs-navy"
            >
              {settings.primary_contact_email}
            </a>
            <div className="mt-1">
              <a
                href={BOOSTER_FORM_URL}
                target="_blank"
                rel="noopener noreferrer"
                className="text-muted-foreground hover:text-mavs-navy"
              >
                Join Our Mailing List
              </a>
            </div>
            <div className="mt-1">
              <Link
                href="/about"
                className="text-muted-foreground hover:text-mavs-navy"
              >
                About
              </Link>
            </div>
            <div className="mt-1 flex items-center gap-3 md:justify-end">
              {settings.facebook_boosters_url ? (
                <a
                  href={settings.facebook_boosters_url}
                  target="_blank"
                  rel="noopener noreferrer"
                  aria-label="Facebook"
                  className="text-muted-foreground hover:text-mavs-navy transition-colors"
                >
                  <Facebook className="h-4 w-4" />
                </a>
              ) : null}
              {settings.instagram_url ? (
                <a
                  href={settings.instagram_url}
                  target="_blank"
                  rel="noopener noreferrer"
                  aria-label="Instagram"
                  className="text-muted-foreground hover:text-mavs-navy transition-colors"
                >
                  <Instagram className="h-4 w-4" />
                </a>
              ) : null}
              {settings.youtube_url ? (
                <a
                  href={settings.youtube_url}
                  target="_blank"
                  rel="noopener noreferrer"
                  aria-label="YouTube"
                  className="text-muted-foreground hover:text-mavs-navy transition-colors"
                >
                  <Youtube className="h-4 w-4" />
                </a>
              ) : null}
            </div>
          </div>
        </div>

        <p className="mt-4 pt-4 border-t border-border text-muted-foreground">
          {settings.school_affiliation_disclaimer} © 2026 McNeil Maverick
          Football Booster Club · 501(c)(3) · EIN 26-4231242.
        </p>
      </div>
    </footer>
  );
}
