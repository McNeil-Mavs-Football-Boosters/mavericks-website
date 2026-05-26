import type { ReactNode } from "react";

import type { ResourceLink } from "@/lib/types";

import { ResourceItem } from "./resource-item";

export function ResourceSection({
  heading,
  links,
  footer,
}: {
  heading: string;
  links: ResourceLink[];
  footer?: ReactNode;
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
      {footer}
    </section>
  );
}
