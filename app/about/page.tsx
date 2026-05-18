import Link from "next/link";

import { ContactForm } from "@/app/contact/contact-form";

export const metadata = {
  title: "About",
};

export default function AboutPage() {
  return (
    <div className="mx-auto max-w-5xl px-4 sm:px-6 lg:px-8 py-12">
      <h1 className="text-3xl font-black uppercase tracking-tight sm:text-4xl mb-4">
        About This Site
      </h1>
      <p className="text-foreground leading-7">
        mcneilmavericks.org is the public website for McNeil Mavericks
        football. It&apos;s maintained by the McNeil Maverick Football Booster
        Club, a 501(c)(3) parent volunteer organization. We post game
        schedules, rosters, news, and information for parents and athletes. To
        learn more about the booster club, visit{" "}
        <Link href="/boosters" className="text-mavs-navy hover:underline">
          the Boosters section
        </Link>
        .
      </p>

      <section className="mt-10">
        <h2 className="text-xl font-bold uppercase tracking-tight mb-3">Get in touch</h2>
        <p className="text-foreground mb-6">
          Questions about membership, sponsorships, or volunteering? Send us a
          note and a board member will get back to you within a few days.
        </p>
        <ContactForm />
      </section>

      <section className="mt-10 pt-8 border-t border-border">
        <h2 className="text-xl font-bold uppercase tracking-tight mb-3">Direct contacts</h2>
        <ul className="space-y-2 text-sm list-none p-0">
          <li>
            <span className="font-semibold text-foreground">
              General questions:
            </span>{" "}
            <a
              href="mailto:boosters@mcneilmavericks.org"
              className="text-mavs-navy hover:underline"
            >
              boosters@mcneilmavericks.org
            </a>
          </li>
          <li>
            <span className="font-semibold text-foreground">
              Sponsorship inquiries:
            </span>{" "}
            <a
              href="mailto:sponsorship@mcneilmavericks.org"
              className="text-mavs-navy hover:underline"
            >
              sponsorship@mcneilmavericks.org
            </a>
          </li>
          <li>
            <span className="font-semibold text-foreground">
              Membership questions:
            </span>{" "}
            <a
              href="mailto:boosters@mcneilmavericks.org"
              className="text-mavs-navy hover:underline"
            >
              boosters@mcneilmavericks.org
            </a>
          </li>
          <li>
            <span className="font-semibold text-foreground">
              Website / technical issues:
            </span>{" "}
            <a
              href="mailto:webmaster@mcneilmavericks.org"
              className="text-mavs-navy hover:underline"
            >
              webmaster@mcneilmavericks.org
            </a>
          </li>
        </ul>
      </section>

      <section className="mt-10 pt-8 border-t border-border">
        <h2 className="text-xl font-bold uppercase tracking-tight mb-3">Affiliations</h2>
        <p className="text-sm text-muted-foreground leading-relaxed">
          This website is maintained by the McNeil Maverick Football Booster
          Club and is not a part of McNeil High School or Round Rock ISD.
          Neither McNeil High School nor Round Rock ISD is responsible for the
          content or opinions within this website.
        </p>
      </section>
    </div>
  );
}
