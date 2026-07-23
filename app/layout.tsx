import type { Metadata } from "next";
import { Lato } from "next/font/google";
import "./globals.css";
import { Footer } from "@/components/layout/Footer";
import { Header } from "@/components/layout/Header";
import { getSiteSettingsCore } from "@/lib/site-settings";

// Lato is the Round Rock ISD / McNeil HS official online typeface (per the
// 2024 brand style guide). Weights map to brand type rules:
//   Body copy        → Regular (400)  — guide labels Lato 400 as "Medium"
//   Secondary head   → Bold    (700)
//   Headline (h1)    → Black   (900)
// Lato on Google Fonts publishes 100/300/400/700/900 — no native 500 — so 400
// stands in for "Medium" per the guide's online-usage callouts.
// Assigned to --font-sans so `font-sans` (and any unstyled text) inherits it.
const lato = Lato({
  variable: "--font-sans",
  subsets: ["latin"],
  weight: ["400", "700", "900"],
  display: "swap",
});

const SITE_DESCRIPTION =
  "Parent-run 501(c)(3) supporting McNeil High School Mavericks football in Austin, Texas.";

// metadataBase makes the auto-wired opengraph-image.png / twitter-image.png
// resolve to absolute URLs, which link-preview crawlers (SportsYou, iMessage,
// Facebook, etc.) require to render a preview card.
export const metadata: Metadata = {
  metadataBase: new URL("https://www.mcneilmavericks.org"),
  title: {
    default: "McNeil Mavericks Football Booster Club",
    template: "%s · McNeil Mavericks Football Booster Club",
  },
  description: SITE_DESCRIPTION,
  openGraph: {
    type: "website",
    siteName: "McNeil Mavericks Football",
    title: "McNeil Mavericks Football Booster Club",
    description: SITE_DESCRIPTION,
    url: "https://www.mcneilmavericks.org",
    locale: "en_US",
  },
  twitter: {
    card: "summary_large_image",
    title: "McNeil Mavericks Football Booster Club",
    description: SITE_DESCRIPTION,
  },
};

export default async function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  const { freshman_has_blue } = await getSiteSettingsCore();
  return (
    <html
      lang="en"
      className={`${lato.variable} h-full antialiased`}
    >
      <body className="flex min-h-full flex-col bg-background text-foreground">
        <Header freshmanHasBlue={freshman_has_blue} />
        <main className="flex-1">{children}</main>
        <Footer />
      </body>
    </html>
  );
}
