import Link from "next/link";
import type { ReactNode } from "react";

import { iconForHint } from "@/lib/resource-icons";
import type { ResourceLink } from "@/lib/types";

function isExternal(url: string): boolean {
  if (url.startsWith("http://") || url.startsWith("https://")) return true;
  return !url.startsWith("/");
}

function LinkWrapper({
  url,
  children,
}: {
  url: string;
  children: ReactNode;
}) {
  const className =
    "font-semibold text-mavs-green hover:underline";

  if (isExternal(url)) {
    return (
      <a
        href={url}
        target="_blank"
        rel="noopener noreferrer"
        className={className}
      >
        {children}
      </a>
    );
  }

  return (
    <Link href={url} className={className}>
      {children}
    </Link>
  );
}

export function ResourceItem({ link }: { link: ResourceLink }) {
  const Icon = iconForHint(link.icon_hint);
  const hasDescription =
    link.description != null && link.description.trim() !== "";

  return (
    <li className="flex items-start gap-3 py-2">
      <Icon
        aria-hidden="true"
        className="h-5 w-5 shrink-0 text-mavs-green"
      />
      <div className="min-w-0 flex-1">
        <LinkWrapper url={link.url}>{link.label}</LinkWrapper>
        {hasDescription ? (
          <p className="text-sm text-muted-foreground">{link.description}</p>
        ) : null}
      </div>
    </li>
  );
}
