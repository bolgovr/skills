---
name: observable
description: Structured logging discipline for any language. Use when adding or reviewing log statements, instrumenting a new endpoint, job, or external integration, or shipping a feature that runs in production and needs evidence it works.
---

# Structured Logging

Code you can't observe is code you can't operate. Write logging alongside the feature, the same way you write tests, not after the first incident.

## 1. Start from questions

Before adding a log line, write down 2 to 4 questions an on-call engineer will ask about this feature (e.g. "why did this payment fail permanently?", "did the retry succeed?"). Every log event must help answer one. If you can't name the questions, you will log everything and learn nothing.

## 2. Log events, not prose

Each line is a stable event name plus machine-readable fields, emitted through the language's structured logger (never `print`, string formatting, or interpolation into the message):

```
BAD:  "Payment 123 failed for user 42 after 3 retries"
GOOD: level=warn event=payment_failed payment_id=123 provider=stripe error_code=card_declined attempt=3
```

- Event names are stable identifiers (`payment_failed`), not sentences. Renaming one breaks queries.
- Values go in fields, never baked into the message, so they can be filtered and aggregated.
- Use one output format per sink (JSON is the usual choice).

## 3. Use levels consistently

| Level | Meaning |
|---|---|
| `error` | An invariant broke; someone may need to act |
| `warn` | Degraded but handled (retry succeeded, fallback used) |
| `info` | Significant business event (order placed, job finished) |
| `debug` | Diagnostic detail; off in production by default |

Log an error once, where it is handled, not at every layer it passes through.

## 4. Make every line attributable

- **Correlation ID.** Generate or accept one at the system boundary, attach it to every line, and propagate it across every outbound call and async hop (HTTP headers such as `X-Request-ID` or `traceparent`, queue message metadata). Without it, one request can't be reconstructed from interleaved logs.
- **Entry point.** When several entry points feed one sink (scheduler, webhook, replay endpoint, manual CLI run), stamp an `entry_point` field where the run starts and propagate it with the correlation ID. Never re-derive it downstream: a field that merely correlates with an entry point is a guess, not an attribution.

Prefer the logger's context or child-logger mechanism so these fields are bound once, not repeated at each call site.

## 5. Never log secrets

No tokens, passwords, API keys, auth headers, or unredacted PII. Allowlist fields; never log whole request or response bodies. For external calls, log metadata only: endpoint, status, latency, attempt count, sanitized identifiers. Log pipelines are a classic data-leak path.

## Red flags

- A change adding retries, queues, or external calls with no new log events
- Messages built by string formatting instead of fields
- Lines with no correlation ID
- One sink fed by several entry points with no field saying which one
- Secrets, tokens, or full payloads in output

## Checklist

- [ ] On-call questions are written down and each log event maps to one
- [ ] Output is structured, with stable event names and values in fields
- [ ] Levels follow the table above; each error is logged once
- [ ] Every line carries a correlation ID, propagated across outbound and async boundaries
- [ ] Multi-entry-point sinks carry an entry-point field set at the start of the run
- [ ] No secrets or unredacted PII (spot-check real output, not just the code)
- [ ] An induced failure can be diagnosed from the logs alone, without reading the source
