"use client";

import { Printer } from "lucide-react";

export function PrintButton() {
  return (
    <button
      type="button"
      aria-label="Print this page"
      onClick={() => window.print()}
      className="inline-flex items-center gap-1.5 rounded-md border border-mavs-green px-3 py-1.5 text-sm font-medium text-mavs-green hover:bg-mavs-green/10 print:hidden"
    >
      <Printer className="h-4 w-4" />
      Print
    </button>
  );
}
