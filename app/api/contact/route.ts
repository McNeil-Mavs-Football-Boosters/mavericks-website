import { NextResponse } from "next/server";
import { z } from "zod";
import { getResendClient } from "@/lib/resend";

export const runtime = "nodejs";

const ContactSchema = z.object({
  name: z.string().trim().min(1).max(100),
  email: z.string().trim().email().max(200),
  subject: z.string().trim().min(1).max(200),
  message: z.string().trim().min(1).max(5000),
  website: z.string().max(0).optional().or(z.literal("")),
});

export async function POST(request: Request) {
  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON" }, { status: 400 });
  }

  if (
    typeof body === "object" &&
    body !== null &&
    "website" in body &&
    typeof (body as { website: unknown }).website === "string" &&
    (body as { website: string }).website.length > 0
  ) {
    return NextResponse.json({ ok: true }, { status: 400 });
  }

  const result = ContactSchema.safeParse(body);
  if (!result.success) {
    return NextResponse.json(
      { error: "Invalid input", issues: result.error.issues },
      { status: 400 },
    );
  }

  const data = result.data;
  const to = process.env.CONTACT_TO_EMAIL;
  const from = process.env.CONTACT_FROM_EMAIL;
  if (!to || !from) {
    console.error("Email not configured: missing CONTACT_TO_EMAIL or CONTACT_FROM_EMAIL");
    return NextResponse.json({ error: "Email not configured" }, { status: 500 });
  }

  const text = `New contact form submission from mcneilmavericks.org

From: ${data.name} <${data.email}>
Subject: ${data.subject}

${data.message}

---
Sent from the contact form. Reply directly to respond to ${data.name}.`;

  try {
    const sendResult = await getResendClient().emails.send({
      from,
      to,
      replyTo: data.email,
      subject: `[Mavericks Boosters] ${data.subject}`,
      text,
    });
    if (sendResult.error) {
      console.error("Resend send failed", sendResult.error);
      return NextResponse.json({ error: "Failed to send" }, { status: 500 });
    }
  } catch (err) {
    console.error("Resend send failed", err);
    return NextResponse.json({ error: "Failed to send" }, { status: 500 });
  }

  return NextResponse.json({ ok: true }, { status: 200 });
}
