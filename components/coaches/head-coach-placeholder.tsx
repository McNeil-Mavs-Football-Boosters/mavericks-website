export function HeadCoachPlaceholder() {
  return (
    <article className="flex h-full flex-col overflow-hidden rounded-lg border border-border bg-white">
      <div
        aria-hidden="true"
        className="aspect-square w-full bg-muted"
      />
      <div className="flex flex-1 flex-col p-5">
        <p className="text-sm leading-6 text-foreground">
          Head Coach: position currently open. We&apos;ll update this page when
          the new coach is announced.
        </p>
      </div>
    </article>
  );
}
