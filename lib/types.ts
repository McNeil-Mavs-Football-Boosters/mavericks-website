// Row shapes for the Supabase tables the public site reads.
// Keep in sync with db/migrations/.

export interface SiteSettings {
  id: number;
  legal_name: string;
  display_name: string;
  ein: string;
  mailing_address: string | null;
  primary_contact_email: string;
  school_affiliation_disclaimer: string;
  facebook_football_url: string | null;
  facebook_boosters_url: string | null;
  x_football_url: string | null;
  x_boosters_url: string | null;
  instagram_url: string | null;
  youtube_url: string | null;
  hero_image_url: string | null;
  hero_headline: string;
  hero_subhead: string | null;
  primary_cta_label: string;
  primary_cta_url: string;
  quick_action_card_1: string;
  quick_action_card_2: string;
  quick_action_card_3: string;
  alias_boosters: string | null;
  alias_president: string | null;
  alias_treasurer: string | null;
  alias_secretary: string | null;
  alias_webmaster: string | null;
  alias_sponsorship: string | null;
  last_edited_by: string | null;
  updated_at: string;
}

export interface BoardMember {
  id: string;
  name: string;
  role: string;
  email_alias: string | null;
  bio: string | null;
  photo_url: string | null;
  sort_order: number;
  year: string;
  active: boolean;
  last_edited_by: string | null;
  created_at: string;
  updated_at: string;
}
