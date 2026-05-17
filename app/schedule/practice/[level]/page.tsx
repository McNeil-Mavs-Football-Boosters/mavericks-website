import { notFound } from "next/navigation";
import ReactMarkdown from "react-markdown";
import remarkGfm from "remark-gfm";

import { PrintButton } from "@/components/schedule/print-button";
import { PrintFooter } from "@/components/schedule/print-footer";
import { getSiteSettingsCore } from "@/lib/site-settings";
import { createServerClient } from "@/lib/supabase/server";

const LEVEL_TITLES: Record<string, string> = {
  varsity: "Varsity",
  jv: "JV",
  freshman: "Freshman",
};

type PracticeRow = {
  body: string | null;
  source_note: string | null;
};

export default async function PracticeSchedulePage({
  params,
}: {
  params: Promise<{ level: string }>;
}) {
  const { level } = await params;
  const levelTitle = LEVEL_TITLES[level];
  if (!levelTitle) notFound();

  const { current_year, freshman_has_blue } = await getSiteSettingsCore();

  const teamLabel =
    level === "freshman" && freshman_has_blue
      ? "Freshman Green & Blue"
      : levelTitle;

  const supabase = createServerClient();
  const { data } = await supabase
    .from("practice_schedules")
    .select("body, source_note")
    .eq("year", current_year)
    .eq("team_level", level)
    .eq("active", true)
    .limit(1)
    .maybeSingle<PracticeRow>();

  const body = (data?.body ?? "").trim();
  const sourceNote = (data?.source_note ?? "").trim();

  return (
    <section>
      <header className="mb-6 flex items-start justify-between gap-4">
        <h1 className="text-3xl font-bold tracking-tight sm:text-4xl">
          {current_year} {teamLabel} Practice Schedule
        </h1>
        <PrintButton />
      </header>

      {body ? (
        <div className="rounded-lg border border-border bg-white p-6 leading-7 [&_h1]:text-2xl [&_h1]:font-semibold [&_h1]:mt-4 [&_h1]:mb-2 [&_h2]:text-xl [&_h2]:font-semibold [&_h2]:mt-4 [&_h2]:mb-2 [&_h3]:font-semibold [&_h3]:mt-3 [&_h3]:mb-1 [&_p]:mb-3 [&_ul]:list-disc [&_ul]:pl-6 [&_ul]:mb-3 [&_ol]:list-decimal [&_ol]:pl-6 [&_ol]:mb-3 [&_a]:text-mavs-green [&_a]:underline [&_table]:w-full [&_table]:my-3 [&_th]:text-left [&_th]:py-1 [&_td]:py-1 [&_th]:border-b [&_td]:border-b [&_th]:border-border [&_td]:border-border print:[&_a]:text-black print:[&_a]:no-underline">
          <ReactMarkdown remarkPlugins={[remarkGfm]}>{body}</ReactMarkdown>
        </div>
      ) : (
        <div className="rounded-lg border border-border bg-white p-8 text-center">
          <p className="text-foreground">
            {sourceNote || "Practice schedule coming soon."}
          </p>
        </div>
      )}

      <PrintFooter />
    </section>
  );
}
