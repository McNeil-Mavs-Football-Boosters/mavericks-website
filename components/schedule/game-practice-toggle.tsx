"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";

import { cn } from "@/lib/utils";

type ToggleState = {
  level: string;
  type: "games" | "practice";
};

function parsePath(pathname: string): ToggleState | null {
  // Expected shapes:
  //   /schedule/games/[level]
  //   /schedule/games/freshman/[green|blue]
  //   /schedule/practice/[level]
  const parts = pathname.split("/").filter(Boolean);
  if (parts.length < 3 || parts[0] !== "schedule") return null;

  const type = parts[1];
  const level = parts[2];
  if (!level) return null;
  if (type === "games") return { level, type: "games" };
  if (type === "practice") return { level, type: "practice" };
  return null;
}

export function GamePracticeToggle() {
  const pathname = usePathname();
  const state = parsePath(pathname ?? "");
  if (!state) return null;

  const { level, type } = state;
  const gameHref = `/schedule/games/${level}${
    level === "freshman" ? "/green" : ""
  }`;
  const practiceHref = `/schedule/practice/${level}`;

  const isGame = type === "games";

  return (
    <div className="flex flex-wrap items-center gap-x-4 gap-y-3 rounded-lg border border-mavs-navy/20 bg-mavs-navy/5 px-3 py-3 sm:px-4">
      <span className="text-xs font-bold uppercase tracking-widest text-mavs-navy/70">
        Viewing
      </span>
      <div
        role="tablist"
        aria-label="Game or practice schedule"
        className="inline-flex rounded-full border-2 border-mavs-navy bg-white p-1 shadow-sm"
      >
        <ToggleButton
          href={gameHref}
          active={isGame}
          label="Game"
        />
        <ToggleButton
          href={practiceHref}
          active={!isGame}
          label="Practice"
        />
      </div>
    </div>
  );
}

function ToggleButton({
  href,
  active,
  label,
}: {
  href: string;
  active: boolean;
  label: string;
}) {
  return (
    <Link
      href={href}
      role="tab"
      aria-current={active ? "page" : undefined}
      aria-selected={active}
      className={cn(
        "inline-flex h-10 min-w-28 items-center justify-center rounded-full px-6 text-sm font-black uppercase tracking-wide transition-colors",
        active
          ? "bg-mavs-navy text-white shadow"
          : "bg-transparent text-mavs-navy hover:bg-mavs-navy/15",
      )}
    >
      {label}
    </Link>
  );
}
