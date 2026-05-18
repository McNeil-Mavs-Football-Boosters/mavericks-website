import type { ResourceLink } from "@/lib/types";

import { ResourceItem } from "./resource-item";

export function ResourceSection({
  heading,
  links,
}: {
  heading: string;
  links: ResourceLink[];
}) {
  if (links.length === 0) return null;

  return (
    <section>
      <h2 className="text-xl font-bold uppercase tracking-tight">{heading}</h2>
      <ul className="mt-3 divide-y divide-border">
        {links.map((link) => (
          <ResourceItem key={link.id} link={link} />
        ))}
      </ul>
    </section>
  );
}
