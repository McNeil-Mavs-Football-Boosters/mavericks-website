-- 149_event_signup_label.sql
--
-- Picture Day photo ordering. Coach sent Jeremy the photographer's ImageQuix
-- link 2026-08-19 and asked for it on the Picture Day event, two days before
-- pictures are taken (Fri Aug 21).
--
-- WHY A NEW COLUMN AND NOT JUST signup_url. The detail page's CTA label is the
-- literal string "Sign Up →". That is correct for all three events currently
-- using signup_url (youth camp, senior program ad, pool party) — every one is a
-- Google Form you sign up on. This link is a STORE: it resolves to
-- shop.imagequix.com and sells photos. "Sign Up" on a checkout is a lie about
-- what the button does, and relabelling the shared button would break the three
-- rows that mean it literally. So the label becomes per-row, defaulting to the
-- old string when NULL — the three existing rows are untouched and keep
-- rendering exactly as they do today.
--
-- Rejected: putting the URL in `description`. The /events list card and the ICS
-- feed render description as PLAIN TEXT (only the detail page runs it through
-- ReactMarkdown), so a markdown link would render as literal "[Order
-- photos](https://…)" on the list and in every subscribed calendar, and a bare
-- URL would eat the call times out of the card's line-clamp-3.
--
-- Rejected: reusing photos_url. Its button reads "View Photos" and sits next to
-- the free club Google Photos albums (migration 114) in the past-events list.
-- Conflating a paid vendor storefront with a club album is exactly the kind of
-- thing a parent would click expecting free.
--
-- LABEL IS "Order Photos", not "Pre-Order Photos" (Jeremy 2026-08-19). It reads
-- correctly both before Friday, when the store is a prepay, and after, when the
-- same gallery holds the actual proofs. "Pre-Order" would need someone to
-- remember to change it on Aug 21 and nobody would.
--
-- ⚠️ THE URL PUBLISHED HERE IS THE `vando.imagequix.com` FORM COACH SENT, NOT
-- the `shop.imagequix.com/g1001432099` it redirects to. The `g…` id is an
-- ImageQuix-internal gallery id; the vando code + keyword is the link the
-- photographer hands out. Same reasoning as the Venmo profile-link fallback:
-- publish the vendor's public entry point, not the internal id you observed it
-- resolving to today.
--
-- VERIFIED LIVE 2026-08-19 before publishing, by rendering the URL in a real
-- browser (the page is a JS SPA — curl returns only an empty shell, and a
-- headless-Chromium user agent gets served "Page Not Found", so neither proves
-- anything). Rendered with a normal desktop UA it 302s to
-- shop.imagequix.com/g1001432099 and the page title is exactly
-- "McNeil HS (RRISD) F26 Football". A link to the WRONG school's gallery is
-- worse than no link, and nothing on this site can detect that later.
--
-- ⚠️ This link rots silently, same as photos_url. If the photographer closes
-- the gallery, the site shows a dead checkout with no signal. Both columns are
-- nullable and every render site hides its affordance when null, so pulling it
-- down is a one-line UPDATE with no deploy.
--
-- The description also gains one sentence saying the charge is the
-- photographer's (Jeremy 2026-08-19) — the club takes money on this site for
-- memberships and sponsorships, so an unattributed "Order Photos" button on a
-- club page reads as a club charge.

begin;

alter table events
  add column if not exists signup_label text;

comment on column events.signup_label is
  'CTA label for signup_url. NULL means "Sign Up" — the default for the Google '
  'Form signups this column was added around. Set it when the destination is '
  'not a signup (e.g. a photo vendor''s store), so the button says what it does. '
  'Meaningless without signup_url; render sites read it as (signup_label ?? "Sign Up").';

-- Guard: the three existing signup_url rows must stay on the default label.
-- If a later migration sets one, this assertion is the place to find out.
do $$
declare n int;
begin
  select count(*) into n from events
   where signup_url is not null and signup_label is not null;
  if n <> 0 then
    raise exception 'expected 0 pre-existing labelled signups, found %', n;
  end if;
end $$;

update events
set signup_url   = 'https://vando.imagequix.com/P9M6G96?keyword=McNeilHSFBF26',
    signup_label = 'Order Photos',
    description  = description ||
      ' Photos are ordered from the school photographer''s online gallery; the club does not process the charge.'
where slug = 'picture-day-2026'
  and signup_url is null
  and description = 'Team and individual photos for all three levels. Upperclassmen (Soph/Jr/Sr): 7:00 a.m. arrival, pictures complete by 8:00 a.m., film during Period 2. Freshmen: 8:00 a.m. arrival, pictures complete by 9:15 a.m., film after pictures if time permits.';

-- Match on the exact prior description so a re-run cannot append the sentence
-- twice and an edited description aborts loudly rather than being clobbered.
do $$
declare n int;
begin
  select count(*) into n from events
   where slug = 'picture-day-2026'
     and status = 'published'
     and signup_url = 'https://vando.imagequix.com/P9M6G96?keyword=McNeilHSFBF26'
     and signup_label = 'Order Photos'
     and description like '%school photographer''s online gallery%'
     and description not like '%school photographer''s online gallery%school photographer''s online gallery%';
  if n <> 1 then
    raise exception 'picture-day-2026 ordering link not applied as expected (matched % rows)', n;
  end if;
end $$;

commit;

-- /events and /events/<slug> are force-dynamic / request-time, so the button is
-- live with no deploy ONCE THE CODE THAT READS signup_label IS DEPLOYED. Before
-- that deploy the button renders the old "Sign Up →" string against a store URL,
-- which is the wrong label on a checkout — apply this migration and ship the
-- code together.
--
-- ⚠️ /events.ics is CDN-cached for an hour. Irrelevant here (the feed carries no
-- signup field) but noted so nobody goes looking for the link in a calendar.
