# ADR-0008: Hotel Location Mapping and Geocoding

- Status: Approved
- Date: 2026-08-31
- Decision owner: Ahmed

## Context

`BDR-017` requires exact Hotel coordinates plus an editable customer-facing address. Provider
details must not leak into business logic or Flutter clients.

## Decision

Manager Mobile uses OpenStreetMap tiles through `flutter_map` and displays OpenStreetMap
attribution. Reverse geocoding uses Nominatim through a backend provider abstraction. The
backend supplies an identifying User-Agent, enforces a timeout, and treats provider failure as
non-blocking. Location remains a structured value in `Hotel.profileData.location`; no schema
migration is required.

The Hotel-owned endpoint is `POST /hotels/:hotelId/location/reverse-geocode`. It accepts valid
latitude/longitude values and returns either a detected address or an unavailable result.
Profile persistence requires latitude, longitude, and a non-empty address whether detected or
entered manually.

## Consequences

- No geocoding credential is stored in Flutter.
- Provider-specific behavior is isolated behind the backend adapter.
- Coordinates can support future distance queries, but nearby search is not implemented here.
- Existing Hotel ownership, lifecycle, application, and approval behavior remain unchanged.
