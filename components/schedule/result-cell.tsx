import type { Game } from "@/lib/types";

const EM_DASH = "—";

/**
 * The Result column, and ONLY the result.
 *
 * ⚠️ It used to also render "Watch →" here for a non-final game with a
 * `watch_url`. That is gone as of migration 165 — broadcast links now live in
 * `LinksCell`, in the right-hand action column. The stopgap had two limits that
 * VYPE broke immediately: it could show only ONE link (VYPE supplies two, their
 * watch page plus the YouTube URL), and it occupied the same cell as the score,
 * so a replay link had nowhere to go once the game went final. Do not put a link
 * back in here.
 */
export function ResultCell({ game }: { game: Game }) {
  const { result_status, our_score, their_score } = game;

  if (result_status === "final") {
    if (our_score == null || their_score == null) {
      return <span className="text-muted-foreground print:text-black">{EM_DASH}</span>;
    }
    if (our_score > their_score) {
      return (
        <span className="font-semibold text-mavs-green print:text-black">
          W {our_score}-{their_score}
        </span>
      );
    }
    if (our_score < their_score) {
      return (
        <span className="font-semibold text-foreground print:text-black">
          L {our_score}-{their_score}
        </span>
      );
    }
    return (
      <span className="font-semibold text-foreground print:text-black">
        T {our_score}-{their_score}
      </span>
    );
  }

  if (result_status === "cancelled") {
    return (
      <span className="inline-flex items-center rounded-full border border-border px-2 py-0.5 text-xs text-muted-foreground print:border-black print:text-black">
        Cancelled
      </span>
    );
  }

  if (result_status === "postponed") {
    return (
      <span className="inline-flex items-center rounded-full border border-border px-2 py-0.5 text-xs text-muted-foreground print:border-black print:text-black">
        Postponed
      </span>
    );
  }

  if (result_status === "tbd") {
    return <span className="text-muted-foreground print:text-black">TBD</span>;
  }

  return <span className="text-muted-foreground print:text-black">{EM_DASH}</span>;
}
