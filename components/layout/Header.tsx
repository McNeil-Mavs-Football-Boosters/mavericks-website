"use client";

import { useEffect, useRef, useState } from "react";
import Image from "next/image";
import Link from "next/link";
import { ChevronDown, Menu } from "lucide-react";

import { MobileNav } from "@/components/layout/MobileNav";
import {
  BOOSTER_LINKS,
  buildRosterLinks,
  buildScheduleLinks,
  type NavLink,
} from "@/components/layout/teamLinks";

type DropdownName = "schedule" | "roster" | "boosters";

export function Header({ freshmanHasBlue }: { freshmanHasBlue: boolean }) {
  const [mobileOpen, setMobileOpen] = useState(false);
  const [openDropdown, setOpenDropdown] = useState<DropdownName | null>(null);
  const scheduleRef = useRef<HTMLDivElement | null>(null);
  const rosterRef = useRef<HTMLDivElement | null>(null);
  const boostersRef = useRef<HTMLDivElement | null>(null);

  useEffect(() => {
    if (!openDropdown) return;

    const refs: Record<DropdownName, React.RefObject<HTMLDivElement | null>> = {
      schedule: scheduleRef,
      roster: rosterRef,
      boosters: boostersRef,
    };

    const handleClickOutside = (e: MouseEvent) => {
      const ref = refs[openDropdown];
      if (ref.current && !ref.current.contains(e.target as Node)) {
        setOpenDropdown(null);
      }
    };

    const handleKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") setOpenDropdown(null);
    };

    document.addEventListener("mousedown", handleClickOutside);
    document.addEventListener("keydown", handleKey);

    return () => {
      document.removeEventListener("mousedown", handleClickOutside);
      document.removeEventListener("keydown", handleKey);
    };
  }, [openDropdown]);

  const toggle = (name: DropdownName) =>
    setOpenDropdown((current) => (current === name ? null : name));
  const close = () => setOpenDropdown(null);

  return (
    <header className="sticky top-0 z-40 w-full bg-mavs-navy print:hidden">
      {/* ⚠️ `lg:max-w-[80vw]` IS DROPPED AT xl, WHICH IS WHERE THE DESKTOP NAV
          APPEARS. Measured 2026-08-26: the nav needs ~1030px on one line, and
          the 80vw cap left it ~790px at 1440 -- so "Coaches & Trainers",
          "Booster Club" and "Forms & Links" each broke onto a second line at
          EVERY width from 1280 to 1600, i.e. on essentially every laptop. The
          cap was not aligning the header with anything: 80vw appears nowhere
          else in the app. Below xl the nav is a hamburger and the cap is free,
          so it stays there. */}
      <div className="flex h-16 items-center gap-3 px-4 sm:px-6 lg:px-8 lg:max-w-[80vw] lg:mx-auto xl:max-w-none xl:mx-0 xl:justify-center">
        <Link
          href="/"
          aria-label="McNeil Mavericks Football home"
          className="flex items-center gap-2 shrink-0"
        >
          <Image
            src="/brand/mhs-logo.png"
            alt=""
            width={48}
            height={48}
            priority
            className="h-10 w-10 object-contain rounded-full bg-white p-0.5"
          />
          <span className="font-black uppercase tracking-tight text-white text-sm sm:text-base">
            <span className="hidden md:inline">McNeil Mavericks Football</span>
            <span className="inline md:hidden">Mavs Football</span>
          </span>
        </Link>

        {/* justify-START, not justify-between. `justify-between` spread the items
            edge to edge, which is what produced the very wide gaps Jeremy asked
            to close on 2026-08-26 -- and it got worse with each item added, since
            the leftover width was divided between fewer joins. A fixed gap keeps
            the spacing constant no matter how many items the nav grows to. */}
        <nav className="hidden xl:flex items-center justify-start gap-4 2xl:gap-6 pl-4 2xl:pl-8">
          <HeaderDropdown
            label="Schedule"
            links={buildScheduleLinks(freshmanHasBlue)}
            isOpen={openDropdown === "schedule"}
            onToggle={() => toggle("schedule")}
            onItemClick={close}
            containerRef={scheduleRef}
            align="left"
          />

          <HeaderDropdown
            label="Roster"
            links={buildRosterLinks(freshmanHasBlue)}
            isOpen={openDropdown === "roster"}
            onToggle={() => toggle("roster")}
            onItemClick={close}
            containerRef={rosterRef}
            align="left"
          />

          <Link
            href="/coaches"
            className="whitespace-nowrap text-sm font-bold uppercase tracking-wide text-white hover:text-white/80 transition-colors"
          >
            Coaches &amp; Trainers
          </Link>

          <HeaderDropdown
            label="Booster Club"
            links={BOOSTER_LINKS}
            isOpen={openDropdown === "boosters"}
            onToggle={() => toggle("boosters")}
            onItemClick={close}
            containerRef={boostersRef}
            align="left"
          />

          <Link
            href="/events"
            className="whitespace-nowrap text-sm font-bold uppercase tracking-wide text-white hover:text-white/80 transition-colors"
          >
            Events
          </Link>
          {/* Volunteer is ALSO in BOOSTER_LINKS, on purpose (Jeremy 2026-08-26):
              "we need Volunteer to be it's own ... link in the top header. you can
              leave under booster club too". Recruiting is the club's constant
              need, so it gets a top-level slot instead of being two clicks deep.
              A plain Link rather than a dropdown -- there is exactly one
              destination, and a dropdown with a single child is worse than a
              link. Both entries point at the same route, so nothing can drift. */}
          <Link
            href="/boosters/volunteer"
            className="whitespace-nowrap text-sm font-bold uppercase tracking-wide text-white hover:text-white/80 transition-colors"
          >
            Volunteer
          </Link>
          <Link
            href="/sponsors"
            className="whitespace-nowrap text-sm font-bold uppercase tracking-wide text-white hover:text-white/80 transition-colors"
          >
            Sponsors
          </Link>
          <Link
            href="/resources"
            className="whitespace-nowrap text-sm font-bold uppercase tracking-wide text-white hover:text-white/80 transition-colors"
          >
            Forms &amp; Links
          </Link>
        </nav>

        <button
          type="button"
          aria-label="Open menu"
          className="xl:hidden ml-auto inline-flex items-center justify-center p-2 text-white hover:text-white/80"
          onClick={() => setMobileOpen(true)}
        >
          <Menu className="h-6 w-6" />
        </button>
      </div>

      <MobileNav
        open={mobileOpen}
        onClose={() => setMobileOpen(false)}
        freshmanHasBlue={freshmanHasBlue}
      />
    </header>
  );
}

function HeaderDropdown({
  label,
  links,
  isOpen,
  onToggle,
  onItemClick,
  containerRef,
  align,
}: {
  label: string;
  links: NavLink[];
  isOpen: boolean;
  onToggle: () => void;
  onItemClick: () => void;
  containerRef: React.RefObject<HTMLDivElement | null>;
  align: "left" | "right";
}) {
  const alignClass = align === "right" ? "right-0" : "left-0";
  return (
    <div ref={containerRef} className="relative">
      <button
        type="button"
        aria-haspopup="menu"
        aria-expanded={isOpen}
        onClick={onToggle}
        className="inline-flex items-center gap-1 whitespace-nowrap text-sm font-bold uppercase tracking-wide text-white hover:text-white/80 transition-colors"
      >
        {label}
        <ChevronDown
          className={`h-4 w-4 transition-transform ${
            isOpen ? "rotate-180" : ""
          }`}
        />
      </button>
      {isOpen ? (
        <div
          role="menu"
          // w-max + a min-width so each dropdown sizes to its own longest
          // label instead of wrapping inside a fixed 16rem panel. Roster and
          // Booster Club stay at the 16rem floor; only Schedule grows.
          className={`absolute ${alignClass} mt-2 w-max min-w-[16rem] rounded-md border border-border bg-white shadow-lg py-2 z-50`}
        >
          {links.map((link) => (
            <Link
              key={link.href}
              href={link.href}
              role="menuitem"
              onClick={onItemClick}
              className="block whitespace-nowrap px-4 py-2 text-sm text-foreground hover:bg-muted hover:text-mavs-navy"
            >
              {link.label}
            </Link>
          ))}
        </div>
      ) : null}
    </div>
  );
}
