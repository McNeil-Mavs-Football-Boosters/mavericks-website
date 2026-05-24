import Image from "next/image";
import Link from "next/link";
import {
  ArrowUpRight,
  Award,
  Camera,
  Clipboard,
  Coffee,
  Flag,
  HandCoins,
  HeartHandshake,
  Pizza,
  Ruler,
  Users,
  Utensils,
  type LucideIcon,
} from "lucide-react";

import { VOLUNTEER_FORM_URL } from "@/lib/constants";

export const metadata = {
  title: "Volunteer | McNeil Mavericks Football Booster Club",
  description:
    "Volunteer with the McNeil Football Booster Club. Help feed the team, support coaches, run events, and more.",
};

interface Opportunity {
  icon: LucideIcon;
  title: string;
  description: string;
}

const OPPORTUNITIES: Opportunity[] = [
  {
    icon: Utensils,
    title: "Hosting a Varsity Team Dinner",
    description:
      "Open your home or organize a meal for the varsity team during the season.",
  },
  {
    icon: Coffee,
    title: "Picking Up Coaches Meals",
    description:
      "Grab and deliver meals for the coaching staff on practice or game days.",
  },
  {
    icon: Pizza,
    title: "Picking Up Game-Day Meals",
    description:
      "Help feed the team before games with quick pickup and delivery shifts.",
  },
  {
    icon: Ruler,
    title: "Freshman / JV Chain Gang",
    description:
      "Work the chain crew on the sideline at Freshman and JV home games.",
  },
  {
    icon: Award,
    title: "Banquets & Player Recognition",
    description:
      "Help plan and run the football banquet, senior night, and other recognition events.",
  },
  {
    icon: HandCoins,
    title: "Fundraising",
    description:
      "Pitch in on fundraisers that keep the booster club going year-round.",
  },
  {
    icon: Users,
    title: "Joining a Committee",
    description:
      "Plug into one of our 11 committees for a deeper, ongoing role.",
  },
  {
    icon: Flag,
    title: "Game-Day Tunnel Crew",
    description:
      "Help transport, set up, and tear down the run-out tunnel on game days. Requires a few volunteers and a trailer.",
  },
  {
    icon: Clipboard,
    title: "Game-Day General Support",
    description:
      "Be a flexible extra hand on game days wherever the team needs help.",
  },
  {
    icon: Camera,
    title: "Communications",
    description:
      "Support team photos, social media posts, or website updates.",
  },
  {
    icon: HeartHandshake,
    title: "General Volunteer",
    description:
      "Not sure where to plug in? Tell us a bit about yourself and we'll find a fit.",
  },
];

export default function BoostersVolunteerPage() {
  return (
    <>
      <section className="bg-mavs-green text-white py-12 md:py-16">
        <div className="container mx-auto px-4">
          <div className="flex flex-col md:flex-row md:items-center gap-4 md:gap-6">
            <Image
              src="/brand/mhs-logo.png"
              alt="McNeil Mavericks logo"
              width={80}
              height={80}
              priority
              className="h-16 w-16 md:h-20 md:w-20 object-contain shrink-0 rounded-full bg-white p-0.5 mx-auto md:mx-0"
            />
            <div className="flex-1 text-center">
              <h1 className="text-4xl md:text-6xl font-black uppercase tracking-tight">
                Volunteer with McNeil Football
              </h1>
            </div>
            <a
              href={VOLUNTEER_FORM_URL}
              target="_blank"
              rel="noopener"
              className="bg-mavs-navy text-white px-6 py-3 font-bold uppercase hover:bg-mavs-navy/90 transition-colors inline-block whitespace-nowrap shrink-0 text-center w-full md:w-auto focus:outline-none focus-visible:ring-2 focus-visible:ring-white focus-visible:ring-offset-2 focus-visible:ring-offset-mavs-green"
            >
              Sign Up →
            </a>
          </div>
        </div>
      </section>

      <section className="container mx-auto px-4 py-10 md:py-12 max-w-3xl">
        <div className="space-y-4 text-lg leading-relaxed text-gray-800">
          <p>
            McNeil Football is powered by more than the players and coaches on
            the field. It is also powered by the parents, families, and
            volunteers who give their time behind the scenes to make the season
            meaningful for our athletes.
          </p>
          <p>
            Every meal served, every pickup made, every event organized, and
            every hour volunteered helps create the kind of program our players
            deserve. These moments may seem small, but they add up to something
            our athletes feel throughout the season: support.
          </p>
          <p>
            The McNeil Football Booster Club offers several ways for families
            and community members to get involved. Whether you can help once, a
            few times, or throughout the season, your time makes a difference.
          </p>
        </div>
      </section>

      <section className="container mx-auto px-4 py-8 md:py-12">
        <div className="text-center mb-8">
          <h2 className="text-3xl md:text-4xl font-bold text-mavs-navy">
            Ways to Get Involved
          </h2>
          <p className="text-lg text-gray-600 mt-3">
            Volunteer opportunities may include:
          </p>
        </div>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {OPPORTUNITIES.map((opportunity) => {
            const Icon = opportunity.icon;
            const isCommittee = opportunity.title === "Joining a Committee";

            if (isCommittee) {
              return (
                <Link
                  key={opportunity.title}
                  href="/boosters/committees"
                  className="relative bg-white border border-gray-200 rounded-lg p-6 hover:shadow-md transition-shadow block"
                >
                  <ArrowUpRight
                    aria-hidden="true"
                    className="absolute top-4 right-4 text-mavs-navy"
                    size={20}
                  />
                  <Icon
                    aria-hidden="true"
                    size={32}
                    className="text-mavs-navy mb-3"
                  />
                  <h3 className="font-bold text-lg text-mavs-navy">
                    {opportunity.title}
                  </h3>
                  <p className="text-gray-600 text-sm mt-2">
                    {opportunity.description}
                  </p>
                </Link>
              );
            }

            return (
              <div
                key={opportunity.title}
                className="bg-white border border-gray-200 rounded-lg p-6 hover:shadow-md transition-shadow"
              >
                <Icon
                  aria-hidden="true"
                  size={32}
                  className="text-mavs-navy mb-3"
                />
                <h3 className="font-bold text-lg text-mavs-navy">
                  {opportunity.title}
                </h3>
                <p className="text-gray-600 text-sm mt-2">
                  {opportunity.description}
                </p>
              </div>
            );
          })}
        </div>
      </section>

      <section className="container mx-auto px-4 py-10 md:py-12 max-w-3xl">
        <div className="space-y-4 text-lg leading-relaxed text-gray-800">
          <p>
            You do not need to have a specific skill or a large amount of time
            to help. Some roles take planning and coordination, while others may
            only take a quick pickup or a short shift. What matters most is that
            our players see their community showing up for them.
          </p>
          <p>
            When you volunteer with McNeil Football, you are helping feed the
            team, support the coaches, celebrate the players, and build the
            kind of football experience our athletes will remember long after
            the season ends.
          </p>
          <p>
            Your time matters. Your help is appreciated. And every volunteer
            makes McNeil Football stronger.
          </p>
        </div>
      </section>

      <section className="bg-mavs-navy text-white py-12 md:py-16">
        <div className="container mx-auto px-4 text-center">
          <h2 className="text-3xl md:text-4xl font-bold">Ready to Help?</h2>
          <p className="text-lg text-white/90 mt-4 max-w-xl mx-auto">
            Fill out the volunteer interest form and we&apos;ll be in touch.
          </p>
          <a
            href={VOLUNTEER_FORM_URL}
            target="_blank"
            rel="noopener"
            className="inline-block mt-8 bg-mavs-green text-white px-8 py-4 font-bold uppercase hover:bg-mavs-green/90 transition-colors text-lg focus:outline-none focus-visible:ring-2 focus-visible:ring-white focus-visible:ring-offset-2 focus-visible:ring-offset-mavs-navy"
          >
            Sign Up →
          </a>
        </div>
      </section>
    </>
  );
}
