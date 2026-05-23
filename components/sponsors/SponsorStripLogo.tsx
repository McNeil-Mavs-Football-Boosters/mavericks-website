import { publicStorageUrl } from "@/lib/storage";

export type SponsorStripLogoSponsor = {
  id: string;
  name: string;
  logo_url: string | null;
  website_url: string | null;
};

export function SponsorStripLogo({
  sponsor,
  sizeClass,
}: {
  sponsor: SponsorStripLogoSponsor;
  sizeClass: string;
}) {
  const logoSrc = sponsor.logo_url
    ? publicStorageUrl(sponsor.logo_url, "sponsor-logos")
    : null;
  if (!logoSrc) return null;
  const inner = (
    /* eslint-disable-next-line @next/next/no-img-element */
    <img
      src={logoSrc}
      alt={sponsor.name}
      className={`${sizeClass} w-auto h-auto object-contain`}
    />
  );
  return sponsor.website_url ? (
    <a
      href={sponsor.website_url}
      target="_blank"
      rel="noopener noreferrer"
      className="hover:opacity-80 transition-opacity"
      aria-label={`Visit ${sponsor.name}`}
    >
      {inner}
    </a>
  ) : (
    inner
  );
}
