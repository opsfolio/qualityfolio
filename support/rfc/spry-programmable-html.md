# Spry Programmable HTML – Specification v0.1 (Draft)

> Spry Programmable HTML: The HTML-First Server+Client Component System

## 1. Purpose and scope

Spry Programmable HTML is an HTML-first templating and component model intended for:

* Server-side rendering in Deno/TypeScript.
* Optional client-side enhancement via native Web Components.

Core principles:

* Only use HTML constructs and `data-*` attributes defined by web standards.
* Make templates and components understandable and editable by HTML/CSS designers.
* Let TypeScript supply data and behavior without introducing a new template language.
* Keep a single source of truth: HTML files define layouts, pages, and components.

This document specifies:

* Authoring conventions for HTML templates, layouts, pages, and components.
* The meaning of specific `data-*` attributes.
* The server-side rendering model.
* The client-side Web Component model.
* Integration expectations for Deno/TypeScript engines.

Non-goals for v0.1:

* No general-purpose JavaScript expression language.
* No automatic type inference from templates (this can be added as a separate spec).
* No persistence or routing concerns (out of scope).

---

## 2. Terminology

Spry Programmable HTML uses the following terms:

* Template: Any `<template>` element used for programmable rendering.
* Layout template: A template with `data-nature="layout"`, used as a page frame and using `<slot>` for content insertion.
* Page template: A template with `data-nature="page"`, typically representing a page that can be rendered as a full HTML document.
* Component template: A template with `data-nature="component"`, exposed as a custom element (for example `<user-card>`).
* Partial template: A template with `data-nature="partial"`, meant for reuse but not directly exposed as a custom element.
* Component instance: An element in the DOM whose tag name matches the id (or specified tag) of a component template (for example `<user-card>`).
* Context: The data object supplied by the server or client runtime when rendering a template or component.
* Engine: The Deno/TypeScript implementation that parses HTML, builds an AST, and applies the semantics of this spec.

---

## 3. HTML authoring model

Spry Programmable HTML is authored in standard `.html` files. There are three main constructs:

* Layouts (`<template data-nature="layout">`)
* Pages (`<template data-nature="page">`)
* Components and partials (`<template data-nature="component">`, `data-nature="partial"`)

All logic is encoded via:

* Standard HTML elements (including `<template>` and `<slot>`).
* Custom elements (for component usage).
* `data-*` attributes described below.

### 3.1 Template identification

Each Spry template must:

* Use a `<template>` element.
* Have an `id` attribute unique within its file or template registry.
* Have a `data-nature` attribute with one of:

  * `layout`
  * `page`
  * `component`
  * `partial`

Examples:

```html
<template id="layout.main" data-nature="layout">
  ...
</template>

<template id="page.users" data-nature="page" data-layout="layout.main">
  ...
</template>

<template id="user-card" data-nature="component">
  ...
</template>

<template id="badge" data-nature="partial">
  ...
</template>
```

---

## 4. Layouts and slots

Layouts are templates that define an outer frame and use `<slot>` elements to designate insertion points for page content.

### 4.1 Layout templates

A layout template is defined as:

```html
<template id="layout.main" data-nature="layout">
  <html lang="en">
    <head>
      <title><slot name="title"></slot></title>
    </head>
    <body>
      <header><slot name="header"></slot></header>
      <main><slot></slot></main>
      <footer><slot name="footer"></slot></footer>
    </body>
  </html>
</template>
```

Rules:

* Layouts may contain any HTML under the `<template>`.
* `<slot>` without a name is the default content area.
* Named slots (for example `name="title"`) are used for specific areas such as titles, headers, or sidebars.

### 4.2 Page templates and slots

A page template can reference a layout by setting `data-layout` to the layout id:

```html
<template id="page.users" data-nature="page" data-layout="layout.main">
  <template data-slot="title">Users</template>
  <template data-slot="header">
    <h1>User Directory</h1>
  </template>

  <section>
    <!-- page main content -->
  </section>

  <template data-slot="footer">
    &copy; <span data-bind="year"></span>
  </template>
</template>
```

Rules:

* `data-layout` must refer to an existing `data-nature="layout"` template id.
* Children of a page template with `data-slot="slotName"` are used to fill a slot in the layout whose `<slot name="slotName">`.
* A child of the page template without `data-slot` is used as the default slot content (`<slot>` with no `name`).

Page’s main content is typically one or more elements (for example `<section>`, `<main>`) that do not have `data-slot`.

---

## 5. Component templates and usage

Component templates define reusable visual units that can be used as real custom elements.

### 5.1 Component definition

A component template:

* Uses `<template>`.
* Has `data-nature="component"`.
* Its `id` determines the tag name by default.

```html
<template id="user-card" data-nature="component">
  <article class="user-card">
    <h2 data-bind="name"></h2>
    <p data-bind="email"></p>
    <footer>
      <slot name="footer"></slot>
    </footer>
  </article>
</template>
```

Rules:

* If no other attribute is specified, the component tag name is equal to its `id` (for example `id="user-card"` implies `<user-card>`).
* Component templates may contain:

  * `<slot>` and `<slot name="...">` for projected content.
  * `data-bind`, `data-if`, `data-each`, `data-include` attributes (defined later).

Optional override:

```html
<template id="UserCard" data-nature="component" data-tag="user-card">
  ...
</template>
```

* In this case, `id` is an internal identifier and `data-tag` is the custom element tag.

### 5.2 Component usage

In HTML, a component is used like any other custom element:

```html
<user-card
  name="Ava Martinez"
  email="ava@example.com"
>
  <span slot="footer">Premium user</span>
</user-card>
```

Rules:

* Attributes on the component instance map directly to properties in its render context.

  * Example: `name="Ava"` becomes `ctx.name = "Ava"`.
* Children of the component instance:

  * Elements with `slot="name"` are projected into the component’s `<slot name="name">`.
  * Children without `slot` go into the component’s default `<slot>`.

---

## 6. Partials and includes

Partial templates are reusable fragments that are not themselves custom elements.

### 6.1 Partial definition

```html
<template id="badge" data-nature="partial">
  <span class="badge" data-bind="label"></span>
</template>
```

### 6.2 Including partials

A partial may be included within a layout, page, or component using `data-include`:

```html
<template data-include="badge"></template>
```

Optionally passing properties:

```html
<template data-include="badge" data-props="label:status"></template>
```

Rules:

* `data-include` must refer to a `partial` or `component` template id.
* If `data-props` is present, its values are merged into the context for rendering the included template (details in section 8).

---

## 7. Data binding and control attributes

Spry Programmable HTML uses `data-*` attributes to express imperative logic in a declarative way.

All of these attributes are meaningful only to the engine; in standard HTML they are inert metadata.

### 7.1 Data paths

Many attributes refer to data via a “path” string.

Supported path forms:

* Simple identifier: `user`
* Dotted path: `user.name`, `order.total`
* Index access on arrays: `users[0].name` (optional for v0.1; can be restricted to dotted paths if desired)

For v0.1, the minimal required support is:

* `identifier`
* `identifier.identifier` (any depth)

Array index support is optional; if supported, it uses `identifier[index]`.

Evaluating a path:

* Root object is the current context.
* Each step navigates properties (and optionally indices).
* If any intermediate value is `null` or `undefined`, the path evaluation yields `undefined`.

### 7.2 data-bind

`data-bind` sets an element’s text content based on a context value.

Example:

```html
<span data-bind="user.name"></span>
```

Semantics:

* Evaluate the path in `data-bind`.
* Convert the result to a string.
* Escape HTML-sensitive characters (`&`, `<`, `>`, `"`, `'`).
* Replace the element’s children with a single text node containing the escaped string.

For v0.1:

* `data-bind` is defined only for text content; attribute binding may be introduced later.

If the value is `undefined` or `null`, the element’s children become an empty text node.

### 7.3 data-html (optional)

`data-html` may be used where the engine should insert unescaped HTML.

Example:

```html
<div data-html="article.bodyHtml"></div>
```

Semantics:

* Evaluate the path.
* Interpret the result as an HTML string.
* Parse or insert as raw HTML into the element’s children.
* No escaping is performed.

Use of `data-html` should be limited to trusted content and is considered advanced usage.

If security is a concern, `data-html` can be disabled or restricted by the engine implementation.

### 7.4 data-if

`data-if` conditionally includes or excludes an element and its subtree.

Example:

```html
<li data-if="user.active">
  <span data-bind="user.name"></span>
</li>
```

Expression forms:

* Path only: `user.active`
* Optional unary not: `!user.disabled`
* Optional equality comparison (if enabled): `user.role == 'admin'`

Minimal required for v0.1:

* Path that resolves to a truthy/falsy value.

Semantics:

* Evaluate the condition against the current context.
* If the evaluation is falsy, the element is removed from the output.
* If truthy, the element is retained and its descendants are processed normally.

### 7.5 data-each

`data-each` repeats a fragment for each element in an array.

Defined on `<template>` elements:

```html
<ul>
  <template data-each="user in users">
    <li>
      <span data-bind="user.name"></span>
    </li>
  </template>
</ul>
```

Grammar:

* `item in collectionPath`

Where:

* `item` is the loop variable name.
* `collectionPath` is a path expression resolving to an array.

Semantics:

1. Evaluate `collectionPath` in the current context.
2. If undefined, null, or not an array, treat as empty list.
3. For each element of the array:

   * Create a new child context:

     * Copies all properties from parent context.
     * Adds/overwrites property named `item` with the array element.
   * Render the children of the `<template>` once with the child context.
4. Replace the `<template>` node with the concatenation of all rendered children.

Support for an index variable (for example `user,i in users`) can be added later; v0.1 assumes a single loop variable.

### 7.6 data-include and data-props

`data-include` includes another template inline.

Basic inclusion:

```html
<template data-include="badge"></template>
```

Inclusion with properties:

```html
<template data-include="badge" data-props="label:user.status; kind:user.tier"></template>
```

`data-props` is defined as a semicolon-separated list of `name:expression` pairs.

Minimal form:

* `name:path`

For v0.1, treat `expression` as a path; more advanced expressions may be defined later.

Semantics:

1. Parse `data-props` into key → path mapping.
2. Evaluate each path against the current context.
3. Build a props object.
4. Create a child context:

   * Copies parent context.
   * Overlays values from props object.
5. Render the referenced template with the child context.
6. Replace the `<template data-include>` node with the rendered content.

---

## 8. Context and scope rules

Spry Programmable HTML uses a hierarchical context model.

* The engine starts with a root context supplied by the caller when rendering a layout or page.
* New child contexts are created in the following situations:

  * When rendering a `data-each` loop body.
  * When rendering an included template (`data-include`) or component template.
  * Optionally when applying a layout.

Context inheritance:

* A child context sees all properties of its parent unless overridden.
* New or overridden properties (for example loop variables, props) shadow parent ones with the same name.

For example:

* Root context: `{ users: [...], year: 2025 }`
* Inside `data-each="user in users"` body: context `{ users: [...], year: 2025, user: <one user> }`

---

## 9. Server-side semantics

This section defines how an engine in Deno/TypeScript processes HTML files.

### 9.1 Template registry construction

The engine:

1. Reads one or more `.html` files.
2. Parses each into an HTML AST (for example using rehype-parse / hast).
3. Visits all `<template>` elements and builds a registry keyed by `id`.
4. For each template, stores:

   * id
   * data-nature
   * optional data-layout
   * optional data-tag
   * content subtree

The registry is used for:

* Rendering pages by template id.
* Resolving includes.
* Resolving component templates.

### 9.2 Page rendering

Rendering a page template by id involves:

1. Lookup of the page template in the registry.

2. Cloning its content subtree into a fresh AST root.

3. Applying the transformation pipeline (binding and control attributes) to the page content with the provided root context.

4. If the page template has `data-layout`:

   * Render the page content to an intermediate AST.
   * Render the specified layout template with a context that incorporates:

     * The original root context.
     * Slot contents derived from page `data-slot` children and page main content.
   * Slot replacement semantics:

     * Named slots in the layout are replaced with the corresponding content.
     * The default slot receives the main page content.

5. The result is a complete AST for the document (usually containing `<html>`).

Finally the engine serializes this AST to an HTML string.

### 9.3 Component expansion (server-side) – optional

There are two possible server strategies:

* Full expansion: expand component instances into plain HTML.
* Deferred: keep component tags as-is and rely on client runtime.

The v0.1 spec defines full expansion semantics; an engine may optionally expose a mode to skip component expansion.

When expanding components:

1. Build a component template registry (subset of templates with `data-nature="component"`).

2. Traverse the AST for the rendered page or layout.

3. For each element whose tag name matches a component tag:

   * Build a context from:

     * Root page context.
     * Attributes on the component element, mapping attribute names to string values.
   * Clone the component template content.
   * Perform slot distribution:

     * For each `<slot name="X">`:

       * Replace it with clones of children from the component instance that have `slot="X"`.
       * If there are no such children, slot may remain empty or use fallback content in the template.
     * For `<slot>` with no name:

       * Replace it with clones of children with no `slot` attribute.
   * Apply the transformation pipeline to the component subtree with the context.
   * Replace the component element with the resulting subtree.

4. Continue traversal until all component instances are processed.

---

## 10. Client-side semantics

On the client, the same HTML templates can be used to define real Web Components. This is optional but recommended.

### 10.1 Component registration

A client runtime script:

1. Waits for DOMContentLoaded.
2. Selects all `<template data-nature="component">`.
3. For each:

   * Determines tag name:

     * Tag = template’s `data-tag` if present, otherwise the `id`.
   * Defines a custom element class that:

     * Attaches a shadow root.
     * Clones the template content into the shadow root.
     * Builds a context from its attributes and possibly other data sources.
     * Applies binding semantics in its shadow root (using `data-bind`, `data-if`, `data-each`, `data-include`).

Attributes:

* All attributes on the component instance become context string properties by name.
* Further enhancements (parsing JSON, numbers, booleans) may be supported by conventions (for example `data-type-*`), but are outside v0.1.

### 10.2 Slot behavior (client)

Slot behavior follows standard shadow DOM rules:

* Children of the component instance with `slot="name"` are projected into `<slot name="name">` in the shadow root.
* Children without `slot` go into the default `<slot>`.

The runtime may choose to run data binding logic after slot distribution, or treat slots as purely structural while `data-bind` is processed on the shadow tree.

---

## 11. Escaping, security, and XSS

By default, Spry Programmable HTML is designed to be safe for typical uses.

* `data-bind` always produces escaped text.
* `data-if`, `data-each`, `data-include` do not introduce raw HTML; they operate on AST structures.
* `data-html` is the only mechanism that can introduce unescaped HTML; it should be considered advanced and must only be used with trusted content.

Engine implementation guidelines:

* Always escape special HTML characters when inserting text from arbitrary data.
* Consider disabling `data-html` by default or providing a configuration flag.
* Always treat user-provided data as untrusted by default.

---

## 12. Error handling and diagnostics

The engine should detect and report errors clearly. Recommended diagnostics:

* Missing template:

  * When `data-layout` or `data-include` refers to a non-existent template id.
* Invalid nature:

  * When a template has unknown `data-nature`.
* Invalid `data-each` syntax:

  * Malformed string that does not match `identifier in path`.
* Invalid path:

  * Path syntax errors; at minimum, engine should detect obviously invalid forms.
* Component conflicts:

  * Duplicate component tag names or ids.

Error messages should include:

* File or template id where the error occurred.
* Node location (if available from AST).
* The offending attribute value.

---

## 13. TypeScript integration guidelines

Although not strictly part of the HTML spec, Spry Programmable HTML is designed to integrate well with TypeScript.

Recommended patterns:

* Define a mapping from template ids to context types:

  ```ts
  type TemplateContexts = {
    "layout.main": { title: string; header?: string; footer?: string; year: number };
    "page.users": { year: number; users: { name: string; email: string; status: string; active: boolean }[] };
    "user-card": { name: string; email: string; status?: string };
    "badge": { label: string };
  };
  ```

* Expose an engine interface:

  ```ts
  interface TemplateEngine<T extends Record<string, unknown>> {
    render<K extends keyof T>(id: K, context: T[K]): Promise<string>;
  }
  ```

* Consider code generation tools that:

  * Parse templates.
  * Extract `data-bind`, `data-each`, and `data-props` usage.
  * Generate or validate TypeScript context types.

This integration is advisory and can evolve in a separate document.

---

## 14. Versioning and extensibility

This document describes Spry Programmable HTML v0.1.

Possible future extensions (explicitly out of scope here):

* Attribute-level bindings (for example `data-bind-src="imageUrl"`).
* Supporting index variables in `data-each` (for example `item, index in items`).
* Richer condition expressions in `data-if` (`&&`, `||`, comparisons).
* Importing data from external sources declared in HTML metadata.
* Dedicated accessibility helpers and ARIA-related patterns.

Extensions must preserve:

* HTML validity.
* The principle that all new semantics are expressed via `data-*` attributes or existing HTML constructs.
* Backward compatibility where possible.

---

# Analysis of Alternatives (`AoA`)

There are *many* HTML templating engines and *many* Web Component frameworks — but **no existing open-source library implements the exact model of Spry Programmable HTML**, because your approach combines:

* **Pure HTML templates using only web-standard constructs** (`<template>`, `<slot>`, `data-*`)
* **Server-side AST transforms using unist/hast**
* **Automatic dual-mode Web Component simulation (server + client)**
* **Fully programmable logic (loops, conditionals, includes) expressed ONLY through `data-*` attributes**

This combination is unique.
But there *are* projects that come **close in spirit**, each covering *one or two* pieces of what Spry Programmable HTML aims to accomplish.

Below is a curated overview of the closest relatives.

---

# ✔️ 1. Libraries somewhat similar — closest in spirit

## **🟩 1. Alpine.js**

**Closest match for the “HTML-only, data-* driven logic” idea.**
Not server-side though.

* Uses `x-for`, `x-if`, `x-bind`, etc. (attribute-based logic)
* Works inside static HTML files
* No AST, no server-side rendering, no Web Component integration

**Spry difference:**
Spry is **server-first**, pure HTML (no new attributes), and AST-driven. Alpine is **client-only** and invents new attribute dialects.

---

## **🟩 2. htmx**

Similar because it pushes semantics into HTML with attributes.

* `hx-get`, `hx-target`, `hx-swap`
* HTML-driven UI, progressive enhancement
* No templating engine or SSR templating model

**Spry difference:**
Spry adds *full server-side rendering, layout composition, components, loops, conditionals, partials*, etc.

---

## **🟩 3. Marko (by eBay)**

Closest server-side Web Component–like templating.

* Compiles templates into Web Components
* Supports SSR hydration
* HTML-ish syntax, but not pure HTML (introduces own syntax)

**Spry difference:**
Spry mandates **strict HTML** with `data-*` only.
Marko introduces non-standard tags and compile-time syntax.

---

## **🟩 4. Stencil.js**

Builds Web Components from templates and TS.

* Generates standards-compliant Web Components
* Uses shadow DOM and slots
* Has SSR modes (limited)

**Spry difference:**
Stencil uses `.tsx` and decorators, **not HTML templates**.
Spry components are **defined as `<template>` in HTML**.

---

## **🟩 5. Lit (Google)**

Web Component compiler/runtime.

* Components defined in JS using template literals
* Shadow DOM + slots
* SSR rendering is possible

**Spry difference:**
Lit **does not parse HTML files**; templates are JS-string-based.

---

## **🟩 6. Squirrelly, Eta, Nunjucks, Liquid, EJS**

Template engines, but:

* All invent custom syntax (`{{ }}`, `{% %}`, etc.)
* Not HTML-pure
* No Web Component integration
* No AST transformations
* No standard `<template>` usage

**Spry difference:**
Spry **never** introduces any syntax other than standard HTML and `data-*`.

---

## **🟩 7. WebC (Astro’s “Web Components in HTML”)**

This is **the closest match in the entire ecosystem.**

* One file can contain multiple components defined in HTML
* `<template>`-centric
* Uses “frontmatter-like” annotations in HTML comments
* Allows **server-side components**
* Produces Web Components on the client

**BUT — big differences:**

* Uses non-standard directives inside HTML comments for logic
* Uses a build compiler (not runtime AST)
* Not loops/conditionals via `data-*`
* Not AST-driven like unist/hast
* Doesn’t enforce pure specification alignment the way Spry does

Spry Programmable HTML is **more general, cleaner, and spec-compliant.**

---

# ✔️ 2. Libraries specifically using unist/hast to manipulate HTML

These libraries use the same AST ecosystem you’re using:

### **rehype (UnifiedJS ecosystem)**

* The HTML equivalent of remark/mdast
* Allows custom AST transforms
* Lets you fully implement Spry’s SSR model

But **rehype itself has no templating logic**.

### **hastscript**

* Helps build HTML AST nodes
* Foundation for your server engine

### **rehype-stringify**

* Serializes AST back to HTML

### **vfile**

* Useful for integrating metadata (e.g., template registry)

Spry becomes **the first templating engine built on top of rehype/hast**.

---

# ✔️ 3. Libraries using HTML templates + slots + shadow DOM

### Native Web Components

Browser-only; no SSR, no AST.

### Hybrids.js

Simplified Web Component definitions, no HTML file parsing.

### Slim.js

Custom syntax, not standard HTML-only.

### SkateJS

More ergonomic Web Components API.

None stay **strictly HTML-only** like Spry.

---

# ✔️ 4. Libraries that treat HTML as the “template language”

## **11ty (Eleventy)**

Allows HTML to be used as templates but:

* Uses Nunjucks/Liquid/etc. for logic
* Not pure HTML

## **WMR / Preact HTML SSR**

HTML used heavily but not as templates with Web Component semantics.

---

# ✔️ 5. Summary Table

| Library                    | Pure HTML templates | Only data-*          | Native `<template>` | SSR     | Web Components | AST-based       |
| -------------------------- | ------------------- | -------------------- | ------------------- | ------- | -------------- | --------------- |
| **Spry Programmable HTML** | ✔️                  | ✔️                   | ✔️                  | ✔️      | ✔️ (automatic) | ✔️ (unist/hast) |
| Alpine.js                  | ✔️                  | ❌ custom attrs       | ✔️                  | ❌       | ❌              | ❌               |
| htmx                       | ✔️                  | ❌ custom attrs       | ❌                   | ❌       | ❌              | ❌               |
| Marko                      | ❌ custom syntax     | ❌                    | ❌                   | ✔️      | ✔️             | ❌               |
| Lit                        | ❌ uses JS templates | ❌                    | ❌                   | ✔️      | ✔️             | ❌               |
| Stencil                    | ❌ TS decorators     | ❌                    | ❌                   | partial | ✔️             | ❌               |
| WebC                       | ✔️ (closest)        | ❌ comment directives | ✔️                  | ✔️      | ✔️             | ❌               |
| EJS/Nunjucks/etc.          | ❌                   | ❌                    | ❌                   | ✔️      | ❌              | ❌               |
| rehype/unist               | N/A                 | N/A                  | N/A                 | N/A     | N/A            | ✔️              |

**Conclusion:
Spry Programmable HTML is unique — nothing open-source currently does exactly this.**

It combines:

* HTML-only authoring using `data-*`
* `<template>`-based components
* Automatic server-side component expansion
* Optional client-side native Web Component generation
* Rehype/hast AST transforms
* Strict compliance with HTML standards
* No new syntax

This is novel.

---

# AI Prompt

Here’s a prompt you can paste into another AI to get the implementation started.

---

You are an expert Deno 2.5 + TypeScript architect and library designer. Your task is to implement a production-quality, type-safe, generics-enabled, secure, ergonomic library that implements the “Spry Programmable HTML” spec described below.

High-level goals

* Implement a server-side and optional client-side rendering engine for “Spry Programmable HTML”.
* Use only web standards based HTML: `<template>`, `<slot>`, custom elements, and `data-*` attributes.
* Use Deno 2.5 and modern TypeScript with strong generics and type inference.
* Provide a great ergonomics and DX for library consumers, including:

  * Type-safe template registries and context objects.
  * Functional-style APIs (pure functions wherever possible, minimal global state).
  * Clear, structured error messages.
* Keep the `data-*` DSL intentionally tiny but expressive:

  * A very small set of attributes (data-bind, data-if, data-each, data-include, data-slot, data-layout, data-nature, data-tag, data-props).
  * Near-infinite flexibility is achieved via TypeScript functions and type-safe objects, not via an expression-heavy DSL.
* Ensure security by default:

  * Proper escaping for any text inserted into HTML.
  * Clear boundaries for any potential unescaped HTML insertion.

Runtime environment and tooling

* Target: Deno 2.5+ with TypeScript strict mode.
* Use JSR modules for dependencies where appropriate (for example unified, rehype-parse, rehype-stringify, unist utilities, vfile).
* No Node-specific APIs; use Deno APIs only.
* Code should be structured as a reusable library that can be imported by other Deno projects.

Spry Programmable HTML summary

Implement the core of the previously defined “Spry Programmable HTML” spec with the following core ideas:

1. Templates are defined using `<template>` tags with:

   * `id` (unique within a registry).
   * `data-nature` in: "layout" | "page" | "component" | "partial".
   * Optional `data-layout` (for pages that use a layout).
   * Optional `data-tag` (for components where tag name differs from id).

2. Layouts:

   * `<template id="layout.main" data-nature="layout">` contains a full document frame:

     * Typically `<html>`, `<head>`, `<body>`, etc.
   * Uses `<slot>` and `<slot name="...">` for content insertion.

3. Pages:

   * `<template id="page.users" data-nature="page" data-layout="layout.main">`.
   * Child `<template data-slot="name">` elements fill named slots in the layout.
   * Content without `data-slot` is used for the default `<slot>` in the layout.

4. Components:

   * `<template id="user-card" data-nature="component">` defines a component.
   * Component tag name by default equals `id` (e.g., `<user-card>`).
   * Optionally overridden by `data-tag="user-card"`.
   * Component templates use `<slot>` and `<slot name="...">` for projected content.
   * Component usage is natural Web Components style:

     * `<user-card name="Ava" email="ava@example.com"><span slot="footer">VIP</span></user-card>`
   * Attributes on component instances map to context properties (name, email, etc).

5. Partials:

   * `<template id="badge" data-nature="partial">` defines a reusable fragment.
   * Included via `data-include="badge"`.

6. Data DSL (tiny but expressive, all via data-* attributes):

   * `data-nature`: "layout" | "page" | "component" | "partial".
   * `data-layout`: references an id of a layout template on a page template.
   * `data-slot`: marks children of a page template to be inserted into layout slots.
   * `data-bind`: simple data path → textContent binding (escaped).

     * Example: `<span data-bind="user.name"></span>`
   * `data-if`: condition to include or exclude an element.

     * Minimal support: path that resolves to truthy or falsy, e.g. `user.active`
   * `data-each`: loops defined on `<template>`:

     * Form: `item in itemsPath`
     * Example: `<template data-each="user in users"> ... </template>`
   * `data-include`: includes partials or component templates:

     * `<template data-include="badge">...</template>`
   * `data-props`: defines props when including:

     * Minimal safe form: `key:path; key2:path2`
     * Example: `data-props="label:user.status; kind:user.tier"`

7. Context rules:

   * The engine starts with a root context provided by the caller.
   * `data-each` introduces a loop variable in a child context.
   * `data-include` introduces props in a child context.
   * Components are rendered with a base context + attributes-provided props.

8. Security:

   * `data-bind` must always escape HTML.
   * Only one optional risky escape path should exist (e.g. `data-html`), and it should be clearly documented and easy to disable.
   * No arbitrary JS in templates; paths must be restricted to simple identifiers and dotted paths (e.g., `user`, `user.name`, `order.total`).

Type system and generics requirements

Design the library to be type-safe and generics-enabled:

1. Template contexts:

   * Define a generic mapping from template IDs to context types:

     * Example:

       ```ts
       type TemplateContexts = {
         "layout.main": { title: string; year: number; header?: string; footer?: string };
         "page.users": { year: number; users: User[] };
         "user-card": { name: string; email: string; status?: string };
         "badge": { label: string; kind?: string };
       };
       ```

   * Consumers should be able to declare such a mapping and pass it to the engine generically.

2. Engine interface:

   * Provide an interface like:

     ```ts
     interface SpryHtmlEngine<TContexts extends Record<string, object>> {
       render<K extends keyof TContexts>(id: K, context: TContexts[K]): Promise<string>;
       // Optionally: renderToAst<K extends keyof TContexts>(...)
       // Optionally: renderComponentInstance(...)
     }
     ```

   * Ensure type safety:

     * Calling `render("page.users", { ... })` must require the correct context shape.
     * Calling with missing or wrong properties should be a TypeScript error.

3. Template registry:

   * Provide a generic builder that loads one or more HTML files and annotates them with type information:

     ```ts
     function createSpryHtmlEngine<TContexts extends Record<string, object>>(options: {
       sources: string[]; // file paths or generic sources
       // plugin hooks, options, etc.
     }): Promise<SpryHtmlEngine<TContexts>>;
     ```

   * The engine can remain runtime-flexible, but TypeScript generics should give compile-time safety for known templates.

4. Data path typing:

   * For v1, you can treat paths like `user.name` as runtime-only but provide:

     * A small helper type or function that strongly encourages mapping paths to known keys.

   * Optionally, you can expose a typed path helper:

     ```ts
     type PathFor<T> = ... // optional advanced feature
     ```

   * Focus mainly on secure runtime handling, but keep the API open to future typed path inference.

5. Functional programming style:

   * Design the core transformation pipeline as a series of pure functions:

     * `resolveEach(root, ctx, registry) -> Root`
     * `resolveIf(root, ctx) -> Root`
     * `resolveInclude(root, ctx, registry) -> Root`
     * `resolveBind(root, ctx) -> Root`
     * `applyLayout(pageRoot, layoutTemplate, ctx) -> Root`
     * `expandComponents(root, ctx, registry) -> Root`

   * These functions should not rely on mutable singletons or global registries.

   * Data for each pass is passed as arguments; results are returned as new structures or mutated ASTs with clearly documented behavior.

DSL to TypeScript function mapping

The core requirement is that the `data-*` DSL is tiny, but the underlying behavior is served by type-safe functions and configuration objects in TypeScript.

Design a small, extensible registry for behavior:

1. A central “behavior” or “semantics” interface (rough sketch):

   ```ts
   interface SpryBehavior {
     resolveBind(ctx: unknown, path: string): string;  // returns escaped HTML-safe string
     resolveIf(ctx: unknown, expr: string): boolean;
     resolveEach(ctx: unknown, spec: string): Iterable<[itemName: string, childCtx: unknown]>;
     resolveInclude(ctx: unknown, templateId: string, propsSpec?: string): { childCtx: unknown };
     // Optionally allow custom data-* handlers
   }
   ```

2. Provide a default implementation that:

   * Only supports safe, minimal path resolution and basic condition checks.
   * Does not allow arbitrary JS evaluation.
   * Treats `expr` in data-if as:

     * A simple path, or
     * Optional negation: `!path`.

3. Make the behavior configurable:

   * The consumer can supply a custom `behavior` object implementing the same interface.
   * This is how “near-infinite flexibility” is achieved: behavior is in TS, templates stay simple.

4. Ensure the behavior interface itself is type-safe:

   * Use generics to tie the context type to behavior where possible.

Directory and module structure

Design a clean module layout. For example:

* `mod.ts`: public API entry point.
* `engine/`:

  * `engine.ts`: main `createSpryHtmlEngine` implementation.
  * `registry.ts`: template registry and loading (using Deno.readTextFile or generic sources).
  * `render.ts`: orchestration of passes for rendering a template to HTML.
* `ast/`:

  * `parse.ts`: wrappers around rehype-parse.
  * `stringify.ts`: wrappers around rehype-stringify.
  * `transforms/`:

    * `bind.ts` (data-bind)
    * `if.ts` (data-if)
    * `each.ts` (data-each)
    * `include.ts` (data-include + data-props)
    * `layout.ts` (data-layout + data-slot + slots)
    * `components.ts` (component expansion)
* `behavior/`:

  * `default.ts`: default SpryBehavior implementation.
  * `types.ts`: behavior interfaces, path-evaluation helpers.
* `client/`:

  * `web-components.ts`: optional client runtime to turn component templates into real Web Components via `customElements.define`.
  * `bindings.ts`: lightweight browser-side `data-bind`, `data-if`, `data-each` application inside shadow roots.

Implementation details and constraints

Please implement:

1. HTML parsing and stringification with rehype/hast:

   * Parse .html to a `Root` AST.
   * Build a template registry holding:

     * id
     * data-nature
     * data-layout or data-tag where applicable
     * content subtree.

2. Rendering pipeline:

   * `render(templateId, context)`:

     * Find template by id.
     * Assert its nature is allowed to be rendered as root (e.g., page or layout).
     * Clone its content AST.
     * Apply transforms in a safe order:

       1. resolveEach
       2. resolveIf
       3. resolveInclude
       4. resolveBind
       5. expandComponents (optional for server mode)
       6. applyLayout (if data-layout is used).
     * Serialize to HTML string.
   * Document the transform order and make it configurable if appropriate.

3. Component expansion (server side):

   * Discover component templates via `data-nature="component"`.
   * When a component instance (e.g., `<user-card>`) is found:

     * Build a component context from:

       * Parent context.
       * Its attributes (name/value pairs mapped to context).
     * Perform slot distribution into the component template AST.
     * Run the standard transforms inside the component subtree.
     * Replace `<user-card>` with the rendered subtree.

4. Client runtime for Web Components:

   * A small JS module that:

     * On DOMContentLoaded, finds all `<template data-nature="component">`.
     * Defines a custom element class per component using `customElements.define`.
     * Each component:

       * Attaches a shadow DOM.
       * Clones template content into it.
       * Builds a context from instance attributes.
       * Applies `data-bind`, `data-if`, `data-each`, `data-include` inside shadow root.
     * Uses standard `<slot>` behavior for children.

5. Security and escaping:

   * Implement a safe HTML-escaping function for use with `data-bind`.
   * Treat all data as untrusted by default.
   * Provide a clearly labeled, optional `data-html` (or similar) that inserts unescaped HTML and document its risk.
   * Do not eval or Function any strings; expression evaluation is limited and controlled.

Developer experience and ergonomics

Focus heavily on DX:

1. TypeScript:

   * Use strict mode, readonly props where appropriate, discriminated unions for template types, and generics for contexts.
   * Provide well-documented public types (e.g., `SpryHtmlEngine`, `TemplateRegistry`, `TemplateContextMap`).

2. Errors:

   * When a template id is not found, throw an error with:

     * Template id.
     * Known template ids.
   * When data-nature is invalid or missing but required, throw a clear error.
   * When data-each or data-props strings are malformed, include:

     * Offending string.
     * Template id.
     * Optional node position if available from AST.

3. Logging:

   * Avoid noisy logging in the library; instead:

     * Provide hooks or options to plug in a logger or debug function.

4. Testing:

   * Write robust tests for:

     * Basic binding (data-bind).
     * Conditionals (data-if).
     * Loops (data-each).
     * Includes and props (data-include + data-props).
     * Layouts and slots (data-layout, data-slot, `<slot>`).
     * Components SSR expansion and client runtime.
   * Tests should run via Deno’s native test runner.

5. Documentation (inline and minimal markdown):

   * Use TSDoc/JSDoc comments on all public APIs.
   * Optionally provide a small README-style markdown string example that:

     * Shows how to define templates in HTML.
     * Shows how to define TemplateContexts.
     * Shows how to create the engine and render a page.

Final deliverables

* A set of TypeScript modules implementing:

  * The template registry and parsing.
  * The rendering engine with functional transforms.
  * The behavior interface and default behavior.
  * The optional client-side Web Component runtime.
* Strongly typed, generics-enabled public APIs as described.
* A minimal set of well-structured tests demonstrating:

  * Layout + page + component + partial.
  * All supported data-* attributes in realistic examples.
* Good inline documentation and error messages.

Please now:

1. Propose the final public API (types and functions) as you recommend it.
2. Implement the library in idiomatic Deno 2.5 TypeScript across multiple modules.
3. Provide example HTML templates and a Deno test that exercises the full pipeline.
4. Explain any design tradeoffs you make (e.g., transform order, behavior configuration) in comments so a future maintainer can understand and extend it.

