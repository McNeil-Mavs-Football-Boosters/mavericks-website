"use client";

import { useEffect } from "react";
import Link from "next/link";
import { X } from "lucide-react";

interface MobileNavProps {
  open: boolean;
  onClose: () => void;
}

export function MobileNav({ open, onClose }: MobileNavProps) {
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
      <div className="fixed inset-y-0 right-0 w-full max-w-xs bg-white p-6 shadow-xl z-50 flex flex-col">
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
          <Link
            href="/"
            onClick={onClose}
            className="text-lg font-medium py-3 border-b border-border last:border-b-0 text-foreground hover:text-mavs-green"
          >
            Home
          </Link>
          <Link
            href="/about"
            onClick={onClose}
            className="text-lg font-medium py-3 border-b border-border last:border-b-0 text-foreground hover:text-mavs-green"
          >
            About
          </Link>
          <Link
            href="/contact"
            onClick={onClose}
            className="text-lg font-medium py-3 border-b border-border last:border-b-0 text-foreground hover:text-mavs-green"
          >
            Contact
          </Link>
        </nav>
      </div>
    </>
  );
}
