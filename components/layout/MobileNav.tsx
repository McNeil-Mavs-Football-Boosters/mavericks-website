"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { ChevronDown, X } from "lucide-react";

import {
  buildRosterLinks,
  buildScheduleLinks,
  type NavLink,
} from "@/components/layout/teamLinks";

interface MobileNavProps {
  open: boolean;
  onClose: () => void;
  freshmanHasBlue: boolean;
}

const TOP_LINK_CLASS =
  "text-lg font-medium py-3 border-b border-border last:border-b-0 text-foreground hover:text-mavs-green";

const BOOSTER_LINKS: NavLink[] = [
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

type AccordionName = "schedule" | "roster" | "boosters";

export function MobileNav({ open, onClose, freshmanHasBlue }: MobileNavProps) {
  const [openAccordion, setOpenAccordion] = useState<AccordionName | null>(
    null,
  );

  useEffect(() => {
    if (!open) return;

    const handleKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") onClose();
    };

    document.addEventListener("keydown", handleKey);
    const previousOverflow = document.body.style.overflow;
    document.body.style.overflow = "hidden";

    return () => {
      document.removeEventListener("keydown", handleKey);
      document.body.style.overflow = previousOverflow;
      setOpenAccordion(null);
    };
  }, [open, onClose]);

  if (!open) return null;

  const toggle = (name: AccordionName) =>
    setOpenAccordion((current) => (current === name ? null : name));

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

          <MobileNavAccordion
            label="Schedule"
            links={buildScheduleLinks(freshmanHasBlue)}
            isOpen={openAccordion === "schedule"}
            onToggle={() => toggle("schedule")}
            onItemClick={onClose}
          />

          <MobileNavAccordion
            label="Roster"
            links={buildRosterLinks(freshmanHasBlue)}
            isOpen={openAccordion === "roster"}
            onToggle={() => toggle("roster")}
            onItemClick={onClose}
          />

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

          <MobileNavAccordion
            label="Boosters"
            links={BOOSTER_LINKS}
            isOpen={openAccordion === "boosters"}
            onToggle={() => toggle("boosters")}
            onItemClick={onClose}
          />

          <Link href="/about" onClick={onClose} className={TOP_LINK_CLASS}>
            About
          </Link>
        </nav>
      </div>
    </>
  );
}

function MobileNavAccordion({
  label,
  links,
  isOpen,
  onToggle,
  onItemClick,
}: {
  label: string;
  links: NavLink[];
  isOpen: boolean;
  onToggle: () => void;
  onItemClick: () => void;
}) {
  return (
    <>
      <button
        type="button"
        aria-expanded={isOpen}
        onClick={onToggle}
        className={`${TOP_LINK_CLASS} flex items-center justify-between w-full text-left`}
      >
        <span>{label}</span>
        <ChevronDown
          className={`h-5 w-5 transition-transform ${isOpen ? "rotate-180" : ""}`}
        />
      </button>
      {isOpen ? (
        <div className="flex flex-col pl-4 border-b border-border">
          {links.map((link) => (
            <Link
              key={link.href}
              href={link.href}
              onClick={onItemClick}
              className="text-base font-medium py-2 text-muted-foreground hover:text-mavs-green"
            >
              {link.label}
            </Link>
          ))}
        </div>
      ) : null}
    </>
  );
}
