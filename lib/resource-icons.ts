import type { ComponentType } from "react";
import {
  ClipboardList,
  ExternalLink,
  FileText,
  Mail,
  Newspaper,
  Play,
  type LucideProps,
} from "lucide-react";

type LucideIcon = ComponentType<LucideProps>;

const ICON_BY_HINT: Record<string, LucideIcon> = {
  external: ExternalLink,
  pdf: FileText,
  form: ClipboardList,
  video: Play,
  mail: Mail,
  newspaper: Newspaper,
};

export function iconForHint(hint: string | null): LucideIcon {
  if (hint == null) return ExternalLink;
  return ICON_BY_HINT[hint] ?? ExternalLink;
}
