// Slice 1 placeholder for the Subscribe to calendar control.
// Renders only the button shape so the toolbar layout is final; slice 2 swaps
// this for a client component that opens the popover with Google/Apple/Outlook/
// Copy-ICS options.
//
// TODO slice 2: replace with client component <SubscribeCalendarButton>.
export default function SubscribeButtonShape() {
  return (
    <span
      aria-disabled="true"
      className="border border-mavs-navy text-mavs-navy bg-white px-4 py-2 rounded inline-flex items-center gap-2 cursor-not-allowed opacity-60 font-bold uppercase tracking-wide text-sm"
    >
      Subscribe to calendar ▾
    </span>
  );
}
