"use client";

import { useEffect, useRef, useState } from "react";
import { Apple, Calendar, ChevronDown, Copy } from "lucide-react";

export function SubscribeCalendarButton() {
  const [isOpen, setIsOpen] = useState(false);
  const [copied, setCopied] = useState(false);
  const containerRef = useRef<HTMLDivElement | null>(null);

  // Outside-click + Escape — mirrors components/layout/Header.tsx pattern.
  useEffect(() => {
    if (!isOpen) return;

    const handleClickOutside = (e: MouseEvent) => {
      if (
        containerRef.current &&
        !containerRef.current.contains(e.target as Node)
      ) {
        setIsOpen(false);
      }
    };

    const handleKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") setIsOpen(false);
    };

    document.addEventListener("mousedown", handleClickOutside);
    document.addEventListener("keydown", handleKey);

    return () => {
      document.removeEventListener("mousedown", handleClickOutside);
      document.removeEventListener("keydown", handleKey);
    };
  }, [isOpen]);

  const siteEnvUrl = process.env.NEXT_PUBLIC_SITE_URL;
  const origin =
    siteEnvUrl ?? (typeof window !== "undefined" ? window.location.origin : "");
  const hostNoScheme = origin.replace(/^https?:\/\//, "");
  const icsHttpsUrl = `${origin}/events.ics`;
  const icsWebcalUrl = `webcal://${hostNoScheme}/events.ics`;
  const googleUrl = `https://calendar.google.com/calendar/r?cid=${encodeURIComponent(
    icsWebcalUrl,
  )}`;
  const outlookUrl = `https://outlook.live.com/calendar/0/addcalendar?url=${encodeURIComponent(
    icsHttpsUrl,
  )}`;

  const rowClass =
    "flex items-center gap-3 w-full px-4 py-2 text-sm text-foreground hover:bg-muted hover:text-mavs-navy text-left";

  const handleCopy = async () => {
    try {
      await navigator.clipboard.writeText(icsHttpsUrl);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    } catch (err) {
      console.warn("Clipboard write failed", err);
    }
  };

  return (
    <div ref={containerRef} className="relative">
      <button
        type="button"
        aria-haspopup="menu"
        aria-expanded={isOpen}
        onClick={() => setIsOpen((v) => !v)}
        className="border border-mavs-navy text-mavs-navy bg-white px-4 py-2 rounded inline-flex items-center gap-2 hover:bg-mavs-navy/5"
      >
        Subscribe to calendar
        <ChevronDown className="h-4 w-4" />
      </button>

      {isOpen && origin ? (
        <div
          role="menu"
          className="absolute right-0 mt-2 w-64 rounded-md border border-mavs-navy/20 bg-white shadow-lg py-2 z-50"
        >
          <a
            href={googleUrl}
            target="_blank"
            rel="noopener noreferrer"
            role="menuitem"
            onClick={() => setIsOpen(false)}
            className={rowClass}
          >
            <Calendar className="h-4 w-4" />
            <span>Google Calendar</span>
          </a>
          <a
            href={icsWebcalUrl}
            role="menuitem"
            onClick={() => setIsOpen(false)}
            className={rowClass}
          >
            <Apple className="h-4 w-4" />
            <span>Apple / iCal</span>
          </a>
          <a
            href={outlookUrl}
            target="_blank"
            rel="noopener noreferrer"
            role="menuitem"
            onClick={() => setIsOpen(false)}
            className={rowClass}
          >
            <Calendar className="h-4 w-4" />
            <span>Outlook</span>
          </a>
          <button
            type="button"
            role="menuitem"
            onClick={handleCopy}
            className={rowClass}
          >
            <Copy className="h-4 w-4" />
            <span>Copy ICS URL</span>
            {copied ? (
              <span className="ml-auto text-xs text-mavs-green font-bold">
                Copied!
              </span>
            ) : null}
          </button>
        </div>
      ) : null}
    </div>
  );
}
