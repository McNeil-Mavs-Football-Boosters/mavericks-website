import { createServerClient } from "@/lib/supabase/server";

// Step 2 smoke test. Delete before Step 4.
export const dynamic = "force-dynamic";

export default async function Ping() {
  const supabase = createServerClient();
  const { data, error } = await supabase.rpc("now_utc");

  return (
    <main className="mx-auto max-w-xl p-8 font-mono text-sm">
      <h1 className="mb-4 text-lg font-semibold">Supabase smoke test</h1>
      {error ? (
        <pre className="rounded bg-red-50 p-4 whitespace-pre-wrap text-red-900">
          error: {JSON.stringify(error, null, 2)}
        </pre>
      ) : (
        <p>
          Postgres <code>now()</code>: <strong>{String(data)}</strong>
        </p>
      )}
    </main>
  );
}
