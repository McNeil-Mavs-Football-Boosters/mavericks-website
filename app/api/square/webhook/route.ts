import { NextResponse } from "next/server";
import { WebhooksHelper } from "square";
import { createServerClient } from "@/lib/supabase/server";

export const runtime = "nodejs";

/**
 * Square webhook endpoint. Verifies the HMAC signature, then reconciles
 * completed payments against the pending rows written by the checkout routes.
 *
 * Notification URL must match exactly what's registered in the Square Developer
 * dashboard webhook subscription (that's also where SQUARE_WEBHOOK_SIGNATURE_KEY
 * comes from). Set both before this can succeed:
 *   SQUARE_WEBHOOK_SIGNATURE_KEY   (secret)
 *   SQUARE_WEBHOOK_NOTIFICATION_URL (optional; defaults to NEXT_PUBLIC_SITE_URL + this path)
 */
function notificationUrl(): string {
  const explicit = process.env.SQUARE_WEBHOOK_NOTIFICATION_URL;
  if (explicit) return explicit;
  const base = process.env.NEXT_PUBLIC_SITE_URL?.replace(/\/$/, "") ?? "";
  return `${base}/api/square/webhook`;
}

export async function POST(request: Request) {
  const signatureKey = process.env.SQUARE_WEBHOOK_SIGNATURE_KEY;
  if (!signatureKey) {
    console.error("[square/webhook] SQUARE_WEBHOOK_SIGNATURE_KEY not configured");
    return NextResponse.json({ error: "Webhook not configured" }, { status: 500 });
  }

  // Raw body is required for signature verification — read as text, parse after.
  const rawBody = await request.text();
  const signatureHeader = request.headers.get("x-square-hmacsha256-signature") ?? "";

  let valid = false;
  try {
    valid = await WebhooksHelper.verifySignature({
      requestBody: rawBody,
      signatureHeader,
      signatureKey,
      notificationUrl: notificationUrl(),
    });
  } catch (err) {
    console.error("[square/webhook] signature verification threw", err);
    return NextResponse.json({ error: "Bad signature" }, { status: 401 });
  }
  if (!valid) {
    console.warn("[square/webhook] rejected event with invalid signature");
    return NextResponse.json({ error: "Bad signature" }, { status: 401 });
  }

  let event: {
    type?: string;
    data?: { object?: { payment?: { id?: string; order_id?: string; status?: string } } };
  };
  try {
    event = JSON.parse(rawBody);
  } catch {
    return NextResponse.json({ error: "Invalid JSON" }, { status: 400 });
  }

  // We only act on completed payments. Everything else is acknowledged so
  // Square stops retrying, but ignored.
  const payment = event.data?.object?.payment;
  const isPaymentEvent =
    event.type === "payment.created" || event.type === "payment.updated";

  if (!isPaymentEvent || !payment) {
    return NextResponse.json({ ok: true, ignored: event.type ?? "unknown" }, { status: 200 });
  }

  if (payment.status !== "COMPLETED") {
    return NextResponse.json({ ok: true, status: payment.status }, { status: 200 });
  }

  const orderId = payment.order_id;
  if (!orderId) {
    console.error("[square/webhook] completed payment with no order_id", payment.id);
    return NextResponse.json({ ok: true }, { status: 200 });
  }

  // Flip the pending row (matched by the Square order id we stored at checkout)
  // to succeeded and record the Square payment id. Idempotent: re-running on an
  // already-succeeded row is a harmless no-op update.
  try {
    const supabase = createServerClient();
    const { data, error } = await supabase
      .from("payments")
      .update({
        status: "succeeded",
        payment_provider_id: payment.id ?? null,
        updated_at: new Date().toISOString(),
      })
      .eq("payment_session_id", orderId)
      .select("id");

    if (error) {
      console.error("[square/webhook] payment update failed", error);
      // 500 so Square retries — the payment is real; we just failed to record it.
      return NextResponse.json({ error: "Update failed" }, { status: 500 });
    }
    if (!data || data.length === 0) {
      // No pending row for this order. Should not happen — checkout writes the
      // row before handing out the URL. Log loudly for manual reconciliation;
      // do NOT guess the purpose and fabricate a row.
      console.error(
        `[square/webhook] no pending payment row for order ${orderId} (payment ${payment.id}) — manual reconciliation needed`,
      );
    }
  } catch (err) {
    console.error("[square/webhook] payment update threw", err);
    return NextResponse.json({ error: "Update failed" }, { status: 500 });
  }

  return NextResponse.json({ ok: true }, { status: 200 });
}
