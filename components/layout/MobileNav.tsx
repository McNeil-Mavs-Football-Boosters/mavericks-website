"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { ChevronDown, X } from "lucide-react";

interface MobileNavProps {
  open: boolean;
  onClose: () => void;
}

const TOP_LINK_CLASS =
  "text-lg font-medium py-3 border-b border-border last:border-b-0 text-foreground hover:text-mavs-green";

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

export function MobileNav({ open, onClose }: MobileNavProps) {
  const [boostersOpen, setBoostersOpen] = useState(false);

  useEffect(() => {
    if (!open) return;

    const handleKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") onClose();
    };

    document.addEventListener("keydown", handleKey);
    const previousOverflow = document.body.style.overflow;
    document.body.style.overflow = "hidden";

    // Reset Boosters accordion to collapsed when the drawer closes — done in
    // cleanup so we're not calling setState in the effect body.
    return () => {
      document.removeEventListener("keydown", handleKey);
      document.body.style.overflow = previousOverflow;
      setBoostersOpen(false);
    };
  }, [open, onClose]);

  if (!open) return null;

  return (
    <>
      <div
        className="fixed inset-0 bg-black/40 z-50"
        onClick={onClose}
        aria-hidden="true"
      />
      <div className="fixed inset-y-0 right-0 w-full max-w-xs bg-white p-6 shadow-xl z-50 flex flex-col overflow-y-auto">
        <div className="flex justify-end">
          <button
            type="button"
            aria-label="Close menu"
            onClick={onClose}
            className="inline-flex items-center justify-center p-2 text-foreground hover:text-mavs-green"
          >
            <X className="h-6 w-6" />
          </button>
        </div>
        <nav className="mt-4 flex flex-col">
          <Link href="/" onClick={onClose} className={TOP_LINK_CLASS}>
            Home
          </Link>
          <Link href="/schedule" onClick={onClose} className={TOP_LINK_CLASS}>
            Schedule
          </Link>
          <Link href="/roster" onClick={onClose} className={TOP_LINK_CLASS}>
            Roster
          </Link>
          <Link href="/coaches" onClick={onClose} className={TOP_LINK_CLASS}>
            Coaches &amp; Trainers
          </Link>
          <Link href="/news" onClick={onClose} className={TOP_LINK_CLASS}>
            News
          </Link>
          <Link href="/sponsors" onClick={onClose} className={TOP_LINK_CLASS}>
            Sponsors
          </Link>
          <Link href="/resources" onClick={onClose} className={TOP_LINK_CLASS}>
            For Parents &amp; Athletes
          </Link>

          <button
            type="button"
            aria-expanded={boostersOpen}
            onClick={() => setBoostersOpen((v) => !v)}
            className={`${TOP_LINK_CLASS} flex items-center justify-between w-full text-left`}
          >
            <span>Boosters</span>
            <ChevronDown
              className={`h-5 w-5 transition-transform ${boostersOpen ? "rotate-180" : ""}`}
            />
          </button>
          {boostersOpen ? (
            <div className="flex flex-col pl-4 border-b border-border">
              {BOOSTER_LINKS.map((link) => (
                <Link
                  key={link.href}
                  href={link.href}
                  onClick={onClose}
                  className="text-base font-medium py-2 text-muted-foreground hover:text-mavs-green"
                >
                  {link.label}
                </Link>
              ))}
            </div>
          ) : null}

          <Link href="/about" onClick={onClose} className={TOP_LINK_CLASS}>
            About
          </Link>
        </nav>
      </div>
    </>
  );
}
