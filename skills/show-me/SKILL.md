---
name: show-me
description: "Explain a domain, data, or programming concept as an interactive HTML page, grounded in the current repo when the topic lives there."
disable-model-invocation: true
argument-hint: "<concept | path | question>"
---

The user wants to understand something by seeing it. Build one HTML page whose picture does the explaining, and open it in their browser. The topic is the argument: a concept ("backpressure"), a thing in this repo ("how an order becomes an invoice", `src/billing/`), or a dataset ("what's in `events.parquet`"). With no argument, take the topic from the conversation, or ask.

You only explain. Never edit project code, and never write the page into the repo unless the user asks for it there.

## 1. Ground it

Look in the repo before anything else, even when the topic sounds generic: "show me our retry logic" and "show me exponential backoff" may be the same page. Check `CONTEXT.md` and the ADRs for domain vocabulary, then search the code, schemas, tests, and data files for the topic.

- **It lives here.** Read the real thing: the code path, the schema, the actual rows. The page uses the repo's own names, values, and file paths, because a reader who goes from the page to the code should recognise what they find. Tests are a good source of realistic example inputs.
- **It doesn't.** Explain the general concept with a small invented example that feels real (named customers and plausible amounts, not `foo` and `x`).
- **Both.** When the repo implements a general concept, lead with how it works here and use the general concept as the frame.

Anything you put on the page as fact about the repo, you have read. If you could not find or verify a piece, say so on the page or leave it out; a confident diagram of a flow that doesn't exist is worse than no diagram.

For a dataset, profile it first (shape, types, distributions, nulls, outliers) with whatever is at hand (`duckdb`, `sqlite3`, `python3`, `jq`), so the page shows what is actually in the data and not what the column names suggest.

## 2. Find the one question

Write down, for yourself, the single question the page answers and the misconception or gap it closes ("why does a late event still land in the right window?"). Everything on the page serves that question. If the topic is too broad for one question ("show me the billing domain"), pick the overview question (what are the pieces and how do they relate?) and let the reader drill into parts, or ask the user which part they care about.

Then pick the form from the shape of the idea, not from what is easy to draw:

| The idea is about | Form that shows it |
| --- | --- |
| Steps over time (an algorithm, a request, a lifecycle) | A step-through: play, step, scrub, with the state drawn at each step and the active line or actor highlighted |
| Messages between actors (a protocol, a saga, a race) | A sequence or swimlane view the reader can advance, including the failure branch |
| States and transitions (an order, a connection, a parser) | A state diagram the reader drives by firing events |
| Structure (modules, entities, a schema, a tree) | A node and edge diagram with detail on hover or click, laid out so position means something |
| A parameter or trade-off (cache size, batch window, learning rate) | An explorable: a slider or input wired to a live picture of the consequence |
| Two ways of doing one thing | Side by side on the same input, in sync |
| A dataset | Charts chosen for the question (distribution, trend, breakdown), with filtering, over the real values |
| A transformation (a pipeline, a query, a map and reduce) | The same few rows followed through every stage |

Mix forms when the idea has more than one shape, but one stays the centrepiece.

## 3. Build the page

**Lead with the picture.** The main visual sits at the top, usable without reading anything first. Prose is short and sits next to the part of the picture it explains. If the page would read the same with the visual deleted, it is an article, and the user asked to be shown.

**Run one concrete example all the way through.** A specific order, a specific array, five specific rows. Abstract boxes labelled "Service A" teach nothing; watching order #1042 get rejected at the credit check does.

**Make the interaction carry the mechanism.** Good interaction lets the reader change a cause and watch the effect: step forward, drag the slider, kill the node, send the duplicate message. Include the case where it goes wrong, since that is usually where understanding comes from. Skip interaction that only decorates (entrance animations, hover glows), and give every animation manual controls so the reader sets the pace.

**Say what they are looking at.** A title that states the question, a one-sentence answer under it, a legend for every encoding (colour, shape, position), units on every axis, and a "what to try" hint beside each control. For repo topics, show the source file paths so the reader can go and read the code.

**Mark what is real.** If some values come from the repo and some are invented for illustration, label the invented ones. If a data page shows a sample or an aggregate, say which and how many rows it stands for.

### The file

- One `.html` file with inline CSS and JS. Embed data in the page as a JS literal: `fetch` of a local file fails on `file://`.
- Hand-written SVG, canvas, and plain JS are enough for most pages and keep full control over the picture. Pull a library from a CDN when it does real work: D3 for layouts and scales, Chart.js or Observable Plot for standard charts, Mermaid for a quick static graph, highlight.js for code. Pin an exact version in the URL so the page still works next month.
- Readable in light and dark (`prefers-color-scheme`), and at laptop width without horizontal scrolling. Do not encode meaning in colour alone.
- Keep embedded data small: sample or aggregate large datasets (a few thousand points is plenty), and never embed secrets, credentials, or personal data. Replace or aggregate them.
- Controls work with the keyboard (real `<button>` and `<input>` elements), with arrow keys for stepping where it fits.

## 4. Check, then open

A page that throws on load shows the user a blank screen, so check before opening it:

1. Write it to `${TMPDIR:-/tmp}/show-me/<topic-slug>.html`. If that name exists, add a numeric suffix; an earlier page may still be open in a tab.
2. Syntax-check the inline scripts (extract them and run `node --check`, if node is available).
3. If a browser tool is available (a headless browser, a browser MCP, Playwright), load the page, read the console for errors, and look at a screenshot: is the main visual actually drawn, do labels overlap, does stepping change the picture? Fix what you find.
4. Open it: `open <file>` on macOS, `xdg-open <file>` on Linux.

## 5. Report

In chat, give: the path, the question the page answers with its one-sentence answer, what to try first, and what is real versus illustrative. Name anything you could not verify. Don't paste the HTML.

Then ask whether it landed. The usual follow-ups are a deeper look at one part, a different example, or keeping the page (offer to copy it into the repo wherever they want it).
