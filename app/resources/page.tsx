import { ResourceSection } from "@/components/resources/resource-section";
import { getResourceLinks } from "@/lib/queries/resource-links";
import type { ResourceLink } from "@/lib/types";

export const dynamic = "force-dynamic";

type SectionKey = ResourceLink["section"];

const SECTION_ORDER: ReadonlyArray<{ key: SectionKey; heading: string }> = [
  { key: "registration_forms", heading: "Registration & Forms" },
  { key: "communications", heading: "News and Communications" },
  { key: "resources", heading: "Resources" },
  { key: "stadiums", heading: "Stadiums & Directions" },
  { key: "other", heading: "Other" },
];

export default async function ResourcesPage() {
  const links = await getResourceLinks();

  const grouped = new Map<SectionKey, ResourceLink[]>();
  for (const link of links) {
    const bucket = grouped.get(link.section);
    if (bucket) {
      bucket.push(link);
    } else {
      grouped.set(link.section, [link]);
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
