import { ScheduleNav } from "@/components/schedule/ScheduleNav";
import { getSiteSettingsCore } from "@/lib/site-settings";

export const revalidate = 60;

export default async function ScheduleLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const { freshman_has_blue } = await getSiteSettingsCore();
  return (
    <>
      <ScheduleNav freshmanHasBlue={freshman_has_blue} />
      <div className="mx-auto max-w-6xl px-4 sm:px-6 lg:px-8 py-8">
        {children}
      </div>
    </>
  );
}
