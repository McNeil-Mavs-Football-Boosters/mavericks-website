"use client";

import { useState } from "react";
import Link from "next/link";
import { Menu } from "lucide-react";
import { MobileNav } from "@/components/layout/MobileNav";

export function Header() {
  const [open, setOpen] = useState(false);

  return (
    <header className="sticky top-0 z-40 w-full bg-white border-b border-border">
      <div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 flex h-16 items-center justify-between">
        <Link href="/" className="font-semibold text-mavs-green">
          <span className="hidden md:inline">
            McNeil Mavericks Football Booster Club
          </span>
          <span className="inline md:hidden">Mavs Boosters</span>
        </Link>

        <nav className="hidden md:flex items-center gap-6">
          <Link
            href="/"
            className="text-sm font-medium text-foreground hover:text-mavs-green transition-colors"
          >
            Home
          </Link>
          <Link
            href="/about"
            className="text-sm font-medium text-foreground hover:text-mavs-green transition-colors"
          >
            About
          </Link>
          <Link
            href="/contact"
            className="text-sm font-medium text-foreground hover:text-mavs-green transition-colors"
          >
            Contact
          </Link>
        </nav>

        <button
          type="button"
          aria-label="Open menu"
          className="md:hidden inline-flex items-center justify-center p-2 text-foreground hover:text-mavs-green"
          onClick={() => setOpen(true)}
        >
          <Menu className="h-6 w-6" />
        </button>
      </div>

      <MobileNav open={open} onClose={() => setOpen(false)} />
    </header>
  );
}
