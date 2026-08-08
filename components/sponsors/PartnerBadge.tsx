import { publicStorageUrl } from "@/lib/storage";

export type PartnerBadgeItem = {
  id: string;
  name: string;
  logo_url: string | null;
  website_url: string | null;
};

/**
 * A Community Partner on /boosters/donate: logo, or the business name when we
 * don't have one.
 *
 * ⚠️ The name fallback is the whole point of this component existing rather than
 * reusing SponsorStripLogo. That component (and SponsorCard on /sponsors) both
 * `return null` when logo_url is empty — fine for paying sponsors, who always
 * supply artwork, but partners are exactly the group most likely to have no
 * usable logo (a taqueria donating meals, a shop giving gift cards). Reusing it
 * would mean adding a partner and silently seeing nothing appear.
 *
 * No tagline or description is rendered, deliberately: name + logo + link is
 * acknowledgment for a 501(c)(3); promotional copy would be advertising.
 */
export function PartnerBadge({ partner }: { partner: PartnerBadgeItem }) {
  const logoSrc = partner.logo_url
    ? publicStorageUrl(partner.logo_url, "sponsor-logos")
    : null;

  const inner = logoSrc ? (
    /* eslint-disable-next-line @next/next/no-img-element */
    <img
      src={logoSrc}
      alt={partner.name}
      // Height is the binding constraint for the wide logos and width for the
      // near-square ones (Chicoine). 80px keeps the heavy colour-block marks
      // (Jack Allen's, Mighty Fine, Phil's, The League) from dominating while
      // still leaving Chicoine's thin linework and Tony C's second line legible.
      className="max-h-20 max-w-[min(200px,100%)] w-auto h-auto object-contain"
    />
  ) : (
    // Matched to the logo box so a name-only partner occupies the same cell and
    // the grid doesn't go ragged.
    <span className="flex items-center justify-center max-h-20 min-h-20 max-w-[min(200px,100%)] px-3 text-center text-base font-bold uppercase tracking-wide text-mavs-navy">
      {partner.name}
    </span>
  );

  return partner.website_url ? (
    <a
      href={partner.website_url}
      target="_blank"
      rel="noopener noreferrer"
      className="hover:opacity-80 transition-opacity"
      aria-label={`Visit ${partner.name}`}
    >
      {inner}
    </a>
  ) : (
    inner
  );
}
