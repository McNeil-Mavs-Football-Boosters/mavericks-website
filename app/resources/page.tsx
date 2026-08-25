import { ResourceSection } from "@/components/resources/resource-section";
import { CLEAR_BAG_POLICY_URL } from "@/lib/constants";
import { getCurrentMavMail } from "@/lib/mavmail";
import { getResourceLinks } from "@/lib/queries/resource-links";
import type { ResourceLink } from "@/lib/types";

export const dynamic = "force-dynamic";

type SectionKey = ResourceLink["section"];

// "Stadiums & Directions" was retired in migration 147: every game on the site
// now carries its own verified map pin, so a hand-maintained list of three
// stadiums was strictly worse than the link sitting next to the game — and two
// of its three entries were already stale.
const SECTION_ORDER: ReadonlyArray<{ key: SectionKey; heading: string }> = [
  { key: "registration_forms", heading: "Registration & Forms" },
  { key: "communications", heading: "News & Communications" },
  { key: "resources", heading: "Resources" },
  { key: "other", heading: "Other" },
];

const RENDERED_SECTIONS = new Set<SectionKey>(SECTION_ORDER.map((s) => s.key));

/**
 * The clear bag policy, rendered as a normal Resources entry.
 *
 * It is NOT a resource_links row on purpose: the same URL is on both games pages
 * (lib/constants.ts), and a second copy in the database is the drift trap this
 * project keeps paying for. Deriving the entry from the constant keeps one
 * source and still gives it a real card instead of the footnote it used to be
 * under Stadiums.
 */
function clearBagPolicyLink(): ResourceLink {
  return {
    id: "clear-bag-policy",
    section: "resources",
    label: "Clear Bag Policy",
    url: CLEAR_BAG_POLICY_URL,
    description:
      "What you can and cannot bring into RRISD stadiums on game night.",
    icon_hint: "external",
    sort_order: 3,
    active: true,
  };
}

/**
 * "This Week's Mav Mail", pointing at the current issue.
 *
 * Synthesised the same way as clearBagPolicyLink above rather than stored as a
 * resource_links row, because the URL CHANGES EVERY WEEK — a database row would
 * be stale by the following Sunday and someone would have to remember to edit
 * it. See lib/mavmail.ts for how the slug is built and why it is verified.
 *
 * Returns null when no issue resolves, and the caller then renders nothing. The
 * durable "Subscribe to Mav Mail" row is a real database row and is always
 * there, so losing this entry degrades to "subscribe" rather than to nothing.
 */
function mavMailLink(issue: { url: string; issueLabel: string }): ResourceLink {
  return {
    id: "mavmail-current",
    section: "communications",
    label: "This Week's Mav Mail",
    url: issue.url,
    description: `RRISD's newsletter for McNeil — issue of ${issue.issueLabel}. Football ticket links are published here first.`,
    icon_hint: "external",
    // Above the Subscribe row (-4), so the current issue reads first.
    sort_order: -6,
    active: true,
  };
}

export default async function ResourcesPage() {
  // Both are independent reads; the Mav Mail probe must never delay the page it
  // decorates, and it is fetch-cached for an hour inside getCurrentMavMail.
  const [links, mavMail] = await Promise.all([
    getResourceLinks(),
    getCurrentMavMail(),
  ]);

  const grouped = new Map<SectionKey, ResourceLink[]>();
  // A link whose section is no longer rendered (e.g. a stray 'stadiums' row
  // added after migration 147) falls into "Other" rather than disappearing.
  // Silently dropping a link someone deliberately added is the worse failure.
  const synthesised: ResourceLink[] = [clearBagPolicyLink()];
  if (mavMail) synthesised.push(mavMailLink(mavMail));

  for (const link of [...links, ...synthesised]) {
    const section = RENDERED_SECTIONS.has(link.section) ? link.section : "other";
    const bucket = grouped.get(section);
    if (bucket) {
      bucket.push(link);
    } else {
      grouped.set(section, [link]);
    }
  }

  return (
    <div className="mx-auto max-w-5xl px-4 sm:px-6 lg:px-8 py-8 sm:py-12">
      <header>
        <h1 className="text-3xl font-black uppercase tracking-tight sm:text-4xl">
          Forms & Links
        </h1>
        <p className="mt-2 text-sm text-muted-foreground">
          Forms, links, and resources for the McNeil Mavericks football community
        </p>
      </header>

      {links.length === 0 ? (
        <div className="mt-8 rounded-lg border border-border bg-white p-8 text-center">
          <p className="text-foreground">
            Resources coming soon. Contact boosters@mcneilmavericks.org with questions.
          </p>
        </div>
      ) : (
        <div className="mt-8 space-y-10">
          {SECTION_ORDER.map(({ key, heading }) => (
            <ResourceSection
              key={key}
              heading={heading}
              links={grouped.get(key) ?? []}
            />
          ))}
        </div>
      )}
    </div>
  );
}
