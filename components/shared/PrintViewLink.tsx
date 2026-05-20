import { Printer } from "lucide-react";

import { publicObjectUrl } from "@/lib/storage";

type PrintViewLinkProps = {
  storagePath: string | null | undefined;
};

export function PrintViewLink({ storagePath }: PrintViewLinkProps) {
  if (!storagePath) return null;
  return (
    <a
      href={publicObjectUrl(storagePath)}
      target="_blank"
      rel="noopener noreferrer"
      className="inline-flex items-center gap-1.5 rounded-md border border-mavs-navy px-3 py-1.5 text-sm font-medium text-mavs-navy hover:bg-mavs-navy/10"
    >
      <Printer className="h-4 w-4" />
      Print View
      <span className="sr-only">(opens PDF in new tab)</span>
    </a>
  );
}
