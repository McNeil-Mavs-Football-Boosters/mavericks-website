import { CoachCard } from "@/components/coaches/coach-card";
import { HeadCoachPlaceholder } from "@/components/coaches/head-coach-placeholder";
import { getCoachesForYear } from "@/lib/queries/coaches";
import { getSiteSettingsCore } from "@/lib/site-settings";
import type { Coach } from "@/lib/types";

export const dynamic = "force-dynamic";

type RoleCategory = Coach["role_category"];

const SECTION_ORDER: ReadonlyArray<{ key: RoleCategory; heading: string }> = [
  { key: "head", heading: "Head Coach" },
  { key: "coordinator", heading: "Coordinators" },
  { key: "position_coach", heading: "Position Coaches" },
  { key: "trainer", heading: "Trainers" },
  { key: "staff", heading: "Staff" },
];

export default async function CoachesPage() {
  const { current_year } = await getSiteSettingsCore();
  const coaches = await getCoachesForYear(current_year);

  const grouped = new Map<RoleCategory, Coach[]>();
  for (const coach of coaches) {
    const bucket = grouped.get(coach.role_category);
    if (bucket) {
      bucket.push(coach);
    } else {
      grouped.set(coach.role_category, [coach]);
    }
  }

  return (
    <div className="mx-auto max-w-6xl px-4 sm:px-6 lg:px-8 py-8 sm:py-12">
      <header>
        <h1 className="text-3xl font-bold tracking-tight sm:text-4xl">
          Coaches & Trainers
        </h1>
        <p className="mt-2 text-sm text-muted-foreground">{current_year}</p>
      </header>

      <div className="mt-8 space-y-10">
        {SECTION_ORDER.map(({ key, heading }) => {
          const rows = grouped.get(key) ?? [];

          if (key === "head") {
            // Head Coach: always render heading; show placeholder when empty.
            return (
              <section key={key}>
                <h2 className="text-xl font-semibold tracking-tight">
                  {heading}
                </h2>
                <div className="mt-4 grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                  {rows.length === 0 ? (
                    <HeadCoachPlaceholder />
                  ) : (
                    rows.map((coach) => (
                      <CoachCard key={coach.id} coach={coach} />
                    ))
                  )}
                </div>
              </section>
            );
          }

          // Other sections: hide entirely if empty.
          if (rows.length === 0) return null;

          return (
            <section key={key}>
              <h2 className="text-xl font-semibold tracking-tight">{heading}</h2>
              <div className="mt-4 grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                {rows.map((coach) => (
                  <CoachCard key={coach.id} coach={coach} />
                ))}
              </div>
            </section>
          );
        })}
      </div>
    </div>
  );
}
