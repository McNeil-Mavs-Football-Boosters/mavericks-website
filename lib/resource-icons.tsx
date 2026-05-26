import type { ComponentType } from "react";
import {
  Camera,
  ClipboardList,
  ExternalLink,
  FileText,
  Mail,
  Newspaper,
  Play,
  type LucideProps,
} from "lucide-react";

type LucideIcon = ComponentType<LucideProps>;

// lucide-react v1.x dropped brand glyphs (trademark). Inline SVG mirrors the
// Footer.tsx Facebook component so the brand mark renders consistently.
function Facebook({ className, ...rest }: LucideProps) {
  return (
    <svg
      xmlns="http://www.w3.org/2000/svg"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
      className={className}
      aria-hidden="true"
      {...rest}
    >
      <path d="M18 2h-3a5 5 0 0 0-5 5v3H7v4h3v8h4v-8h3l1-4h-4V7a1 1 0 0 1 1-1h3z" />
    </svg>
  );
}

const ICON_BY_HINT: Record<string, LucideIcon> = {
  external: ExternalLink,
  pdf: FileText,
  form: ClipboardList,
  video: Play,
  mail: Mail,
  newspaper: Newspaper,
  facebook: Facebook,
  photo: Camera,
};

export function iconForHint(hint: string | null): LucideIcon {
  if (hint == null) return ExternalLink;
  return ICON_BY_HINT[hint] ?? ExternalLink;
}
