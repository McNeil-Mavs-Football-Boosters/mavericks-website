import type { Game } from "@/lib/types";

const EM_DASH = "—";

export function ResultCell({ game }: { game: Game }) {
  const { result_status, our_score, their_score, watch_url } = game;

  // Non-final game with a watch_url: render "Watch →" in place of the
  // em-dash. Used for games that haven't been played yet (or that we're
  // intentionally not scoring) but have a broadcast/stream URL.
  if (result_status !== "final" && watch_url) {
    return (
      <a
        href={watch_url}
        target="_blank"
        rel="noopener noreferrer"
        className="font-semibold text-mavs-navy hover:underline print:text-black print:no-underline"
      >
        Watch →
      </a>
    );
  }

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
