---
title: "Customer Management — Business Specification"
document_type: Business Specification
module: 02-customer-management
module_id: M02
status: Draft
owner: Ahmed
reviewer: TBD
version: 1.0
last_updated: 2026-08-30
depends_on: ["docs/Project-Overview.md", "docs/Project-Glossary.md", "docs/04-business/business-decision-register.md", "docs/04-business/modules/01-authentication-and-account-management/business-specification.md", "docs/04-business/modules/03-hotel-management/business-specification.md", "docs/04-business/modules/04-hall-management/business-specification.md"]
---

# Customer Management — Business Specification

## Module Metadata

| Field | Value |
|---|---|
| Module | Customer Management |
| Module ID | M02 |
| Document Type | Business Specification |
| Version | 1.0 |
| Status | Draft |
| Business Owner | Ahmed |
| Reviewer | TBD |

---

## 1. Purpose

The Customer Management module defines how Customers are represented and managed within the
Hotel Hall Booking System.

The module is responsible for Customer-specific information and Customer-related business
rules. It does not own authentication, Hotel management, Hall management, or booking
transactions.

A key principle of this module is that Customer registration is not required for general
platform discovery. A person may browse Hotels and Halls without creating an account.
Customer registration and onboarding begin when the person decides to proceed with a Booking
or another action that requires an authenticated Customer identity.

---

## 2. Business Objectives

1. Provide a Customer identity that can be associated with Bookings.
2. Maintain Customer-specific profile information.
3. Allow Visitors to discover Hotels and Halls without mandatory registration.
4. Require Customer registration when a protected Customer action, particularly Booking, is
   initiated.
5. Provide the information required by future Booking Management.
6. Maintain a clear separation between Customer Management and Authentication.
7. Prevent Customer Management from taking ownership of Hotel, Hall, or Booking business
   data.
8. Provide a foundation for future Customer-facing functionality.

---

## 3. Scope

### 3.1 In Scope

- Customer profile management.
- Customer-specific business information.
- Customer onboarding when an authenticated identity is required.
- Customer profile completion.
- Customer profile viewing.
- Customer profile updating.
- Customer-specific eligibility rules where approved.
- Providing Customer identity/profile information to authorized platform functions.
- Supporting the transition from anonymous discovery to authenticated Customer activity.

### 3.2 Out of Scope

- Authentication implementation.
- Password management.
- Login and logout.
- Phone verification.
- Session/token management.
- Hotel creation or management.
- Hotel approval.
- Hall creation or management.
- Hall ownership.
- Hall visibility rules.
- Booking creation and management.
- Payment processing.
- Hotel Manager management.
- Platform administration.
- Media storage infrastructure.

---

## 4. Actors

### 4.1 Visitor

A Visitor is a person using the platform without an authenticated Customer account.

A Visitor may:

- Browse Hotels.
- View eligible Hotel information.
- Browse visible Halls.
- View Hall information.
- View available media exposed by the platform.
- Explore the platform without registration.

A Visitor cannot perform protected Customer actions requiring an authenticated identity.

### 4.2 Customer

A Customer is an authenticated user who has registered as a Customer and can perform
Customer-specific protected actions.

The Customer may:

- Maintain their Customer profile.
- Update permitted Customer information.
- Initiate Booking activities.
- Provide information required for Booking.
- Access Customer-specific functionality available to the account.

### 4.3 Hotel Manager

The Hotel Manager owns and manages Hotel-related business information through Hotel
Management.

Customer Management does not give the Hotel Manager ownership of Customer profiles.

### 4.4 Platform Administrator

The Platform Administrator may have administrative capabilities defined by Administration &
Platform Management.

Customer Management should not independently create administrative permissions that are not
defined elsewhere.

---

## 5. Customer Discovery Principle

The platform follows a browse-first, register-at-booking model.

A person does not need to register simply to explore the platform.

```text
Visitor
  -> Browse Hotels
  -> Select Hotel
  -> Browse Halls
  -> View Hall Details
  -> Choose a Hall
  -> Initiate Booking
  -> Registration / Login
  -> Customer Onboarding
  -> Continue Booking
```

---

## 6. Hotel Discovery

Customers and Visitors may discover Hotels that are eligible for Customer-facing operation.

Customer Management does not determine whether a Hotel is eligible.

Hotel Management remains authoritative for:

- Hotel lifecycle.
- Hotel approval.
- Hotel visibility.
- Hotel business information.

Customer-facing discovery consumes the appropriate Hotel information rather than creating a
second Hotel data model.

A Hotel that is not eligible for Customer-facing discovery should not be presented as an
available Hotel to Visitors.

---

## 7. Hall Discovery

Visitors and Customers may browse Halls exposed for Customer-facing discovery.

Hall Management remains authoritative for:

- Hall ownership.
- Hall profile information.
- Hall lifecycle.
- Hall visibility.
- Hall capacity.
- Hall location/area.
- Hall photos.

Customer Management must not duplicate Hall visibility or ownership rules.

Customer-facing Hall information may include:

- Hall name.
- Capacity.
- Description.
- Location/Area.
- Photos.

---

## 8. Customer Registration

Customer registration occurs when the person requires an authenticated Customer identity.

The primary trigger is the decision to proceed with a Booking.

```text
Visitor
  -> Select Hall
  -> Select Book
  -> Not authenticated
  -> Register / Login
```

Authentication and account creation are handled by Authentication & Account Management.

---

## 9. Customer Onboarding

Customer onboarding should be lightweight.

```text
Register/Login
  -> Phone Verification
  -> Customer Profile
  -> Complete Required Information
  -> Return to Booking
  -> Continue Booking
```

The Customer should not be forced to repeat the Hotel/Hall discovery process after
registration.

---

## 10. Customer Profile

Customer Management owns the Customer's business profile.

The exact required and optional profile fields must be explicitly defined and approved before
implementation.

The module should distinguish between:

- Required information.
- Optional information.
- Future/custom information.

No arbitrary Customer fields should be invented during implementation.

---

## 11. Profile Completion

A Customer may have an incomplete profile after registration.

The system should distinguish between:

- Authenticated Customer with complete profile.
- Authenticated Customer with incomplete profile.

The exact fields required for completion are a pending business decision unless already
defined elsewhere.

If a Booking requires information that has not yet been provided, the Customer should be
prompted to complete the required information before the Booking can proceed.

---

## 12. Customer Profile Management

An authenticated Customer should be able to:

- View their own profile.
- Update permitted profile information.
- Complete missing required information.
- Maintain optional profile information.

A Customer must not be able to modify another Customer's profile.

---

## 13. Customer Eligibility

Customer eligibility must use the project's approved business decisions and rules.

Customer Management must not create a second or conflicting definition of eligibility.

If the existing Business Decision Register contains an approved Customer Eligibility
decision, that decision becomes authoritative.

If a required Customer eligibility rule remains unresolved, it must remain explicitly
identified as a Pending Business Decision.

---

## 14. Customer and Booking Boundary

Customer Management does not own the Booking transaction.

```text
Customer Management
  -> Provides Customer identity/profile
  -> Booking Management
  -> Creates and manages Booking
```

Booking Management will own:

- Booking creation.
- Booking modification.
- Booking cancellation.
- Booking lifecycle.
- Reservation rules.
- Booking-specific availability decisions.
- Other transaction-specific behavior.

---

## 15. Customer and Hotel Boundary

Hotel Management owns:

- Hotel identity.
- Hotel profile.
- Hotel lifecycle.
- Hotel approval.
- Hotel eligibility.
- Hotel business information.
- Hotel media relationship.

Customer Management may consume Hotel information for Customer-facing discovery but does not
modify or duplicate Hotel business data.

---

## 16. Customer and Hall Boundary

Hall Management owns:

- Hall identity.
- Hall profile.
- Hall capacity.
- Hall location/area.
- Hall visibility.
- Hall ownership.
- Hall media relationship.

Customer Management may consume Hall information for Customer-facing discovery but does not
modify or duplicate Hall business data.

---

## 17. Customer and Authentication Boundary

Authentication & Account Management owns:

- Customer registration.
- Login.
- Logout.
- Password management.
- Phone verification.
- Authentication credentials.
- Sessions.
- Access and refresh tokens.

Customer Management owns:

- Customer-specific business profile.
- Customer-specific business information.
- Customer-specific business rules.

---

## 18. Core Customer Journeys

### CJ-01 — Browse Without Registration

```text
Visitor
  -> Views Hotels
  -> Selects Hotel
  -> Views Halls
  -> Views Hall details
```

**Expected result:** The Visitor can discover Customer-facing Hotels and Halls without
creating a Customer account.

### CJ-02 — Begin Booking as Visitor

```text
Visitor
  -> Select Hall
  -> Select Book
  -> System requires authentication
  -> Register/Login
```

**Expected result:** The Visitor is directed to Customer authentication without losing the
intended Booking context.

### CJ-03 — Complete Customer Onboarding

```text
Customer registers
  -> Authentication/verification
  -> Customer profile
  -> Required information provided
  -> Profile complete
```

**Expected result:** The Customer has the information required to proceed with the relevant
protected action.

### CJ-04 — Update Customer Profile

```text
Customer
  -> My Profile
  -> Edit information
  -> Save
```

**Expected result:** Only the authenticated Customer's own profile is updated.

### CJ-05 — Return to Booking

```text
Visitor
  -> Hall
  -> Book
  -> Register
  -> Verify
  -> Complete profile
  -> Return to booking
```

**Expected result:** The Customer can continue the Booking process without having to restart
discovery.

---

## 19. Business Rules

### BR-CUST-01 — Discovery Does Not Require Registration

A person may browse Customer-facing Hotels and Halls without creating a Customer account.

### BR-CUST-02 — Protected Actions Require Authentication

Actions requiring a Customer identity must require authentication.

### BR-CUST-03 — Registration Is Triggered by Customer Need

Customer registration should be requested when the Visitor attempts an action that requires a
Customer identity, primarily Booking.

### BR-CUST-04 — Customer Owns Their Profile

A Customer may manage their own Customer profile but may not modify another Customer's
profile.

### BR-CUST-05 — Authentication Is Owned by Module 1

Customer Management does not own authentication credentials, login, verification, or
sessions.

### BR-CUST-06 — Hotel Ownership Remains with Hotel Management

Customer Management cannot create, modify, or approve Hotel business information.

### BR-CUST-07 — Hall Ownership Remains with Hall Management

Customer Management cannot create, modify, or manage Hall inventory.

### BR-CUST-08 — Booking Is Owned by Booking Management

Customer Management does not create or manage Bookings.

### BR-CUST-09 — Customer Discovery Uses Authoritative Hotel/Hall Data

Customer-facing discovery must use the authoritative information supplied by Hotel Management
and Hall Management.

### BR-CUST-10 — Customer Cannot Modify Hotel or Hall Data

A Customer's access to Hotel or Hall information does not grant permission to modify that
information.

### BR-CUST-11 — Required Profile Information Must Be Approved

Customer Management must not invent required Customer profile fields during implementation.

### BR-CUST-12 — Incomplete Profiles

A Customer with incomplete information may remain an authenticated Customer, but a protected
business action requiring missing information may require profile completion.

---

## 20. Exceptions

### Unverified Customer

The authentication module determines verification status. Customer Management must respect
the established authentication rules.

### Incomplete Customer Profile

The Customer may be asked to complete the required information when attempting an action that
requires it.

### Hotel Not Available

Customer-facing discovery must not present Hotels that Hotel Management determines are not
eligible for Customer-facing operation.

### Hall Not Visible

Customer-facing discovery must respect Hall Management's visibility rules.

### Customer Attempts Another Customer's Profile

The operation must be rejected.

### Customer Attempts to Modify Hotel/Hall

The operation must be rejected because those domains are owned by Hotel Management and Hall
Management respectively.

---

## 21. Pending Business Decisions

### BDR-CUST-01 — Required Customer Profile Information

What information must a Customer provide?

Potential categories may include:

- Name.
- Contact information.
- Email.
- Other Customer-specific information.

The actual required fields must be explicitly approved.

### BDR-CUST-02 — Optional Customer Information

Which Customer information is optional?

### BDR-CUST-03 — Profile Completion Requirement

At what point must the Customer profile be complete?

Possible points include:

- Before starting a Booking.
- Before confirming a Booking.
- Only when a specific required field is needed.

### BDR-CUST-04 — Customer Eligibility

What business conditions determine whether a Customer is eligible to perform protected
Customer actions?

This must follow any existing approved eligibility decision rather than introducing a
competing rule.

### BDR-CUST-05 — Customer Account Lifecycle

The Customer lifecycle states and transitions require confirmation if they have not already
been defined elsewhere.

### BDR-CUST-06 — Customer Discovery Scope

The exact search/filter capabilities available to anonymous Visitors and authenticated
Customers should be defined before implementation if they are not already established by
another approved module.

---

## 22. Acceptance Criteria

### AC-CUST-01

A Visitor can browse Customer-facing Hotels without registering.

### AC-CUST-02

A Visitor can browse Customer-facing Halls without registering.

### AC-CUST-03

A Visitor attempting a protected Customer action is required to authenticate.

### AC-CUST-04

Customer registration uses the existing Authentication & Account Management process.

### AC-CUST-05

Customer-specific profile information is managed by Customer Management.

### AC-CUST-06

A Customer can view and update their own permitted profile information.

### AC-CUST-07

A Customer cannot modify another Customer's profile.

### AC-CUST-08

Customer Management does not modify Hotel or Hall business information.

### AC-CUST-09

Customer Management does not create or manage Bookings.

### AC-CUST-10

Customer-facing Hotel discovery respects Hotel Management's authoritative
eligibility/visibility rules.

### AC-CUST-11

Customer-facing Hall discovery respects Hall Management's authoritative visibility rules.

---

## 23. Traceability

| Requirement Area | Responsible Module |
|---|---|
| Registration | Authentication & Account Management |
| Login | Authentication & Account Management |
| Phone Verification | Authentication & Account Management |
| Customer Profile | Customer Management |
| Customer Eligibility | Customer Management / approved business rules |
| Hotel Profile | Hotel Management |
| Hotel Approval | Hotel Management |
| Hall Profile | Hall Management |
| Hall Visibility | Hall Management |
| Hall Ownership | Hall Management |
| Hotel/Hall Discovery | Customer-facing experience consuming authoritative domain data |
| Booking | Booking Management |
| Media Storage | Shared Media Infrastructure |
| Platform Administration | Administration & Platform Management |

---

## 24. Summary

Customer Management provides the Customer identity and Customer-specific business profile
required by the platform while keeping the Customer experience lightweight.

The central onboarding principle is:

> Customers browse first and register when they need to perform a protected action,
> primarily Booking.

This means registration is not a prerequisite for discovering Hotels and Halls.

The resulting Customer journey is:

```text
DISCOVER
  |
  v
Browse Hotels/Halls
  |
  v
Select Hall
  |
  v
Start Booking
  |
  v
Authenticated?
  |-- No  -> Register/Login
  |-- Yes -> Continue
  |
  v
Verify
  |
  v
Complete Customer Profile
  |
  v
Continue Booking
  |
  v
Booking Management
```

Authentication identifies the person. Customer Management manages the Customer. Hotel/Hall
Management provide inventory. Booking Management manages the transaction.
