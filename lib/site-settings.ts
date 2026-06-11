import "server-only";
import { cache } from "react";

import { createServerClient } from "@/lib/supabase/server";

export type SiteSettingsCore = {
  current_year: string;
  current_board_year: string;
  current_coaches_year: string;
  current_schedule_year: string;
  maxpreps_team_url: string | null;
  freshman_has_blue: boolean;
};

const DEFAULTS: SiteSettingsCore = {
  current_year: "2025-26",
  current_board_year: "2026-27",
  current_coaches_year: "2026-27",
  current_schedule_year: "2025-26",
  maxpreps_team_url:
    "https://www.maxpreps.com/tx/austin/mcneil-mavericks/football/",
  freshman_has_blue: false,
};

export const getSiteSettingsCore = cache(
  async (): Promise<SiteSettingsCore> => {
    const supabase = createServerClient();
    const { data, error } = await supabase
      .from("site_settings")
      .select(
        "current_year, current_board_year, current_coaches_year, current_schedule_year, maxpreps_team_url, freshman_has_blue",
      )
      .eq("id", 1)
      .single<SiteSettingsCore>();

    if (error || !data) {
      console.error(
        "[site-settings] missing site_settings row, falling back to defaults",
        error,
      );
      return DEFAULTS;
    }
    return data;
  },
);
