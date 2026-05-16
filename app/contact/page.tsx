import { ContactForm } from "./contact-form";

export const metadata = { title: "Contact" };

export default function ContactPage() {
  return (
    <div className="mx-auto max-w-2xl px-4 sm:px-6 lg:px-8 py-12">
      <h1 className="text-3xl font-bold tracking-tight sm:text-4xl mb-4">Get in touch</h1>
      <p className="text-foreground mb-3">
        Questions about membership, sponsorships, or volunteering? Send us a note and a board member will get back to you within a few days.
      </p>
      <p className="text-sm text-muted-foreground mb-8">
        For sponsorship inquiries specifically, you can also email sponsorship@mcneilmavericks.org once that alias is live.
      </p>
      <ContactForm />
    </div>
  );
}
