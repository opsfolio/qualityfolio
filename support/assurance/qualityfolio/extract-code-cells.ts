#!/usr/bin/env -S deno run -A --node-modules-dir=auto

// extract-code-cells.ts
//
// Load one or more Markdown sources, run the Spry graph rules,
// build a containedInSection tree, visit each node, and show
// we can find <code> cells in files using the new graph.ts / graph-tree.ts
// APIs.

import { gray, green, yellow } from "@std/fmt/colors";
import type { Root } from "types/mdast";
import type { Node } from "types/unist";

import {
  containedInSectionRule,
  createGraphRulesBuilder,
  isBoldSingleLineParagraph,
  isColonSingleLineParagraph,
  IsSectionContainer,
  RuleContext,
} from "../../../lib/axiom/edge/rule/mod.ts";
import { headingText } from "../../../lib/axiom/mdast/node-content.ts";
import {
  astGraphEdges,
  GraphEdge,
  graphEdgesTree,
  type GraphEdgeTreeNode,
  markdownASTs,
} from "../../../lib/axiom/mod.ts";

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

type Relationship = string;
type Edge = GraphEdge<Relationship>;
type Ctx = RuleContext;

interface ViewableRoot {
  root: Root;
  label: string;
}

interface ExtractedCodeCell {
  docIndex: number;
  docLabel: string;
  code: string;
  lang?: string;
  meta?: string;
  ancestors: readonly GraphEdgeTreeNode<Relationship, Edge>[];
}

// Narrow node type for code blocks
type CodeNode = Node & {
  type: "code";
  value?: unknown;
  lang?: string | null;
  meta?: string | null;
};

// ---------------------------------------------------------------------------
// Collect roots
// ---------------------------------------------------------------------------

async function collectRoots(sources: string[]): Promise<ViewableRoot[]> {
  const out: ViewableRoot[] = [];
  if (!sources.length) return out;

  for await (const viewable of markdownASTs(sources)) {
    out.push({
      root: viewable.mdastRoot as Root,
      label: viewable.fileRef(),
    });
  }

  return out;
}

function sanitizeForFilename(label: string): string {
  const trimmed = label.trim();
  const base = trimmed || "document";
  return (
    base
      .replace(/^[./\\]+/, "") // strip leading path-ish chars
      .replace(/[^a-zA-Z0-9._-]+/g, "-")
      .slice(0, 80) || "document"
  );
}

// ---------------------------------------------------------------------------
// Section container callback (similar to model.ts)
// ---------------------------------------------------------------------------

const headingLikeSectionContainer: IsSectionContainer = (node: Node) => {
  if (node.type === "heading") {
    return {
      nature: "heading" as const,
      label: headingText(node),
      // not strictly needed here, but harmless
      mdLabel: headingText(node),
    };
  }

  if (node.type !== "paragraph") return false;

  const candidate = isBoldSingleLineParagraph(node as never) ??
    isColonSingleLineParagraph(node as never);

  if (!candidate) return false;

  return {
    nature: "section" as const,
    ...candidate,
  };
};

// ---------------------------------------------------------------------------
// Build rules + graph tree
// ---------------------------------------------------------------------------

function buildRules() {
  const builder = createGraphRulesBuilder<Relationship, Ctx, Edge>();

  return builder
    .use(
      containedInSectionRule<Relationship, Ctx, Edge>(
        "containedInSection",
        headingLikeSectionContainer,
      ),
    )
    .build();
}

// ---------------------------------------------------------------------------
// Walk the graph tree and collect code cells
// ---------------------------------------------------------------------------

function extractCodeCells(
  roots: readonly Root[],
  labels: readonly string[],
): ExtractedCodeCell[] {
  const results: ExtractedCodeCell[] = [];
  const rules = buildRules();

  roots.forEach((root, docIndex) => {
    const docLabel = labels[docIndex] ?? `doc-${docIndex + 1}`;

    const baseCtx: Ctx = { root };
    const edges = astGraphEdges<Relationship, Edge, Ctx>(root, {
      prepareContext: () => baseCtx,
      rules: () => rules,
    });

    const tree = graphEdgesTree<Relationship, Edge>(edges, {
      relationships: ["containedInSection"],
    });

    const visit = (
      node: GraphEdgeTreeNode<Relationship, Edge>,
      ancestors: GraphEdgeTreeNode<Relationship, Edge>[],
    ) => {
      const md = node.node as Node;

      if (md.type === "code") {
        const codeNode = md as CodeNode;
        const code = typeof codeNode.value === "string" ? codeNode.value : "";

        results.push({
          docIndex,
          docLabel,
          code,
          lang: typeof codeNode.lang === "string" ? codeNode.lang : undefined,
          meta: typeof codeNode.meta === "string" ? codeNode.meta : undefined,
          ancestors,
        });
      }

      for (const child of node.children) {
        visit(child, [...ancestors, node]);
      }
    };

    for (const rootNode of tree.roots) {
      visit(rootNode, []);
    }
  });

  return results;
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

const viewables = await collectRoots(["./qf-complex.md"]);
if (!viewables.length) {
  console.error(gray("No Markdown files to process."));
} else {
  const roots: Root[] = viewables.map((v) => v.root);
  const labels: string[] = viewables.map((v) => v.label);

  const cells = extractCodeCells(roots, labels);

  const perDocCount = new Map<string, number>();

  for (const cell of cells) {
    const baseDocName = sanitizeForFilename(cell.docLabel);
    const key = baseDocName;
    const prev = perDocCount.get(key) ?? 0;
    const next = prev + 1;
    perDocCount.set(key, next);

    console.info(
      green("Found code cell"),
      yellow(`#${next}`),
      gray("→"),
      cell.lang,
      "in",
      baseDocName,
    );
    console.info(
      "      ",
      gray(
        cell.ancestors
          .map((a) => {
            const node = a.node as Node & { type?: string };
            return node.type ?? "(unknown)";
          })
          .join(" → "),
      ),
      "\n",
    );
  }
}
