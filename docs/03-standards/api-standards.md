---
title: "API Standards"
document_type: Standard
status: Approved
version: 1.0
owner: Ahmed (Lead API Architect)
last_updated: 2026-08-03
---

# API Standards
## Hotel Hall Booking Management System

This document defines the official REST API standards for the entire platform. **Every API
endpoint developed for this project must comply with this document.**

> **Relationship to other documents:** `Architecture-Principles.md` §8 already states the
> API *principles* (RESTful, versioned, documented, consistent formats, stateless,
> standard errors) — this document is their full operational contract: exact status codes,
> exact response shapes, exact pagination and filtering conventions. `naming-conventions.md`
> §9 already governs endpoint/field *naming*; this document does not repeat it, only
> extends it into behavior. `coding-standards.md` §5, §9, §11 already govern layering, error
> handling, and validation *inside* the backend; this document governs what crosses the
> wire, not how the backend is internally organized.

---

## 1. Purpose

The backend serves three clients — the Customer app, the Hotel Manager app, and (per
`BDR-007`) the Platform Administration web dashboard — plus, eventually, external
integrations. Every one of those clients is built and maintained separately from the
backend. A REST API standard exists so that:

- **Flutter and React integration is predictable** — a developer building against a new
  endpoint already knows its shape before reading its Technical Design, because every other
  endpoint behaves the same way.
- **Errors are handled once**, not per-endpoint, on both the backend (`coding-standards.md`
  §9) and every client that consumes it.
- **AI-generated endpoints and AI-generated client code agree** — an AI session writing a
  Flutter API client and one writing the Express endpoint it calls produce compatible code
  without needing to coordinate, because both are following the same written contract.
- **The API documents itself** (§16) — a contract this precise is what makes accurate
  OpenAPI documentation possible instead of aspirational.

---

## 2. REST Principles

Full rationale is `Architecture-Principles.md` §8. Applied concretely:

- **Resource-oriented endpoints.** A URL identifies a *thing* (`/bookings`), never an
  *action* (`/createBooking`). What happens to the resource is expressed by the HTTP method
  (§5), not the URL.
- **Stateless communication.** Every request carries everything needed to process it
  (including the JWT, §12) — the server holds no per-client session between requests.
- **Proper HTTP methods.** §5 defines exactly which method does what; a method is never
  used against its semantics (e.g. a `GET` that changes data).
- **Predictable URLs.** Given the resource-naming rules in `naming-conventions.md` §9, a
  developer can guess an endpoint's URL correctly before looking it up.
- **Idempotency where appropriate.** `GET`, `PUT`, `DELETE` are idempotent — calling them
  twice with the same input produces the same end state. `POST` is not idempotent by
  default; where an operation must be safely retryable (e.g. Booking creation from a mobile
  client with flaky connectivity), the endpoint's Technical Design specifies an idempotency
  key mechanism explicitly — it is never assumed.

---

## 3. API Versioning

Every endpoint is versioned in the URL path: `/api/v1/...`, per `technology-stack.md`.

- **v1 is the current and only version** until a breaking change is needed.
- **A new version (`/api/v2/...`) is introduced only for breaking changes** — a new
  optional field, a new endpoint, or a relaxed validation rule is not a breaking change and
  ships within `v1`.
- **Both versions run in parallel during a migration window** when a `v2` is introduced;
  `v1` is never deleted out from under a client still using it without a documented
  deprecation period.
- Introducing a new version is a significant architectural decision and requires an ADR
  (`Decision-Making-Principles.md` §7), the same as any other breaking API change
  (`Architecture-Principles.md` §15, Evolution Principles).

---

## 4. URL Naming Standards

Full detail is `naming-conventions.md` §9. Summary:

```
/api/v1/hotels
/api/v1/bookings
/api/v1/payments
```

- **Nouns, never verbs** — the resource is the noun; the HTTP method is the verb (§5).
- **Plural resource names** — matching the backend module naming already established in
  `naming-conventions.md` §4 (`bookings`, not `booking`).
- **Nesting reflects genuine ownership only** — `/api/v1/hotels/:id/halls` is valid because
  a Hall belongs to a Hotel; a resource is never nested under another it doesn't actually
  belong to just for URL tidiness.

---

## 5. HTTP Methods

| Method | Use | Idempotent |
|---|---|---|
| `GET` | Retrieve a resource or collection. Never changes data. | Yes |
| `POST` | Create a new resource, or trigger a non-idempotent action explicitly modeled as a sub-resource (e.g. `POST /bookings/:id/cancellations`). | No |
| `PUT` | Replace a resource in full. | Yes |
| `PATCH` | Update part of a resource. | Yes |
| `DELETE` | Remove a resource — a soft delete at the data layer (`coding-standards.md` §6), a real `DELETE` at the API layer. | Yes |

`PUT` requires the complete resource representation; a partial update always uses `PATCH`
instead of a partial `PUT`.

---

## 6. Request Standards

| Element | Standard |
|---|---|
| `Authorization` header | `Bearer <JWT>` on every protected endpoint (§12). |
| `Content-Type` | `application/json` for every request with a body, except file uploads (§15), which use `multipart/form-data`. |
| `Accept` | `application/json` — the API does not negotiate alternate representations. |
| Request body | A single JSON object matching the field-naming rules in `naming-conventions.md` §9 — never a bare array or primitive at the top level. |
| Validation | Every request is validated before business logic runs, per `coding-standards.md` §11 — this document defines what the client can expect *back* when validation fails (§8, §9). |

---

## 7. Response Standards

**One response envelope, used by every successful response, on every endpoint:**

```json
{
  "status": "success",
  "message": "Booking retrieved successfully.",
  "data": { "id": "...", "hotelId": "...", "status": "CONFIRMED" },
  "pagination": { "page": 1, "limit": 20, "total": 42, "totalPages": 3, "hasNext": true, "hasPrevious": false },
  "timestamp": "2026-08-03T10:15:00.000Z"
}
```

- **`status`** — always the literal string `"success"` for a 2xx response.
- **`message`** — a short, human-readable description of what happened, safe to display.
- **`data`** — the resource or collection. Never `null` on success; an empty collection is
  `[]`, not the omission of `data`.
- **`pagination`** — present **only** on list endpoints (§10); omitted entirely on
  single-resource responses, never sent as `null`.
- **`timestamp`** — ISO 8601, UTC, generated at response time.

**No endpoint invents its own response shape.** A single consistent envelope is what lets a
Flutter or React client parse every successful response the same way, once.

---

## 8. Error Response Standards

**One error envelope, used by every non-2xx response:**

```json
{
  "status": "error",
  "error": "VALIDATION_ERROR",
  "message": "The request could not be processed due to invalid input.",
  "details": [
    { "field": "startDate", "message": "startDate must be a valid ISO 8601 date." }
  ],
  "timestamp": "2026-08-03T10:15:00.000Z",
  "requestId": "a1b2c3d4-5678-90ab-cdef-1234567890ab"
}
```

- **`status`** — always `"error"`.
- **`error`** — a stable, machine-readable error code (`UPPER_SNAKE_CASE`), not the HTTP
  status name — a client branches on this, not on parsing `message`.
- **`message`** — human-readable, safe to display; never a raw exception message
  (`coding-standards.md` §9, no internal implementation leakage).
- **`details`** — present when there's field-level information to give (validation errors);
  omitted otherwise.
- **`requestId`** — the same correlation ID this request's log entries use
  (`coding-standards.md` §10) — this is what turns a user-reported error into something a
  developer can actually find in the logs.

This is produced by the centralized error-handling middleware (`coding-standards.md` §9) —
never assembled ad hoc in an individual controller.

---

## 9. HTTP Status Codes

| Code | Meaning | Used when |
|---|---|---|
| `200 OK` | Success | A successful `GET`, `PUT`, or `PATCH` that returns a representation. |
| `201 Created` | Resource created | A successful `POST` that creates a resource. Includes the created resource in `data`. |
| `204 No Content` | Success, no body | A successful `DELETE`, or any request with nothing meaningful to return. |
| `400 Bad Request` | Malformed request | The request fails **request validation** — wrong shape, wrong type, missing required field (`coding-standards.md` §11). |
| `401 Unauthorized` | Not authenticated | Missing, invalid, or expired JWT (§12). |
| `403 Forbidden` | Not authorized | Authenticated, but RBAC denies the action (§13). |
| `404 Not Found` | Resource doesn't exist | Including, deliberately, when a resource exists but belongs to a different tenant — a 404 is returned rather than a 403, so tenant existence is never leaked (`Architecture-Principles.md` §6). |
| `409 Conflict` | Conflicts with current state | E.g. a Booking attempt against a Hall slot that's no longer available. |
| `422 Unprocessable Entity` | Fails business validation | The request is well-formed (would pass 400) but violates a **business rule** enforced in a service (`coding-standards.md` §11) — this is the 400/422 boundary: request-shape failures are 400, business-rule failures are 422. |
| `429 Too Many Requests` | Rate limited | §19. |
| `500 Internal Server Error` | Unexpected failure | Anything not anticipated by the above — always logged with full detail server-side, never with full detail in the response (§8). |

No other status code is used without an explicit, documented reason in the relevant
Technical Design.

---

## 10. Pagination Standards

Two pagination modes are approved, matching the Prisma guidance already established in
`coding-standards.md` §6 — the API contract and the underlying query strategy are chosen
together, per endpoint, in that endpoint's Technical Design.

**Offset pagination** — default for bounded, page-numbered lists (most admin/list views):

```
GET /api/v1/bookings?page=1&limit=20
```

```json
"pagination": { "page": 1, "limit": 20, "total": 42, "totalPages": 3, "hasNext": true, "hasPrevious": false }
```

- Defaults: `page=1`, `limit=20`. Maximum `limit`: `100` — a request for more is capped, not
  rejected.
- `totalPages = ceil(total / limit)`; `hasNext`/`hasPrevious` are derived, never
  independently wrong relative to `page`/`totalPages`.

**Cursor pagination** — required for any list that can grow large or is consumed via
infinite scroll on a mobile client, per `coding-standards.md` §6:

```
GET /api/v1/bookings?cursor=<opaque-cursor>&limit=20
```

```json
"pagination": { "limit": 20, "nextCursor": "eyJpZCI6Ii4uLiJ9", "hasNext": true }
```

A single endpoint uses exactly one mode, decided in its Technical Design — never both.

---

## 11. Filtering

Applied as query parameters, `camelCase`, per `naming-conventions.md` §9:

| Filter type | Convention | Example |
|---|---|---|
| Exact match | `?status=CONFIRMED` | Repeat the parameter for OR-semantics: `?status=CONFIRMED&status=PENDING` |
| Date range | `?startDate=...&endDate=...` | Both are ISO 8601; an open-ended range omits the side that's unbounded |
| Free-text search | `?search=...` | Matches whatever field(s) the endpoint's Technical Design specifies — never silently expanded to new fields later without updating that document |
| Sorting | `?sort=<field>&order=asc\|desc` | Default `order` is `asc` if `sort` is given without `order` |

Filters are always additive (AND between different filter types) unless an endpoint's
Technical Design documents otherwise.

---

## 12. Authentication

Per `technology-stack.md` (ADR-0001) and `Architecture-Principles.md` §7:

- **Bearer token.** Every protected endpoint requires `Authorization: Bearer <JWT>`.
- **JWT** carries identity and role claims, verified on every request by shared middleware
  (`coding-standards.md` §5) before any controller runs.
- **Refresh tokens** are exchanged at a dedicated endpoint (`POST /api/v1/auth/refresh`)
  and are never accepted anywhere a regular access token is expected —
  `Architecture-Principles.md` §7 treats them as a distinct security boundary.
- **Protected vs. public endpoints** — protected is the default (§19, secure defaults); an
  endpoint is public (e.g. `POST /api/v1/auth/login`, health checks) only when its
  Technical Design explicitly says so.
- An expired or invalid token always returns `401` (§9), never a silently-degraded or
  partial response.

---

## 13. Authorization

RBAC is enforced on **every** request, at the API layer, after authentication succeeds
(`Architecture-Principles.md` §7):

- A role's permissions are checked against the specific resource and action being
  requested — not just "is this user logged in."
- Authorization failure is always `403` (§9), distinct from the `401` used for
  authentication failure — a client can tell "log in again" from "you're logged in but not
  allowed to do this."
- Multi-tenant scoping (`Architecture-Principles.md` §6) is enforced as part of
  authorization — a Hotel Manager's token authorizes actions only within their own Hotel;
  attempting another Hotel's resource returns `404`, not `403` (§9's tenant-isolation rule).
- Authorization logic lives in shared middleware/guards, never duplicated per controller
  (`coding-standards.md` §5).

---

## 14. Validation

- **Request validation** — the request's shape and types are checked before any handler
  logic runs, per `coding-standards.md` §5 and §11; failures return `400` (§9).
- **Business validation** — business rules are checked in the service layer, per
  `coding-standards.md` §11; failures return `422` (§9).
- **Response validation** — a response is shaped by the API's documented contract (§7) at
  construction time — there is no separate "validate the response before sending" step;
  the contract is enforced by the mapper/serializer producing it (`coding-standards.md` §5).
- **Input sanitization** — any input that will be rendered back to a user (e.g. in a
  Notification or Review) is treated as untrusted content, per
  `Architecture-Principles.md` §7 (Input validation) — sanitization happens once, centrally,
  not per endpoint.

---

## 15. File Upload Standards

Storage is provider-agnostic, Cloudinary default, per `Architecture-Principles.md` §10 and
`technology-stack.md` — an upload endpoint never talks to Cloudinary directly from a
controller; it goes through the storage abstraction (`coding-standards.md` §5).

| Aspect | Standard |
|---|---|
| Transport | `multipart/form-data`, never a base64-encoded field inside a JSON body. |
| Image validation | File type is checked by content (magic bytes), not by trusting the client-supplied extension or `Content-Type`. |
| Maximum file size | Defined per upload endpoint's Technical Design; enforced both client-side (UX) and server-side (security) — the server-side check is the one that's authoritative. |
| Supported formats | Defined per upload endpoint's Technical Design (e.g. Hall photos vs. a document upload have different valid formats) — not assumed globally. |
| Provider abstraction | The response returns a stable, provider-independent reference (e.g. a URL or asset ID) — a client never receives a Cloudinary-specific payload shape it would need to change if the provider changes. |

---

## 16. API Documentation

Every endpoint is documented in OpenAPI (Swagger), per `technology-stack.md` and
`Architecture-Principles.md` §8 — the documented contract is the source of truth for what
an endpoint does, not the implementation. Every endpoint's OpenAPI definition includes:

- **Summary** — one line, what the endpoint does.
- **Description** — enough detail for a client developer to use it without reading the
  Technical Design.
- **Parameters** — every path and query parameter, with type and whether required (§4, §11).
- **Request body** — schema, when applicable (§6).
- **Responses** — every status code the endpoint can actually return (§9), with example
  bodies matching §7/§8's envelopes.
- **Security requirements** — which auth is required (§12) and which roles are authorized
  (§13).

An endpoint without complete OpenAPI documentation has not met its Implementation Review
exit criteria (`Development-Lifecycle.md` Phase 9).

---

## 17. Naming Standards

Fully governed by `naming-conventions.md` §9 — resources, path/query parameters, and
request/response fields are not redefined here. This document assumes and depends on that
standard; if this document and `naming-conventions.md` ever appear to disagree, treat it as
a defect in one of them to be corrected, not a choice between them.

---

## 18. Performance Guidelines

Principles are `Architecture-Principles.md` §12; backend query patterns are
`coding-standards.md` §13. API-contract-level guidelines:

- **Pagination is required** on every list endpoint (§10) — an endpoint never returns an
  unbounded collection.
- **Avoid unnecessary nested data.** A response includes related data (`include` in
  Prisma terms) only when the consuming client actually needs it inline — otherwise the
  client fetches the related resource separately.
- **Efficient queries** back every endpoint — an endpoint's response time is bounded by
  what it actually needs from the database, not by convenience of returning everything
  available (`coding-standards.md` §6).
- **Consistent response sizes** — a given endpoint's response shape doesn't balloon
  conditionally (e.g. sometimes deeply nested, sometimes flat) based on input; a client can
  budget for its size.

---

## 19. Security Guidelines

Principles are `Project-Constitution.md` §8 and `Architecture-Principles.md` §7; the
exhaustive checklist is `security-coding-standards.md` (once authored). API-contract-level
guidelines not already stated elsewhere:

- **HTTPS only**, in every environment — no endpoint is ever served over plain HTTP, even
  in development against a shared environment.
- **Rate limiting** applies per client/IP/token on every endpoint, with authentication
  endpoints (login, refresh) held to stricter limits than general API traffic, given they're
  the highest-value target for abuse. A limited client receives `429` (§9).
- **Authorization is enforced on every request** (§13) — never assumed from a prior request
  in the same session, since the API is stateless (§2).
- **Input validation** happens before any data reaches business logic (§14) — the API layer
  is the system's outer boundary, and nothing crossing it is trusted by default.
- **Sensitive data protection** — payment details, tokens, and password hashes are never
  present in any response body, ever, regardless of the requester's role.
- **Audit logging** — every state-changing request (`POST`/`PUT`/`PATCH`/`DELETE`) on a
  business-significant resource (Bookings, Payments, access changes) is logged with actor,
  action, and `requestId` (§8), per `Project-Constitution.md` §8 (Auditability).

---

## 20. API Review Checklist

What a reviewer checks specifically about an endpoint's API contract — the formal
Implementation Review approval itself is `review-checklists.md` and
`Development-Lifecycle.md` Phase 9; this is a reading aid, the same relationship
`coding-standards.md` §16 has to that review.

- [ ] **Naming** — matches `naming-conventions.md` §9 exactly (§4, §17).
- [ ] **Versioning** — correct `/api/v1/` prefix; no breaking change shipped without a
      version bump (§3).
- [ ] **Validation** — request validation (400) and business validation (422) both present
      and distinct (§14).
- [ ] **Security** — authentication and authorization enforced, rate limiting applied where
      relevant, no sensitive data in any response (§12, §13, §19).
- [ ] **Error handling** — uses the standard error envelope; every plausible status code is
      handled, not just the happy path (§8, §9).
- [ ] **Documentation** — complete OpenAPI entry: summary, description, parameters, request
      body, responses, security (§16).
- [ ] **Performance** — paginated if it's a list endpoint; no unnecessary nested data (§18).
- [ ] **Business compliance** — matches the approved Business Specification exactly.

---

## Version History

| Version | Date | Author | Change |
|---|---|---|---|
| 1.0 | 2026-08-03 | Ahmed | Initial approved API Standards |
