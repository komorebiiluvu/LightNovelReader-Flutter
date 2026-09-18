# F3.4.2 HTML Parser Foundation

Status: **IMPLEMENTED / HUMAN REVIEW REQUIRED**

This slice provides generic HTML parser infrastructure only. It does not parse
any provider's selectors or construct domain identity, and it does not start
the next runtime slice.

## Boundary

The parser boundary is:

```text
DecodedDocument
       |
       v
HtmlDocumentParser
       |
       v
ParsedHtmlDocument
```

`HtmlDocumentParser.parse` accepts only the source-neutral charset layer's
`DecodedDocument`. Raw bytes, transport responses, locators for requests,
session state, and streams are outside this API. Charset selection and error
handling are complete before HTML parsing begins.

The approved `html: 0.15.7` package is imported only by
`lib/src/source/html/`. Its `Document`, `Element`, `Node`, and other DOM types
are consumed inside that infrastructure and never appear in the output models,
domain models, source contracts, features, or UI.

## Output model

`ParsedHtmlDocument` contains:

* optional title evidence;
* one immutable ordered pre-order sequence of project-owned nodes;
* the traversed DOM node count.

The normalized node variants are `ParsedHtmlText`, `ParsedHtmlImage`, and
`ParsedHtmlLink`. Text nodes retain conservative line-boundary normalization
(`CRLF` and `CR` become `LF`) while preserving meaningful spaces. Image and link
nodes retain the raw `src` or `href` locator, including relative, absolute, and
protocol-relative values. No locator is resolved, fetched, cached, or assigned a
domain identity.

Each normalized node retains its DOM depth. Together with the ordered sequence,
this preserves text order, image position, node type, and nesting information
without leaking the package DOM.

## Limits and memory boundary

`HtmlParserLimits` is immutable and injectable. Defaults are:

| Limit | Default |
| --- | ---: |
| DOM traversal depth | 64 |
| traversed DOM nodes | 100,000 |
| produced normalized nodes | 100,000 |
| individual text payload | 1 MiB UTF-8 bytes |

The `html` package constructs its DOM before this traversal runs. These limits
therefore bound deterministic traversal and normalization work, but they are
not the primary memory defense. Transport byte limits and decoded-document size
limits must remain upstream controls.

Limit failures are typed and expose only a constant limit name and safe counts.
Invalid decoded Unicode, unrecoverable parser structure, and unexpected parser
failures have distinct typed categories. Exceptions from the package, DOM
objects, the HTML body, and large payloads never escape or appear in
diagnostics.

## Evidence

Generic fixtures and focused tests cover basic text, title evidence, nested
order, whitespace boundaries, comments, empty input, HTML5 recovery, all
locator forms, injected limits, generated depth greater than 64, generated
node counts above 100,000, invalid decoded text, package isolation, and safe
diagnostics. The parser uses the package's HTML5 recovery behavior and adds no
handwritten correction rules.

Provider-specific parsing, request construction, source runtime behavior,
network integration, persistence, and reader integration remain deferred.
