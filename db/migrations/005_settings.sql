-- Migration 005: Settings tables (site_settings singleton)

CREATE TABLE site_settings (
  id integer PRIMARY KEY DEFAULT 1,
  -- Organization
  legal_name text NOT NULL DEFAULT 'McNeil Maverick Football Booster Club',
  display_name text NOT NULL DEFAULT 'McNeil Mavericks Football Booster Club',
  ein text NOT NULL DEFAULT '26-4231242',
  mailing_address text,
  primary_contact_email text NOT NULL DEFAULT 'boosters@mcneilmavericks.org',
  school_affiliation_disclaimer text NOT NULL DEFAULT 'This website is maintained by the McNeil Maverick Football Booster Club and is not a part of McNeil High School or Round Rock ISD. Neither McNeil High School nor Round Rock ISD is responsible for the content or opinions within this website.',

  -- Social
  facebook_group_url text,
  instagram_url text,
  youtube_url text,

  -- Homepage
  hero_image_url text,
  hero_headline text NOT NULL DEFAULT 'McNeil Mavericks Football Booster Club',
  hero_subhead text,
  primary_cta_label text NOT NULL DEFAULT 'Join the Club',
  primary_cta_url text NOT NULL DEFAULT '/join',
  quick_action_card_1 text NOT NULL DEFAULT 'join',
  quick_action_card_2 text NOT NULL DEFAULT 'sponsor',
  quick_action_card_3 text NOT NULL DEFAULT 'donate',

  -- Email aliases (display only)
  alias_boosters text,
  alias_president text,
  alias_treasurer text,
  alias_secretary text,
  alias_webmaster text,
  alias_sponsorship text,

  last_edited_by uuid REFERENCES auth.users(id),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CHECK (id = 1)  -- enforce singleton
);

INSERT INTO site_settings (id) VALUES (1) ON CONFLICT DO NOTHING;
