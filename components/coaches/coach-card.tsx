import ReactMarkdown from "react-markdown";
import remarkGfm from "remark-gfm";

import type { Coach } from "@/lib/types";

export function CoachCard({ coach }: { coach: Coach }) {
  const bio = (coach.bio ?? "").trim();
  const hasContact = Boolean(coach.email) || Boolean(coach.phone);

  return (
    <article className="flex h-full flex-col overflow-hidden rounded-lg border border-border bg-white">
      <div className="aspect-square w-full">
        {coach.photo_url ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img
            src={coach.photo_url}
            alt={`${coach.name}, ${coach.role}`}
            className="h-full w-full object-cover"
          />
        ) : (
          // No headshot yet: show the Mavericks logo instead of a blank/initials block.
          <div className="flex h-full w-full items-center justify-center bg-white p-8">
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img
              src="/brand/mhs-horseshoe.jpg"
              alt=""
              aria-hidden="true"
              className="max-h-full max-w-full object-contain"
            />
          </div>
        )}
      </div>

      <div className="flex flex-1 flex-col p-5">
        <h3 className="text-lg font-semibold tracking-tight">{coach.name}</h3>
        <p className="mt-1 text-sm text-muted-foreground">{coach.role}</p>
        {coach.teaching_role ? (
          <p className="text-xs text-muted-foreground">{coach.teaching_role}</p>
        ) : null}

        {hasContact ? (
          <div className="mt-3 flex flex-wrap gap-x-4 gap-y-1 text-sm">
            {coach.email ? (
              <a
                href={`mailto:${coach.email}`}
                className="text-mavs-green hover:underline"
              >
                {coach.email}
              </a>
            ) : null}
            {coach.phone ? (
              <a
                href={`tel:${coach.phone}`}
                className="text-mavs-green hover:underline"
              >
                {coach.phone}
              </a>
            ) : null}
          </div>
        ) : null}

        {bio ? (
          <div className="mt-3 text-sm leading-6 [&_h1]:text-base [&_h1]:font-semibold [&_h1]:mt-3 [&_h1]:mb-1 [&_h2]:text-base [&_h2]:font-semibold [&_h2]:mt-3 [&_h2]:mb-1 [&_h3]:font-semibold [&_h3]:mt-2 [&_h3]:mb-1 [&_p]:mb-2 [&_ul]:list-disc [&_ul]:pl-5 [&_ul]:mb-2 [&_ol]:list-decimal [&_ol]:pl-5 [&_ol]:mb-2 [&_a]:text-mavs-green [&_a]:underline">
            <ReactMarkdown remarkPlugins={[remarkGfm]}>{bio}</ReactMarkdown>
          </div>
        ) : null}
      </div>
    </article>
  );
}
