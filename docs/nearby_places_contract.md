# Nearby Places / "Your day here" — verified API contract

Verified live against **staging** and **production** on 2026-09-01. Every claim below was
observed in a real response, not read off Swagger (Swagger declares every response as a bare
`200 OK` with no schema, so it is useless for shapes here).

Hosts:
- staging `https://houseiana-api.jollyisland-881a1746.eastus.azurecontainerapps.io`
- production `https://houseiana-api-prod.jollyisland-881a1746.eastus.azurecontainerapps.io`

Both hosts serve the whole feature. `AppConfig.environment` is `staging` today.

---

## 1. `GET /api/Lookups/NearbyCategories`

```json
{"success":true,"data":[
  {"id":1,"name":"coffee"},{"id":2,"name":"breakfast"},{"id":3,"name":"shopping"},
  {"id":4,"name":"gifts"},{"id":5,"name":"family"},{"id":6,"name":"entertainment"},
  {"id":7,"name":"essentials"}]}
```

- **Localizes through the `?lang=` QUERY PARAM only.** The `lang:` header is ignored
  (`-H "lang: ar"` still returns `coffee`); `?lang=ar` returns `قهوة / فطور / تسوق / هدايا /
  عائلة / ترفيه / أساسيات`. Same trap as `PropertyType` and `RegionCategory`.
- `/api/HotelManagementLookup/NearbyCategories` returns the **same seven ids** — hotels and
  properties share one category id space, so one lookup call serves both.
- The lookup `name` is a bare slug, **not** the marketing copy the UI shows
  ("ابدأ يومك بهدوء ☕"). Chip labels are client copy keyed off the stable **id**.
  Treat the lookup as the source of *which ids exist and in what order*, nothing more.

## 2. Nearby places on the details payloads

Both details endpoints already embed the **complete** list — there is no paging and no
truncation, so the details response alone can drive the day plan and the chip set.

- `GET /api/property-search/{id}` → `data.nearbyPlaces[]`
- `GET /api/hotels/{id}/details`  → `data.nearbyPlaces[]`

## 3. `GET /api/property-search/{propertyId}/nearby-places?categoryId=N`
## 4. `GET /api/hotels/{hotelId}/nearby-places?categoryId=N`

- `categoryId` is **required in practice**. Omitting it returns
  `404 {"success":false,"statusCode":404,"message":"Category not found."}` even though
  Swagger marks it optional. `categoryId=0` and `categoryId=99` 404 the same way.
- Unknown owner id → `404 … "Property not found."` / `"Hotel not found."`
- A category with no places → `200 {"success":true,"data":[]}`.

---

## 5. The two shapes are NOT the same

| field | property | hotel |
|---|---|---|
| owner key | `propertyId` | `hotelId` |
| `categoryId` | int 1..7 | int 1..7 |
| `categoryName` | **absent** | present, localized slug |
| name | `name` **and** `nameAR`, both always sent | `name` only |
| description | `description` **and** `descriptionAR` | `description` only |
| `rating` | number — **can be fractional** (`4.5` in prod) | number |
| `reviewCount` | int, **can be 0** | int **or `null`** |
| `distanceMeters` | int | int |
| `walkMinutes` | int | int |
| `driveMinutes` | int, **can be 0** | int |
| `googleMapsUrl` | string — **can be garbage** (`"test"`) | string — **can be garbage** |
| `priceLevel` | stable enum `CHEAP` / `MODERATELY_PRICED` / `EXPENSIVE` | **display string** |
| `displayOrder` | int, **can be 0** | int **or `null`** |
| `timeOfDay` | stable enum `MORNING` / `LATE_MORNING` / `AFTERNOON` / `EVENING` | **display string** |
| `image` | present, **always `""` so far** (nullable string per DTO) | **absent** |

### The localization trap

**Property rows are never server-localized** — `name` and `nameAR` both come back whatever
`lang` says, so the client picks the field by locale.

**Hotel rows are fully server-localized** by the `lang` header *and* `?lang=`, including the
enum-looking fields:

```
lang=en → "priceLevel":"Cheap",  "timeOfDay":"Late Morning"
lang=ar → "priceLevel":"رخيص",   "timeOfDay":"قبل الظهر"
```

So for hotels `timeOfDay` / `priceLevel` are **display text, not parseable enums**. Any code
that switches on those strings breaks the moment the app is in Arabic — the same class of bug
as the payment-method and property-type lookups.

Consequences baked into the implementation:
- Parsing accepts `LATE_MORNING`, `Late Morning`, `late morning` (case / separator
  insensitive). If it parses, the UI renders **our** localized label; if it does not
  (Arabic hotel text) the UI renders the **raw string** verbatim.
- Day-plan ordering keys off the parsed enum when available and falls back to
  `displayOrder`, which is a stable int on both shapes.

## 6. How much data actually exists

- staging: 2 of 56 properties have any nearby places; 2 of 6 hotels do.
- production: 1 of the first 100 properties (of 2100) has any.

The section must therefore **disappear entirely** when the list is empty — it is the common
case, not the edge case.

## 7. Ordering: why the day plan cannot key off `timeOfDay` alone

For a **property** `timeOfDay` is a stable enum in both languages, so the plan just sorts on it.
For a **hotel** it is translated display text, so in Arabic it parses to nothing — and hotel
`displayOrder` is nullable, so both sort keys can be absent at once.

Breaking that last tie on `name` (the obvious choice) is wrong: every Arabic hotel row ties, the
list falls through to UTF-16 order over Arabic text, and the chain comes out alphabetical — the
evening bar leading, arrows still asserting a sequence, and "ابدأ بقهوة" printed on the *last*
card. The same hotel in English orders correctly, so **the plan reverses itself on a language
switch**.

`NearbyPlace.compare` therefore stops at `timeOfDay → displayOrder → categoryId` (category ids run
coffee → breakfast → shopping → … , which is already roughly a day and is language-independent),
and callers must go through `NearbyPlace.sorted`, which resolves the remaining ties by the order
the backend sent. `List.sort` is not stable — never call it with `compare` directly.

## 8. Other traps this feature already paid for

- **The lookup orders the chips; it must never decide which exist.** Intersecting the payload's
  category ids with the lookup means a retired — or merely not-yet-cached — lookup row deletes
  content the stay still has, and the whole block vanishes a frame after it painted, leaving the
  dividers above and below it stacked. `LookupsCache` holds the lookup for 24h, so this is live the
  day an eighth category ships.
- **A hotel's `description` is the only field that reliably changes between languages.** Its
  `name` is often a brand typed once in Latin, and `priceLevel` / `timeOfDay` are nullable — so the
  "did the payload change language?" check has to include the description, or the card keeps its
  English body copy under an Arabic page forever (hotels have no `descriptionAR`).
- **`0` means "unset"** in `rating`, `reviewCount`, `driveMinutes` and `displayOrder`, and `""`
  means it in `image`. Print a `rating` of 0 and the card reads *rated zero* rather than *unrated*.
