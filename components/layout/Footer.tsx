import Link from "next/link";
import { createServerClient } from "@/lib/supabase/server";
import type { SiteSettings } from "@/lib/types";

const FALLBACK_SETTINGS: SiteSettings = {
  id: 1,
  legal_name: "McNeil Maverick Football Booster Club",
  display_name: "McNeil Mavericks Football Booster Club",
  ein: "",
  mailing_address: null,
  primary_contact_email: "boosters@mcneilmavericks.org",
  school_affiliation_disclaimer:
    "This website is maintained by the McNeil Maverick Football Booster Club and is not a part of McNeil High School or Round Rock ISD. Neither McNeil High School nor Round Rock ISD is responsible for the content or opinions within this website.",
  facebook_group_url: null,
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

export async function Footer() {
  const settings = await loadSettings();

  return (
    <footer className="border-t border-border bg-muted/30 mt-16">
      <div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
          <div>
            <p className="font-semibold text-foreground">
              {settings.display_name}
            </p>
            <p className="text-sm text-muted-foreground mt-1">
              Supporting Mavericks football since 2009.
            </p>
            {settings.mailing_address ? (
              <address className="not-italic text-sm text-muted-foreground mt-3 whitespace-pre-line">
                {settings.mailing_address}
              </address>
            ) : null}
          </div>

          <div>
            <h3 className="text-sm font-semibold text-foreground mb-3">Site</h3>
            <ul className="space-y-2 text-sm">
              <li>
                <Link
                  href="/"
                  className="text-muted-foreground hover:text-mavs-green"
                >
                  Home
                </Link>
              </li>
              <li>
                <Link
                  href="/about"
                  className="text-muted-foreground hover:text-mavs-green"
                >
                  About
                </Link>
              </li>
              <li>
                <Link
                  href="/contact"
                  className="text-muted-foreground hover:text-mavs-green"
                >
                  Contact
                </Link>
              </li>
              <li>
                <Link
                  href="/privacy"
                  className="text-muted-foreground hover:text-mavs-green"
                >
                  Privacy
                </Link>
              </li>
            </ul>
          </div>

          <div>
            <h3 className="text-sm font-semibold text-foreground mb-3">
              Connect
            </h3>
            <ul className="space-y-2 text-sm">
              <li>
                <a
                  href={`mailto:${settings.primary_contact_email}`}
                  className="text-muted-foreground hover:text-mavs-green"
                >
                  {settings.primary_contact_email}
                </a>
              </li>
              {settings.facebook_group_url ? (
                <li>
                  <a
                    href={settings.facebook_group_url}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="text-muted-foreground hover:text-mavs-green"
                  >
                    Facebook
                  </a>
                </li>
              ) : null}
              {settings.instagram_url ? (
                <li>
                  <a
                    href={settings.instagram_url}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="text-muted-foreground hover:text-mavs-green"
                  >
                    Instagram
                  </a>
                </li>
              ) : null}
              {settings.youtube_url ? (
                <li>
                  <a
                    href={settings.youtube_url}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="text-muted-foreground hover:text-mavs-green"
                  >
                    YouTube
                  </a>
                </li>
              ) : null}
            </ul>
          </div>
        </div>

        <div className="mt-10 pt-6 border-t border-border">
          <p className="text-xs text-muted-foreground leading-relaxed">
            {settings.school_affiliation_disclaimer}
          </p>
        </div>

        <p className="mt-6 text-xs text-muted-foreground">
          © 2026 McNeil Maverick Football Booster Club · 501(c)(3) · EIN
          26-4231242
        </p>
      </div>
    </footer>
  );
}
