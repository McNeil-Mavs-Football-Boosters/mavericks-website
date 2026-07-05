import type { Metadata } from "next";
import Image from "next/image";
import Link from "next/link";

export const metadata: Metadata = {
  title: "Thank You for Your Donation | McNeil Mavericks Football Booster Club",
  description:
    "Thank you for supporting McNeil Football. Your donation helps fund team meals, equipment, player recognition, and more.",
  robots: { index: false },
};

export default function DonateThankYouPage() {
  return (
    <>
      {/* Green hero band matching /boosters/donate */}
      <section className="bg-mavs-green text-white py-12 md:py-16">
        <div className="container mx-auto px-4 text-center">
          <Image
            src="/brand/mhs-logo.png"
            alt=""
            aria-hidden="true"
            width={80}
            height={80}
            priority
            className="h-16 w-16 md:h-20 md:w-20 object-contain rounded-full bg-white p-0.5 mx-auto mb-6"
          />
          <h1 className="text-4xl md:text-6xl font-black uppercase tracking-tight">
            Thank You!
          </h1>
        </div>
      </section>

      <section className="container mx-auto px-4 py-12 md:py-16 max-w-2xl text-center">
        <div className="space-y-4 text-lg leading-relaxed text-gray-800">
          <p>
            Your donation to the McNeil Maverick Football Booster Club has been
            received. Thank you for supporting McNeil football.
          </p>
          <p>
            A receipt will be emailed to you by Square. The McNeil Maverick
            Football Booster Club is a 501(c)(3) nonprofit organization, EIN
            26-4231242, so your gift may be tax-deductible.
          </p>
          <p className="text-base text-gray-600">
            If your donation does not appear or you have any questions, email us
            at{" "}
            <a
              href="mailto:mcneilfootballboosters@gmail.com"
              className="text-mavs-navy underline hover:no-underline"
            >
              mcneilfootballboosters@gmail.com
            </a>
            .
          </p>
        </div>

        <div className="mt-10 flex flex-col sm:flex-row gap-4 justify-center">
          <Link
            href="/boosters/donate"
            className="bg-mavs-green text-white px-6 py-3 rounded font-bold uppercase hover:bg-mavs-green/90 transition-colors inline-block"
          >
            Back to Donate
          </Link>
          <Link
            href="/"
            className="bg-mavs-navy text-white px-6 py-3 rounded font-bold uppercase hover:bg-mavs-navy/90 transition-colors inline-block"
          >
            Return Home
          </Link>
        </div>
      </section>
    </>
  );
}
