# /boosters/volunteer Spec

## Goal
Single page that explains why volunteering matters, lists ways to help, and pushes visitors to the volunteer interest Google Form.

## Route
`/boosters/volunteer`

Closes:
- Booster Club header dropdown → "Volunteer" 404
- /boosters/committees bottom CTA landing

## Form URL
Already in `lib/constants.ts`:
```
export const VOLUNTEER_FORM_URL = "https://docs.google.com/forms/d/e/1FAIpQLSfcpW_jAdJexrfSDcUlRZt78dv3S3omPysOR-RoOfY_1TWWkQ/viewform";
```

All "Sign Up" CTAs on this page link to `VOLUNTEER_FORM_URL`, open in new tab (`target="_blank" rel="noopener"`).

## Layout (top to bottom)

### 1. Hero band — GREEN
- Background: `bg-mavs-green text-white`
- Same 3-col flex-row pattern as `/boosters/committees`:
  - Left: `mhs-logo.png` with white-disc treatment (`rounded-full bg-white p-0.5`)
  - Center: title "Volunteer with McNeil Football" (text-4xl md:text-6xl, font-bold)
  - Right: button "SIGN UP →" — `bg-mavs-navy text-white`, links to `VOLUNTEER_FORM_URL`
- Container matches `/sponsors` so the right button right-aligns with rightmost top-nav tab
- Mobile: stacks vertically, button full-width

This is the first GREEN page-header band in the site. Deliberate. Future volunteer-adjacent pages can follow the same pattern.

### 2. Intro prose section
- White background, container-constrained, max-w-3xl for line length
- Three paragraphs verbatim:

> McNeil Football is powered by more than the players and coaches on the field. It is also powered by the parents, families, and volunteers who give their time behind the scenes to make the season meaningful for our athletes.

> Every meal served, every pickup made, every event organized, and every hour volunteered helps create the kind of program our players deserve. These moments may seem small, but they add up to something our athletes feel throughout the season: support.

> The McNeil Football Booster Club offers several ways for families and community members to get involved. Whether you can help once, a few times, or throughout the season, your time makes a difference.

### 3. "Ways to Get Involved" section
- Section heading: "Ways to Get Involved" (text-3xl md:text-4xl, font-bold, navy, centered)
- Subhead under it: "Volunteer opportunities may include:"
- Card grid: `grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6`
- 11 cards in this exact order. Each card: white bg, rounded-lg, border (border-gray-200), p-6, subtle hover lift (`hover:shadow-md transition-shadow`)
- Card layout: lucide-react icon at top (size 32, mavs-navy or mavs-green — designer's call but consistent across all cards), then title (font-bold, text-lg), then description (text-gray-600, text-sm)

| # | Icon (lucide-react) | Title | Description |
|---|---|---|---|
| 1 | Utensils | Hosting a Varsity Team Dinner | Open your home or organize a meal for the varsity team during the season. |
| 2 | Coffee | Picking Up Coaches Meals | Grab and deliver meals for the coaching staff on practice or game days. |
| 3 | Pizza | Picking Up Game-Day Meals | Help feed the team before games with quick pickup and delivery shifts. |
| 4 | Ruler | Freshman / JV Chain Gang | Work the chain crew on the sideline at Freshman and JV home games. |
| 5 | Award | Banquets & Player Recognition | Help plan and run the football banquet, senior night, and other recognition events. |
| 6 | HandCoins | Fundraising | Pitch in on fundraisers that keep the booster club going year-round. |
| 7 | Users | Joining a Committee | Plug into one of our 11 committees for a deeper, ongoing role. *(Card links to /boosters/committees)* |
| 8 | Flag | Game-Day Tunnel Crew | Help transport, set up, and tear down the run-out tunnel on game days. Requires a few volunteers and a trailer. |
| 9 | Clipboard | Game-Day General Support | Be a flexible extra hand on game days wherever the team needs help. |
| 10 | Camera | Communications | Support team photos, social media posts, or website updates. |
| 11 | HeartHandshake | General Volunteer | Not sure where to plug in? Tell us a bit about yourself and we'll find a fit. |

Card #7 (Joining a Committee) is the only one that links somewhere. Wrap it in a Next `<Link href="/boosters/committees">` and add a subtle `ArrowUpRight` icon in the top-right corner of the card to signal it's clickable. Other cards are static — they're descriptive, the Sign Up button is the action.

### 4. Closing prose section
- White background, container-constrained, max-w-3xl
- Paragraphs verbatim:

> You do not need to have a specific skill or a large amount of time to help. Some roles take planning and coordination, while others may only take a quick pickup or a short shift. What matters most is that our players see their community showing up for them.

> When you volunteer with McNeil Football, you are helping feed the team, support the coaches, celebrate the players, and build the kind of football experience our athletes will remember long after the season ends.

> Your time matters. Your help is appreciated. And every volunteer makes McNeil Football stronger.

### 5. Bottom CTA band — NAVY
- Background: `bg-mavs-navy text-white`
- Centered content
- Headline: "Ready to Help?" (text-3xl md:text-4xl, font-bold)
- Subhead: "Fill out the volunteer interest form and we'll be in touch."
- Button: "SIGN UP →" — `bg-mavs-green text-white`, links to `VOLUNTEER_FORM_URL`

Same green-on-navy CTA pattern as `/boosters/sponsor` bottom CTA.

## Data
Hardcoded array of opportunity objects in the page component. No DB table. No migration. If the list grows or needs admin editing later, lift to Supabase then.

## Components
- New page: `app/boosters/volunteer/page.tsx`
- Reuse: existing nav/footer, container utilities, lucide-react icons
- No new shared components needed unless CC sees a clean lift opportunity

## SEO
- Page title: "Volunteer | McNeil Mavericks Football Booster Club"
- Meta description: "Volunteer with the McNeil Football Booster Club. Help feed the team, support coaches, run events, and more."

## Accessibility
- Hero button has visible focus ring
- All icons are decorative — wrap in `aria-hidden="true"`
- Card #7 link has accessible name (the title text is the link text)
- External form links open in new tab — include `rel="noopener"`

## Out of scope for v1
- SignUp Genius integration of any kind
- Per-opportunity detail pages
- Calendar of volunteer slots
- Admin dashboard for form responses (Google Sheet behind the Form is enough)
- Listing individual committees on this page (lives on /boosters/committees, single source of truth)

## Acceptance criteria
- [ ] `/boosters/volunteer` returns 200
- [ ] Header dropdown "Volunteer" link no longer 404s
- [ ] `/boosters/committees` bottom CTA lands on the live page
- [ ] Hero band renders green with logo + title + Sign Up button (navy)
- [ ] All 11 opportunity cards render in the specified order with correct icons and copy
- [ ] Card #7 (Joining a Committee) links to `/boosters/committees`; other cards are non-interactive
- [ ] Both Sign Up buttons link to `VOLUNTEER_FORM_URL` and open in new tab
- [ ] Bottom CTA band renders navy with green Sign Up button
- [ ] Mobile: hero stacks vertically, cards collapse to 1 col, prose stays readable
- [ ] No console errors, no a11y violations on Lighthouse
