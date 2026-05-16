import type { MDXComponents } from "mdx/types";

const components: MDXComponents = {
  h1: ({ children }) => (
    <h1 className="mt-0 mb-6 text-3xl font-bold tracking-tight text-foreground sm:text-4xl">
      {children}
    </h1>
  ),
  h2: ({ children }) => (
    <h2 className="mt-10 mb-3 text-2xl font-semibold tracking-tight text-foreground">
      {children}
    </h2>
  ),
  h3: ({ children }) => (
    <h3 className="mt-8 mb-2 text-xl font-semibold tracking-tight text-foreground">
      {children}
    </h3>
  ),
  p: ({ children }) => (
    <p className="my-4 leading-7 text-foreground">{children}</p>
  ),
  ul: ({ children }) => (
    <ul className="my-4 list-disc space-y-1 pl-6 text-foreground">{children}</ul>
  ),
  ol: ({ children }) => (
    <ol className="my-4 list-decimal space-y-1 pl-6 text-foreground">{children}</ol>
  ),
  a: ({ href, children }) => (
    <a
      href={href}
      className="text-mavs-green underline underline-offset-2 hover:no-underline"
    >
      {children}
    </a>
  ),
  blockquote: ({ children }) => (
    <blockquote className="my-6 border-l-4 border-mavs-green pl-4 italic text-muted-foreground">
      {children}
    </blockquote>
  ),
  hr: () => <hr className="my-8 border-border" />,
};

export function useMDXComponents(): MDXComponents {
  return components;
}
