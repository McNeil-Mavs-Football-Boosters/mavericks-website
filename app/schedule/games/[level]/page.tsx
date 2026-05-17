import { notFound } from "next/navigation";
import { ExternalLink } from "lucide-react";

import { getSiteSettingsCore } from "@/lib/site-settings";

const LEVEL_TITLES: Record<string, string> = {
  varsity: "Varsity",
  jv: "JV",
};

export default async function GameSchedulePage({
  params,
}: {
  params: Promise<{ level: string }>;
}) {
  const { level } = await params;
  const levelTitle = LEVEL_TITLES[level];
  if (!levelTitle) notFound();

  const { current_year, maxpreps_team_url } = await getSiteSettingsCore();

  return (
    <section>
      <header className="mb-6">
        <h1 className="text-3xl font-bold tracking-tight sm:text-4xl">
          {current_year} {levelTitle} Game Schedule
        </h1>
        {maxpreps_team_url ? (
          <p className="mt-2 text-sm">
            <a
              href={maxpreps_team_url}
              target="_blank"
              rel="noopener noreferrer"
              className="text-mavs-green hover:underline"
            >
              Live scores and stats →
            </a>
          </p>
        ) : null}
      </header>

      <div className="rounded-lg border border-border bg-white p-8 text-center">
        <p className="text-foreground">
          {levelTitle} game schedule coming soon. Check MaxPreps for current
          details.
        </p>
        {maxpreps_team_url ? (
          <div className="mt-6">
            <a
              href={maxpreps_team_url}
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex items-center gap-2 rounded-md bg-mavs-green px-4 py-2 text-sm font-medium text-white hover:bg-mavs-green-dark"
            >
              MaxPreps
              <ExternalLink className="h-4 w-4" />
            </a>
          </div>
        ) : null}
      </div>
    </section>
  );
}
