import type { Metadata } from "next";
import PrivacyContent from "@/content/privacy.mdx";

export const metadata: Metadata = {
  title: "Privacy Policy",
  description:
    "How the McNeil Mavericks Football Booster Club collects, uses, and protects personal information.",
};

export default function PrivacyPage() {
  return (
    <div className="mx-auto max-w-3xl px-4 sm:px-6 lg:px-8 py-12">
      <PrivacyContent />
    </div>
  );
}
