import { GamePracticeToggle } from "@/components/schedule/game-practice-toggle";
import { getSiteSettingsCore } from "@/lib/site-settings";

export default async function ScheduleLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  await getSiteSettingsCore();
  return (
    <div className="mx-auto max-w-5xl px-4 sm:px-6 lg:px-8 py-8 sm:py-12">
      <div className="mb-6 print:hidden">
        <GamePracticeToggle />
      </div>
      {children}
    </div>
  );
}
