import "server-only";

import { createServerClient } from "@/lib/supabase/server";
import type {
  HeroBackgroundImage,
  HeroForegroundTile,
} from "@/lib/types";

export interface HeroCarouselData {
  backgrounds: HeroBackgroundImage[];
  tiles: HeroForegroundTile[];
}

export async function loadHeroCarouselData(): Promise<HeroCarouselData> {
  try {
    const supabase = createServerClient();

    const [backgroundsResult, tilesResult] = await Promise.all([
      supabase
        .from("hero_background_images")
        .select("*")
        .eq("active", true)
        .order("sort_order", { ascending: true })
        .returns<HeroBackgroundImage[]>(),
      supabase
        .from("hero_foreground_tiles")
        .select("*")
        .eq("active", true)
        .order("sort_order", { ascending: true })
        .returns<HeroForegroundTile[]>(),
    ]);

    if (backgroundsResult.error) {
      console.error(
        "[queries/hero] loadHeroCarouselData backgrounds failed",
        backgroundsResult.error,
      );
    }
    if (tilesResult.error) {
      console.error(
        "[queries/hero] loadHeroCarouselData tiles failed",
        tilesResult.error,
      );
    }

    return {
      backgrounds: backgroundsResult.error ? [] : backgroundsResult.data ?? [],
      tiles: tilesResult.error ? [] : tilesResult.data ?? [],
    };
  } catch (err) {
    console.error("[queries/hero] loadHeroCarouselData threw", err);
    return { backgrounds: [], tiles: [] };
  }
}
