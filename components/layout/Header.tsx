"use client";

import { useEffect, useRef, useState } from "react";
import Link from "next/link";
import { ChevronDown, Menu } from "lucide-react";
import { MobileNav } from "@/components/layout/MobileNav";

const BOOSTER_LINKS: { href: string; label: string }[] = [
  { href: "/boosters", label: "About the Booster Club" },
  { href: "/boosters/join", label: "Join" },
  { href: "/boosters/members", label: "Members" },
  { href: "/boosters/sponsor", label: "Sponsorship Opportunities" },
  { href: "/boosters/volunteer", label: "Volunteer" },
  { href: "/boosters/committees", label: "Committees" },
  { href: "/boosters/board", label: "Board" },
  { href: "/boosters/events", label: "Calendar / Events" },
  { href: "/boosters/documents", label: "Documents" },
  { href: "/boosters/donate", label: "Donate" },
];

export function Header() {
  const [mobileOpen, setMobileOpen] = useState(false);
  const [boostersOpen, setBoostersOpen] = useState(false);
  const containerRef = useRef<HTMLDivElement | null>(null);

  useEffect(() => {
    if (!boostersOpen) return;

    const handleClickOutside = (e: MouseEvent) => {
      if (
        containerRef.current &&
        !containerRef.current.contains(e.target as Node)
      ) {
        setBoostersOpen(false);
      }
    };

    const handleKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") setBoostersOpen(false);
    };

    document.addEventListener("mousedown", handleClickOutside);
    document.addEventListener("keydown", handleKey);

    return () => {
      document.removeEventListener("mousedown", handleClickOutside);
      document.removeEventListener("keydown", handleKey);
    };
  }, [boostersOpen]);

  return (
    <header className="sticky top-0 z-40 w-full bg-white border-b border-border">
      <div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 flex h-16 items-center justify-between">
        <Link href="/" className="font-semibold text-mavs-green">
          <span className="hidden md:inline">McNeil Mavericks Football</span>
          <span className="inline md:hidden">Mavs Football</span>
        </Link>

        <nav className="hidden lg:flex items-center gap-4 lg:gap-6">
          <Link
            href="/"
            className="text-sm font-medium text-foreground hover:text-mavs-green transition-colors"
          >
            Home
          </Link>
          <Link
            href="/schedule"
            className="text-sm font-medium text-foreground hover:text-mavs-green transition-colors"
          >
            Schedule
          </Link>
          <Link
            href="/roster"
            className="text-sm font-medium text-foreground hover:text-mavs-green transition-colors"
          >
            Roster
          </Link>
          <Link
            href="/coaches"
            className="text-sm font-medium text-foreground hover:text-mavs-green transition-colors"
          >
            Coaches &amp; Trainers
          </Link>
          <Link
            href="/news"
            className="text-sm font-medium text-foreground hover:text-mavs-green transition-colors"
          >
            News
          </Link>
          <Link
            href="/sponsors"
            className="text-sm font-medium text-foreground hover:text-mavs-green transition-colors"
          >
            Sponsors
          </Link>
          <Link
            href="/resources"
            className="text-sm font-medium text-foreground hover:text-mavs-green transition-colors"
          >
            For Parents &amp; Athletes
          </Link>

          <div ref={containerRef} className="relative">
            <button
              type="button"
              aria-haspopup="menu"
              aria-expanded={boostersOpen}
              onClick={() => setBoostersOpen((v) => !v)}
              className="inline-flex items-center gap-1 text-sm font-medium text-foreground hover:text-mavs-green transition-colors"
            >
              Boosters
              <ChevronDown
                className={`h-4 w-4 transition-transform ${
                  boostersOpen ? "rotate-180" : ""
                }`}
              />
            </button>
            {boostersOpen ? (
              <div
                role="menu"
                className="absolute right-0 mt-2 w-64 rounded-md border border-border bg-white shadow-lg py-2 z-50"
              >
                {BOOSTER_LINKS.map((link) => (
                  <Link
                    key={link.href}
                    href={link.href}
                    role="menuitem"
                    onClick={() => setBoostersOpen(false)}
                    className="block px-4 py-2 text-sm text-foreground hover:bg-muted hover:text-mavs-green"
                  >
                    {link.label}
                  </Link>
                ))}
              </div>
            ) : null}
          </div>

          <Link
            href="/about"
            className="text-sm font-medium text-foreground hover:text-mavs-green transition-colors"
          >
            About
          </Link>
        </nav>

        <button
          type="button"
          aria-label="Open menu"
          className="lg:hidden inline-flex items-center justify-center p-2 text-foreground hover:text-mavs-green"
          onClick={() => setMobileOpen(true)}
        >
          <Menu className="h-6 w-6" />
        </button>
      </div>

      <MobileNav open={mobileOpen} onClose={() => setMobileOpen(false)} />
    </header>
  );
}
