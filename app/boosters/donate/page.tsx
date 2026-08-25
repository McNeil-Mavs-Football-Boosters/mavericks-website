import type { Metadata } from "next";
import Image from "next/image";
import Link from "next/link";

import { DONATION_FORM_URL } from "@/lib/constants";
import {
  getConfirmedDonations,
  type Donation,
} from "@/lib/sheets/donations";

export const revalidate = 300; // 5 min ISR (matches /boosters/members)

export const metadata: Metadata = {
  title: "Donate | McNeil Mavericks Football Booster Club",
  description:
    "Donate to McNeil Football. Your contribution funds team meals, equipment, player recognition, and more. McNeil Football Booster Club is a 501(c)(3) nonprofit.",
};

interface AmountCard {
  display: string;
  buttonLabel: string;
  ariaLabel: string;
}

const AMOUNT_CARDS: AmountCard[] = [
  { display: "$25", buttonLabel: "Donate $25", ariaLabel: "Donate $25" },
  { display: "$50", buttonLabel: "Donate $50", ariaLabel: "Donate $50" },
  { display: "$100", buttonLabel: "Donate $100", ariaLabel: "Donate $100" },
  { display: "$250", buttonLabel: "Donate $250", ariaLabel: "Donate $250" },
  { display: "$500", buttonLabel: "Donate $500", ariaLabel: "Donate $500" },
  {
    display: "Other",
    buttonLabel: "Choose Amount",
    ariaLabel: "Donate another amount",
  },
];

function formatAmount(amountCents: number): string {
  return `$${Math.round(amountCents / 100).toLocaleString("en-US")}`;
}

function DonationRow({
  donation,
  isLast,
}: {
  donation: Donation;
  isLast: boolean;
}) {
  return (
    <li
      className={`py-4 ${isLast ? "" : "border-b border-gray-200"}`}
    >
      <div className="flex items-baseline justify-between gap-4">
        <span className="font-bold text-lg text-mavs-navy">
          {donation.displayName}
        </span>
        <span className="font-black text-lg text-mavs-navy">
          {formatAmount(donation.amountCents)}
        </span>
      </div>
      {donation.dedication ? (
        <p className="italic text-sm text-gray-600 mt-1">
          {donation.dedication}
        </p>
      ) : null}
      <p className="text-sm text-gray-500 mt-1">{donation.monthYear}</p>
    </li>
  );
}

export default async function BoostersDonatePage() {
  const donations = await getConfirmedDonations(20);

  return (
    <>
      {/* 1. Green hero band */}
      <section className="bg-mavs-green text-white py-12 md:py-16">
        <div className="container mx-auto px-4">
          <div className="flex flex-col md:flex-row md:items-center gap-4 md:gap-6">
            <Image
              src="/brand/mhs-logo.png"
              alt=""
              aria-hidden="true"
              width={80}
              height={80}
              priority
              className="h-16 w-16 md:h-20 md:w-20 object-contain shrink-0 rounded-full bg-white p-0.5 mx-auto md:mx-0"
            />
            <div className="flex-1 text-center">
              <h1 className="text-4xl md:text-6xl font-black uppercase tracking-tight">
                Make a Donation
              </h1>
            </div>
            <Link
              href="/boosters/join"
              className="bg-mavs-navy text-white px-6 py-3 font-bold uppercase hover:bg-mavs-navy/90 transition-colors inline-block whitespace-nowrap shrink-0 text-center w-full md:w-auto focus:outline-none focus-visible:ring-2 focus-visible:ring-white focus-visible:ring-offset-2 focus-visible:ring-offset-mavs-green"
            >
              Become a Member →
            </Link>
          </div>
        </div>
      </section>

      {/* 2. Intro prose */}
      <section className="container mx-auto px-4 py-12 md:py-16 max-w-3xl">
        <div className="space-y-4 text-lg leading-relaxed text-gray-800">
          <p>
            Your donation to the McNeil Maverick Football Booster Club helps
            fund team meals, banquets, extra equipment, player recognition,
            game day needs, travel support, and other football-specific
            expenses that help create a stronger, more meaningful experience
            for the young men in this program.
          </p>
          <p>
            Every contribution stays with McNeil football. Whether you give
            $25 or $5,000, your support shows up on the field, in the locker
            room, and at every team event throughout the season.
          </p>
          <p>
            The McNeil Maverick Football Booster Club is a 501(c)(3) nonprofit
            organization, EIN 26-4231242.
          </p>
        </div>
      </section>

      {/* 3. Amount cards */}
      <section className="container mx-auto px-4 py-8 md:py-12">
        <div className="text-center mb-8">
          <h2 className="text-3xl md:text-4xl font-bold text-mavs-navy text-center">
            Choose an Amount
          </h2>
          <p className="text-lg text-gray-600 mt-3">
            All donations go through the same form. Select the amount that
            works for you.
          </p>
        </div>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 max-w-5xl mx-auto">
          {AMOUNT_CARDS.map((card) => (
            <div
              key={card.display}
              className="bg-white rounded-lg border-2 border-mavs-navy/30 p-8 hover:shadow-md transition-shadow text-center flex flex-col"
            >
              <div className="font-black text-mavs-navy text-5xl md:text-6xl mb-6">
                {card.display}
              </div>
              <div className="flex-grow" />
              <a
                href={DONATION_FORM_URL}
                target="_blank"
                rel="noopener noreferrer"
                aria-label={card.ariaLabel}
                className="bg-mavs-green text-white px-6 py-3 rounded font-bold uppercase hover:bg-mavs-green/90 transition-colors w-full inline-block text-center"
              >
                {card.buttonLabel}
              </a>
            </div>
          ))}
        </div>
      </section>

      {/* 3b. Employer matching + volunteer grants.
           Added 2026-08-25 at Kendra's request, after she reclaimed the
           Benevity account under the booster Gmail.

           ⚠️ THE LEGAL NAME IS SINGULAR "MAVERICK" and that is the whole point
           of printing it here. Employer giving portals validate against IRS
           records, so a parent searching the brand name "Mavericks" may find
           nothing. Name and EIN are set apart to be copied, not buried in prose.

           Benevity is deliberately NOT named. It is the platform the club is
           registered on, but a parent does not know or care -- they know
           "does my company match donations". Naming it would send people
           looking for a Benevity page instead of their own employer portal. */}
      <section
        id="employer-matching"
        className="container mx-auto px-4 py-12 md:py-16 scroll-mt-24"
      >
        <div className="max-w-3xl mx-auto bg-mavs-navy/5 border-2 border-mavs-navy/10 rounded-lg p-8 md:p-10">
          <h2 className="text-2xl md:text-3xl font-black uppercase tracking-tight text-mavs-navy text-center">
            Your Employer May Double It
          </h2>
          <div className="h-1 w-20 bg-mavs-green mx-auto mt-3 mb-8"></div>
          <div className="space-y-4 text-lg leading-relaxed text-gray-800">
            <p>
              Many companies match employee donations, often dollar for dollar.
              Some also make a donation based on the hours you volunteer. Either
              one means more money for McNeil football at no additional cost to
              you, and most of it goes unclaimed simply because people do not
              know to ask.
            </p>
            <p>
              Check whether your employer has a matching gift or volunteer grant
              program, then look us up in their giving portal using our legal
              name and EIN:
            </p>
          </div>
          <div className="mt-6 bg-white border-2 border-mavs-navy/20 rounded-md p-6 text-center">
            <p className="text-xs font-semibold uppercase tracking-wider text-gray-500">
              Legal Name
            </p>
            <p className="text-xl md:text-2xl font-black text-mavs-navy mt-1">
              McNeil Maverick Football Booster Club
            </p>
            <p className="text-sm text-gray-600 italic mt-2">
              Maverick is singular in our legal name, even though we go by
              Mavericks everywhere else. Search it exactly this way.
            </p>
            <p className="text-xs font-semibold uppercase tracking-wider text-gray-500 mt-6">
              EIN
            </p>
            <p className="text-xl md:text-2xl font-black text-mavs-navy mt-1">
              26-4231242
            </p>
            <p className="text-sm text-gray-600 mt-2">
              501(c)(3) nonprofit organization
            </p>
          </div>
          <p className="mt-6 text-base text-gray-700 text-center">
            Not sure whether your company participates, or cannot find us in
            their system? Email{" "}
            <a
              href="mailto:fundraising@mcneilmavericks.org"
              className="text-mavs-navy font-bold underline hover:text-mavs-green"
            >
              fundraising@mcneilmavericks.org
            </a>{" "}
            and we will help you track it down.
          </p>
        </div>
      </section>

      {/* 4. Thank You to Our Donors */}
      <section className="container mx-auto px-4 py-12 md:py-16">
        <div className="text-center mb-8">
          <h2 className="text-3xl md:text-4xl font-bold text-mavs-navy text-center">
            Thank You to Our Donors
          </h2>
          <p className="text-lg text-gray-600 mt-3">
            Recent contributions to McNeil football. Every gift makes a
            difference.
          </p>
        </div>

        {donations.length === 0 ? (
          <div className="max-w-3xl mx-auto text-center">
            <p className="text-lg text-gray-800">
              Be the first to donate. Your contribution will appear here once
              received.
            </p>
            <div className="mt-6">
              <a
                href={DONATION_FORM_URL}
                target="_blank"
                rel="noopener noreferrer"
                className="bg-mavs-green text-white px-8 py-4 rounded font-bold uppercase hover:bg-mavs-green/90 transition-colors inline-block"
              >
                Donate →
              </a>
            </div>
          </div>
        ) : (
          <>
            <ul className="max-w-3xl mx-auto list-none p-0">
              {donations.map((donation, i) => (
                <DonationRow
                  key={`donation-${i}`}
                  donation={donation}
                  isLast={i === donations.length - 1}
                />
              ))}
            </ul>

            {/* 5. Show more placeholder */}
            {donations.length === 20 ? (
              <p className="text-center text-sm text-gray-500 mt-8">
                Full donation archive coming soon.
              </p>
            ) : null}
          </>
        )}
      </section>

      {/* 6. Bottom navy CTA band */}
      <section className="bg-mavs-navy text-white py-12 md:py-16">
        <div className="container mx-auto px-4 text-center">
          <h2 className="text-3xl md:text-4xl font-bold text-white">
            Want to do more?
          </h2>
          <p className="text-lg text-white/90 mt-4 max-w-xl mx-auto">
            Become a McNeil Football Booster member for exclusive perks and a
            deeper connection to the program.
          </p>
          <Link
            href="/boosters/join"
            className="inline-block mt-8 bg-mavs-green text-white px-8 py-4 rounded font-bold uppercase hover:bg-mavs-green/90 transition-colors"
          >
            Join the Club →
          </Link>
        </div>
      </section>
    </>
  );
}
