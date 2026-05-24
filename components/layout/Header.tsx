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
      <div className="flex h-16 items-center gap-3 px-4 sm:px-6 lg:px-8 lg:max-w-[80vw] lg:mx-auto">
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

        <nav className="hidden xl:flex flex-1 items-center justify-between gap-2 pl-8">
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
            className="text-sm font-bold uppercase tracking-wide text-white hover:text-white/80 transition-colors"
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
            href="/news"
            className="text-sm font-bold uppercase tracking-wide text-white hover:text-white/80 transition-colors"
          >
            News
          </Link>
          <Link
            href="/sponsors"
            className="text-sm font-bold uppercase tracking-wide text-white hover:text-white/80 transition-colors"
          >
            Sponsors
          </Link>
          <Link
            href="/resources"
            className="text-sm font-bold uppercase tracking-wide text-white hover:text-white/80 transition-colors"
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
        className="inline-flex items-center gap-1 text-sm font-bold uppercase tracking-wide text-white hover:text-white/80 transition-colors"
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
          className={`absolute ${alignClass} mt-2 w-64 rounded-md border border-border bg-white shadow-lg py-2 z-50`}
        >
          {links.map((link) => (
            <Link
              key={link.href}
              href={link.href}
              role="menuitem"
              onClick={onItemClick}
              className="block px-4 py-2 text-sm text-foreground hover:bg-muted hover:text-mavs-navy"
            >
              {link.label}
            </Link>
          ))}
        </div>
      ) : null}
    </div>
  );
}
