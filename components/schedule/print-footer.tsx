"use client";

import { useEffect, useState } from "react";

export function PrintFooter() {
  const [url, setUrl] = useState("");
  const [printedOn, setPrintedOn] = useState("");

  useEffect(() => {
    setUrl(window.location.href);
    setPrintedOn(
      new Date().toLocaleDateString("en-US", {
        year: "numeric",
        month: "long",
        day: "numeric",
      }),
    );
  }, []);

  return (
    <div className="hidden print:block mt-8 border-t border-black pt-2 text-xs text-black">
      <span>{url}</span>
      <span aria-hidden="true"> · </span>
      <span>Printed {printedOn}</span>
    </div>
  );
}
