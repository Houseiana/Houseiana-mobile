# Runbook — Leaked Clerk Production Secret Keys (BE-2 / MB)

> **Status:** OPEN — action required
> **Discovered:** 2026-08-17 (critical-bug audit, see `docs/critical_tasks.md` → BE-2)
> **Severity:** Critical
> **Owners:** Clerk-dashboard rotation → backend/ops · Code + git history → mobile
> **Repository:** `github.com/Houseiana/Houseiana-mobile.git` (branch `main`)

---

## 1. What was found

`lib/core/config/clerk_config.dart` contains two **Clerk Backend API secret keys for the production
instance**, written as plaintext string literals:

| Line | Value |
|---|---|
| `clerk_config.dart:37` | `sk_live_1v2twd9j6yO93Ial7eUUs30rg9A3eMU3v4KCZIdHXn` |
| `clerk_config.dart:38` | `sk_live_gia87Rsr3iMVlMAmVlbHVIW79TTQzrEbjULFRfHQsJ` |

They belong to the production Clerk instance identified in the same file:

```
clerk_config.dart:82   publishableKey  = pk_live_Y2xlcmsuaG91c2VpYW5hLmNvbSQ
clerk_config.dart:95   frontendApiUrl  = https://clerk.houseiana.com
clerk_config.dart:99   backendApiUrl   = https://api.clerk.com/v1
```

Both values were introduced by a single commit that is already pushed to `origin/main`:

```
7756926  feat: Firestore chat/notifications, identity verification, search & host parity
```

### 1.1 Exact scope — state this precisely

Lines `1-56` of `clerk_config.dart` are a **fully commented-out legacy config block**. The live
`ClerkConfig` class (lines `59-100`) reads the secret from a build-time flag and defaults it to an
empty string:

```dart
// clerk_config.dart:87-90  — the ACTIVE class
static const String secretKey = String.fromEnvironment(
  'CLERK_SECRET_KEY',
  defaultValue: '',
);
```

Therefore:

- ❌ The keys are **NOT** compiled into the shipped APK / IPA. They are not extractable from a
  released build.
- ✅ The keys **ARE** exposed in the repository working tree and in pushed git history — readable by
  anyone with repo access, and by every clone, fork, CI mirror, and historical checkout.

Do not overstate this as "extractable from the app binary". The accurate statement is
**"two production Clerk secret keys are committed to the repository and its pushed history."**

### 1.2 Why it still has to be treated as compromised

A Clerk secret key is full administrative authority over the production identity system. Anyone
holding one can call `https://api.clerk.com/v1/*` directly:

```bash
# enumerate every Houseiana user, with email / phone / metadata
curl -H "Authorization: Bearer sk_live_1v2twd9…" https://api.clerk.com/v1/users

# mint a valid session for ANY user id  → full impersonation
curl -X POST -H "Authorization: Bearer sk_live_1v2twd9…" \
     https://api.clerk.com/v1/sessions -d '{"user_id":"user_xxx"}'

# overwrite any account's password
curl -X PATCH -H "Authorization: Bearer sk_live_1v2twd9…" \
     https://api.clerk.com/v1/users/user_xxx -d '{"password":"…"}'
```

Because the Houseiana backend authorizes requests on Clerk session JWTs, minting a session is a
**complete authentication bypass** — guest, host, or admin. Combined with user enumeration, this is
also a mass PII exposure.

There is also a live re-arm path in the app: `clerk_service.dart:26-33` still constructs a Dio client
whose fixed header is `Bearer ${ClerkConfig.getBackendSecretKey()}`. The moment anyone pastes a key
back into that constant — or passes `--dart-define=CLERK_SECRET_KEY=sk_live_…` — the secret ships
inside the binary for real.

**Deleting the lines is not sufficient. They remain in git history. The keys must be rotated.**

---

## 2. Remediation — ordered steps

Steps 1 and 2 are independent of any code change and should not wait for them.

### Step 1 — Rotate both keys in Clerk *(backend / ops — do this first)*

1. Open the Clerk Dashboard for the **production** instance (`clerk.houseiana.com`).
2. Go to **Configure → API Keys**.
3. Create a new Secret Key.
4. Update the **backend** environment (`CLERK_SECRET_KEY` or equivalent) with the new value and
   redeploy. Verify the backend still authenticates normally.
5. **Revoke / delete both leaked keys** listed in §1.
6. Store the new secret in the backend environment or a secrets manager only. It must never be
   committed, never be sent to the mobile app, and never be passed via `--dart-define`.

> The two leaked keys are dashboard-revocable, so revocation is immediate and total. Until you
> revoke them, the exposure is live regardless of what the repo looks like.

### Step 2 — Audit for abuse *(backend / ops)*

1. In the Clerk Dashboard, review the API request logs filtered to the two revoked keys.
2. Look specifically for: `GET /v1/users` bulk reads, `POST /v1/sessions` (session minting),
   `PATCH /v1/users/{id}` (password changes), `DELETE /v1/users/{id}`.
3. Check for calls originating from IPs that are not the backend's.
4. If any unrecognised activity is found, treat it as a confirmed breach: force sign-out of all
   sessions, and follow the applicable personal-data breach notification process.
5. Record the outcome — "no unauthorized use observed" is a result worth writing down.

### Step 3 — Remove the keys from the working tree *(mobile)*

Delete the entire commented legacy block, `clerk_config.dart:1-56`. It has no runtime effect; the
active class starts at line 59. Nothing else in the file needs to change.

Verify:

```bash
git grep -n "sk_live" -- lib   # must return nothing
```

### Step 4 — Remove the re-arm path *(mobile)*

Delete `_backendDio` and everything that depends on it, so no future contributor can accidentally
re-enable a Clerk secret key in the client.

In `lib/core/services/clerk_service.dart`:

| Line(s) | Symbol | Action |
|---|---|---|
| `9`, `26-33` | `_backendDio` field + constructor | Delete. Its header is `Bearer ${ClerkConfig.getBackendSecretKey()}`. |
| `85` | `_backendDio.interceptors.add(logInterceptor)` | Delete. |
| `423-430` | `getUser(userId)` | Delete — **no callers anywhere in `lib/`**. |
| `554-578` | `_updateUserPassword(...)` | Delete — see note below. |
| `582-587` | `changeUserPassword(...)` | Delete — thin wrapper over `_updateUserPassword`. |
| `593-603` | `getSession(sessionId)` | Delete — **no callers**. |
| `606-613` | `revokeSession(sessionId)` | One caller: `auth_cubit.dart:442`. See Step 5. |
| `616-623` | `getUserSessions(userId)` | Delete — **no callers**. |

In `lib/core/config/clerk_config.dart`, once nothing references them, also delete:

```dart
static String getBackendSecretKey() => secretKey;      // :91
static bool get hasBackendSecretKey => secretKey.isNotEmpty;  // :92
static const String backendApiUrl = 'https://api.clerk.com/v1';  // :99
```

> **Note on `_updateUserPassword`:** it is already dead in production — it PUTs to
> `api.clerk.com/v1/users/{id}` with the header `Bearer ` (empty), which returns 401. It is the
> third failure point of the broken password-reset flow tracked as **MB-8** in
> `docs/critical_tasks.md`. Deleting it here and rebuilding password reset on the Clerk **Frontend**
> API (which needs no secret) closes both issues with one change. Coordinate the two.

### Step 5 — Replace session revocation on logout *(mobile + backend)*

`auth_cubit.dart:442` calls `_clerkService.revokeSession(sessionId)` on logout. That call is
currently a no-op that 401s, because the secret is empty. Two options:

- **Preferred** — the backend exposes:
  ```
  POST /api/auth/logout
  Authorization: Bearer <caller's Clerk session JWT>
  Body: { "sessionId": "<id>" }
  ```
  and performs the Clerk revoke server-side with the secret it already holds. The app then calls
  this instead of `ClerkService.revokeSession`.
- **Acceptable interim** — remove the call. Local session state is already cleared on logout
  (`UserSession` + cookies + FCM token), and Clerk session JWTs are short-lived. Server-side
  revocation is a hardening measure, not a functional requirement for logout to work.

Do **not** leave the call in place pointing at a client-held secret.

### Step 6 — Purge the values from git history *(mobile — coordinate, it rewrites `main`)*

Rotation (Step 1) already neutralises the keys. This step removes the embarrassing artefact and
prevents secret scanners from re-flagging the repo.

`main` is the only branch, and both keys were introduced in a single commit (`7756926`), so the
rewrite is narrow.

1. Announce the rewrite — everyone must stop pushing and be ready to re-clone.
2. Back the repo up: `git clone --mirror https://github.com/Houseiana/Houseiana-mobile.git backup.git`
3. Purge with `git filter-repo` (preferred) or BFG:

   ```bash
   # create replacements.txt
   sk_live_1v2twd9j6yO93Ial7eUUs30rg9A3eMU3v4KCZIdHXn==>REDACTED
   sk_live_gia87Rsr3iMVlMAmVlbHVIW79TTQzrEbjULFRfHQsJ==>REDACTED

   git filter-repo --replace-text replacements.txt
   ```
4. Force-push: `git push --force --all && git push --force --tags`
5. **Every collaborator re-clones.** A stale local clone will re-introduce the old objects on its
   next push.
6. Ask GitHub Support to expire cached views of the old commits, and check that no fork carries them.

> If a history rewrite is judged too disruptive, it is acceptable to skip Step 6 **only** if Steps 1
> and 2 are complete — a revoked key in history is inert. Record the decision.

### Step 7 — Prevent recurrence

1. Add secret scanning to CI. Minimal gate:
   ```yaml
   - name: Secret scan
     run: |
       if git grep -nE 'sk_live_|sk_test_|pk_live_[A-Za-z0-9]{40,}' -- . ':!docs'; then
         echo "::error::Secret-shaped literal committed"; exit 1
       fi
   ```
   Or use `gitleaks` / GitHub Advanced Security push protection.
2. Enable GitHub **Push Protection** on the repository (Settings → Code security).
3. Add a pre-commit hook mirroring the CI check.
4. Keep the security note already at `clerk_config.dart:62-75` — it correctly states the rule that
   was violated. Reference this runbook from it.

---

## 3. Verification checklist

Close the item only when every line is checked.

| # | Check | How to verify | Owner |
|---|---|---|---|
| 1 | Both leaked keys revoked in Clerk | Dashboard → API Keys — neither key is listed | backend |
| 2 | New secret works in production | Backend authenticates; smoke-test sign-in end to end | backend |
| 3 | New secret is not in the repo | `git grep -n "sk_live" -- .` → no hits outside `docs/` | mobile |
| 4 | Clerk API logs reviewed | Written finding recorded (even if "no abuse observed") | backend |
| 5 | `clerk_config.dart:1-56` deleted | File starts at the live `ClerkConfig` class | mobile |
| 6 | No secret-key call sites remain | `git grep -n "getBackendSecretKey\|_backendDio" -- lib` → no hits | mobile |
| 7 | Logout path resolved | Either `POST /api/auth/logout` is wired, or the call is removed | both |
| 8 | App builds and signs in | `flutter analyze` clean; manual sign-in / sign-out pass | mobile |
| 9 | History purged **or** decision recorded | `git log -S 'sk_live_1v2twd9…' --all` → empty, or a written waiver | mobile |
| 10 | CI secret gate is live | A test commit containing `sk_live_TEST` fails the build | mobile |

---

## 4. What NOT to do

- **Do not** just delete the lines and push. The keys stay in history and stay valid — that fixes
  the appearance, not the exposure. Rotation is the fix.
- **Do not** move the secret into `.env`, `--dart-define`, `strings.xml`, or any other client-side
  location. A mobile app cannot hold a secret; anything shipped to a device is public. Every
  operation needing `sk_*` belongs behind the backend.
- **Do not** paste either key into a ticket, chat message, screenshot, or commit message while
  coordinating this work. Reference them as "the two keys in `clerk_config.dart:37-38`".
- **Do not** reuse the compromised keys anywhere, including staging.

---

## 5. Related items

- `docs/critical_tasks.md` → **BE-2** — the audit finding this runbook implements.
- `docs/critical_tasks.md` → **MB-8** — broken password reset. Its third failure point is
  `_updateUserPassword` depending on this same empty secret; Step 4 and MB-8 should be done together.
- `lib/core/config/clerk_config.dart:62-75` — the in-code security note stating the rule.
