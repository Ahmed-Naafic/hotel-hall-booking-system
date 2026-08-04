# UI kit — Hotel Hall guest app

390×800 phone frame, three tabs, tap-through:

| File | Screen |
| --- | --- |
| `Chrome.jsx` | `StatusBar`, `TabBar`, `AppBar`, `Photo`, `Icon` |
| `Screens.jsx` | `StayScreen` (reservation card, today's timeline, preference switches), `KeyScreen` (arch-framed mobile key, access list), `ServicesScreen` (segmented room/house/desk ordering) |

Flow: Stay → *Open door* → Key → *Unlock* (relocks after 5s) → Services → *Add* → Toast.

All primitives come from the design-system bundle. No photography was supplied, so images
are flat labelled placeholders.
