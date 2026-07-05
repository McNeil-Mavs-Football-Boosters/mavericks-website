import { NextResponse } from "next/server";
import { randomUUID } from "node:crypto";
import { z } from "zod";
import { getSquareClient, getSquareLocationId } from "@/lib/square/client";
import { createServerClient } from "@/lib/supabase/server";

export const runtime = "nodejs";

// $1 minimum, $50,000 ceiling (sanity bound; real donations sit well under).
const CheckoutSchema = z.object({
  amountCents: z.number().int().min(100).max(5_000_000),
  donorName: z.string().trim().max(120).optional(),
  email: z.string().trim().email().max(200).optional().or(z.literal("")),
  dedication: z.string().trim().max(300).optional(),
  anonymous: z.boolean().optional(),
  displayPublicly: z.boolean().optional(),
  website: z.string().max(0).optional().or(z.literal("")), // honeypot
});

export async function POST(request: Request) {
  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON" }, { status: 400 });
  }

  // Honeypot: silently reject bots that fill the hidden field.
  if (
    typeof body === "object" &&
    body !== null &&
    "website" in body &&
    typeof (body as { website: unknown }).website === "string" &&
    (body as { website: string }).website.length > 0
  ) {
    return NextResponse.json({ error: "Invalid input" }, { status: 400 });
  }

  const parsed = CheckoutSchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json(
      { error: "Invalid input", issues: parsed.error.issues },
      { status: 400 },
    );
  }
  const d = parsed.data;
  const email = d.email || null;

  const siteUrl =
    process.env.NEXT_PUBLIC_SITE_URL?.replace(/\/$/, "") ??
    new URL(request.url).origin;

  // 1) Create the Square-hosted payment link.
  let paymentLink;
  try {
    const res = await getSquareClient().checkout.paymentLinks.create({
      idempotencyKey: randomUUID(),
      quickPay: {
        name: "Donation to McNeil Football Booster Club",
        priceMoney: { amount: BigInt(d.amountCents), currency: "USD" },
        locationId: getSquareLocationId(),
      },
      checkoutOptions: {
        redirectUrl: `${siteUrl}/boosters/donate/thank-you`,
        askForShippingAddress: false,
      },
      ...(email ? { prePopulatedData: { buyerEmail: email } } : {}),
    });
    paymentLink = res.paymentLink;
  } catch (err) {
    console.error("[donations/checkout] Square paymentLinks.create failed", err);
    return NextResponse.json({ error: "Could not start checkout" }, { status: 502 });
  }

  if (!paymentLink?.url || !paymentLink.orderId) {
    console.error(
      "[donations/checkout] payment link missing url/orderId",
      paymentLink,
    );
    return NextResponse.json({ error: "Could not start checkout" }, { status: 502 });
  }

  // 2) Record an authoritative pending payment row keyed by the Square order id.
  //    This row carries purpose + display preferences the webhook can't infer.
  //    If it fails we do NOT hand out the checkout URL — better the donor retries
  //    than money gets captured with no tracking record.
  try {
    const supabase = createServerClient();
    const { error } = await supabase.from("payments").insert({
      payment_session_id: paymentLink.orderId,
      payment_provider: "square",
      method: "square",
      purpose: "donation",
      amount_cents: d.amountCents,
      status: "pending",
      payer_email: email,
      payer_name: d.anonymous ? null : d.donorName || null,
      metadata: {
        payment_link_id: paymentLink.id,
        donor_name: d.donorName || null,
        dedication: d.dedication || null,
        anonymous: !!d.anonymous,
        display_publicly: !!d.displayPublicly,
      },
    });
    if (error) {
      console.error("[donations/checkout] pending payment insert failed", error);
      return NextResponse.json({ error: "Could not start checkout" }, { status: 502 });
    }
  } catch (err) {
    console.error("[donations/checkout] pending payment insert threw", err);
    return NextResponse.json({ error: "Could not start checkout" }, { status: 502 });
  }

  return NextResponse.json({ url: paymentLink.url }, { status: 200 });
}
