"use client";

import { useEffect, useMemo, useState, useSyncExternalStore } from "react";

import {
  SponsorStripLogo,
  type SponsorStripLogoSponsor,
} from "@/components/sponsors/SponsorStripLogo";

const VISIBLE = 6;
const INTERVAL_MS = 4000;

/**
 * Homepage sponsor strip: one row, six logos, all the same size.
 *
 * Rotation is a SLIDING WINDOW, not paging. Every tick one logo leaves and one
 * arrives, which is what Jeremy asked for — paging by six would swap the whole
 * row at once and read as a flash rather than a rotation.
 *
 * ── The first sponsor is PINNED ──
 * `sponsors[0]` (ordered by sort_order, so the largest commitment) holds slot 1
 * permanently and the rest cycle through the remaining five slots. This is the
 * answer to the open "does MVP get pinned to page 1" question: a strict window
 * over all sponsors would eventually rotate the biggest supporter off screen,
 * and the sponsorship letter sells the top tier on visibility. Pinning keeps the
 * single-row look while honouring that.
 *
 * ── Behaviour matched to HeroCarousel ──
 * Pauses when the tab is hidden and respects prefers-reduced-motion (rendering
 * a static first window). Deliberately NO pause-on-hover: that feature caused a
 * freeze bug in HeroCarousel (commit 5934640) when the cursor happened to rest
 * over the element after a page load, and it is not worth reintroducing.
 *
 * ── Every logo stays in the DOM ──
 * Off-window logos are hidden with CSS, not unmounted, so crawlers and non-JS
 * visitors still see every sponsor. Sponsors are paying for visibility; they
 * should not be invisible to a search engine because of a rotation.
 */
/**
 * prefers-reduced-motion as an external store.
 *
 * Written this way on purpose: the equivalent in HeroCarousel calls setState
 * synchronously inside an effect, which trips react-hooks/set-state-in-effect
 * and costs an extra render at mount. useSyncExternalStore is the fix that was
 * already identified for that component but never applied. Server snapshot is
 * false so SSR renders the animated (default) markup.
 */
function useReducedMotion(): boolean {
  return useSyncExternalStore(
    (onChange) => {
      const mql = window.matchMedia("(prefers-reduced-motion: reduce)");
      mql.addEventListener("change", onChange);
      return () => mql.removeEventListener("change", onChange);
    },
    () => window.matchMedia("(prefers-reduced-motion: reduce)").matches,
    () => false,
  );
}

export function SponsorCarousel({
  sponsors,
}: {
  sponsors: SponsorStripLogoSponsor[];
}) {
  const rotates = sponsors.length > VISIBLE;
  const [offset, setOffset] = useState(0);
  const reducedMotion = useReducedMotion();

  // Pinned head + rotating tail. The tail cycles through VISIBLE-1 slots.
  const [pinned, ...tail] = sponsors;
  const animate = rotates && !reducedMotion;

  useEffect(() => {
    if (!animate || tail.length === 0) return;
    let id: ReturnType<typeof setInterval> | null = null;
    const start = () => {
      if (id === null) {
        id = setInterval(
          () => setOffset((o) => (o + 1) % tail.length),
          INTERVAL_MS,
        );
      }
    };
    const stop = () => {
      if (id !== null) {
        clearInterval(id);
        id = null;
      }
    };
    const onVisibility = () => (document.hidden ? stop() : start());
    if (!document.hidden) start();
    document.addEventListener("visibilitychange", onVisibility);
    return () => {
      stop();
      document.removeEventListener("visibilitychange", onVisibility);
    };
  }, [animate, tail.length]);

  // The window is simply the first VISIBLE entries of the rotated order, so
  // there is no separate visibility set to keep in sync.
  const ordered = useMemo(() => {
    if (!rotates) return sponsors;
    const rotated = tail.map((_, i) => tail[(offset + i) % tail.length]!);
    return pinned ? [pinned, ...rotated] : rotated;
  }, [rotates, sponsors, pinned, tail, offset]);

  return (
    <div
      className="flex flex-wrap items-center justify-center gap-8 md:gap-12"
      aria-label="Our sponsors"
    >
      {ordered.map((s, i) => {
        const shown = !rotates || i < VISIBLE;
        return (
          <div
            key={s.id}
            // Hidden entries keep their markup for crawlers but must not take
            // layout space or be tabbable, or the row would still be eight wide.
            className={
              shown
                ? "max-w-[200px] max-h-16 flex items-center justify-center transition-opacity duration-700 opacity-100"
                : "hidden"
            }
            aria-hidden={shown ? undefined : true}
          >
            <SponsorStripLogo sponsor={s} sizeClass="max-w-[200px] max-h-16" />
          </div>
        );
      })}
    </div>
  );
}
