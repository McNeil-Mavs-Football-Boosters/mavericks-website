import "server-only";
import { SquareClient, SquareEnvironment } from "square";

let cached: SquareClient | null = null;

/**
 * Server-only Square client. Reads SQUARE_ACCESS_TOKEN + SQUARE_ENVIRONMENT
 * from the environment. Cached across invocations like getResendClient().
 */
export function getSquareClient(): SquareClient {
  if (cached) return cached;
  const token = process.env.SQUARE_ACCESS_TOKEN;
  if (!token) {
    throw new Error("Missing SQUARE_ACCESS_TOKEN");
  }
  const environment =
    process.env.SQUARE_ENVIRONMENT === "production"
      ? SquareEnvironment.Production
      : SquareEnvironment.Sandbox;
  cached = new SquareClient({ token, environment });
  return cached;
}

/** The configured Square location the payments belong to. */
export function getSquareLocationId(): string {
  const id = process.env.SQUARE_LOCATION_ID;
  if (!id) {
    throw new Error("Missing SQUARE_LOCATION_ID");
  }
  return id;
}
