# RaktSetu — Blood Donor Registry & Emergency Request App

A Flutter (cross-platform Android/iOS/Web/Windows) app for maintaining a
voluntary blood-donor repository: browse past/present/future donation events
on a list or calendar, self-register for a camp, raise emergency requests for
rare blood types that automatically match eligible donors by real GPS distance,
carry a digital donor ID card for QR check-in, earn donation milestone badges,
and get in-app notifications when your blood type is needed — with a dedicated
Admin Dashboard for camp coordinators.

This build ships with an **in-memory mock backend** pre-loaded with sample
data, so it runs immediately with no server or Firebase project needed —
ideal for a college demo/viva. A clean interface layer (`AuthService`,
`DataRepository`) is already in place so real Firebase can be swapped in later
without touching any UI code.

> **Looking for the full write-up?** See `RaktSetu_Implementation_Report.docx`
> (submitted alongside this codebase) for a complete module-by-module status,
> the full data model, key business-rule rationale, and a detailed audit log
> of every bug found and fixed during development.

## 1. Prerequisites

- Flutter SDK 3.22+ (`flutter --version` to check) — https://docs.flutter.dev/get-started/install
- Android Studio / an emulator, or a physical device with USB debugging on
  (Chrome and Windows desktop also work for most features — see §2 and §6)
- VS Code or Android Studio with the Flutter/Dart plugins

## 2. Run it

This zip contains `lib/`, `pubspec.yaml`, and the `android/`/`ios/` permission
edits already applied — Flutter still needs to generate the rest of the
platform boilerplate (`web/`, `test/`, etc.):

```bash
cd raktsetu
flutter create .       # fills in remaining platform folders
                        # — safe to run: it won't overwrite your lib/, pubspec.yaml,
                        # AndroidManifest.xml, or Info.plist permission entries
flutter pub get
flutter run             # pick any connected device, or:
flutter run -d chrome   # fastest way to demo without any mobile setup
flutter run -d windows  # if you have Visual Studio installed
```

### Demo accounts

| Phone         | Role   | Notes                                             |
|---------------|--------|----------------------------------------------------|
| `9000000001`–`9000000005` | Donor  | 5 pre-seeded donors with varying blood groups, cities, GPS coordinates, and eligibility states |
| `9999999999`  | **Admin** | Sees an extra "Admin" tab: manage events, verify donations, resolve requests, QR/phone check-in |
| any other 10-digit number | Donor (new) | Goes through fresh profile setup |

**OTP:** the app prints the real generated OTP to the debug console
(`[MockAuthService] OTP for ... is ......`), or just type **`123456`**, which
always works as a demo bypass.

## 3. Project structure

```
lib/
  models/        Donor, BloodEvent, BloodRequest, DonationRecord, DonorMatch,
                 AppNotification + BloodGroup enum
  services/      AuthService (mock OTP) and DataRepository (in-memory) interfaces
  providers/     AppState — single ChangeNotifier holding app-wide state (Provider package)
  screens/
    auth/        splash, phone login, OTP, profile setup
    home/        bottom-navigation shell (adds an "Admin" tab for admin accounts)
    events/      Upcoming/Live/Past tabs + a calendar view, event detail + self-registration
    donors/      searchable donor repository (filter by blood group, city, eligibility)
    requests/    open emergency requests list, raise-request-and-match (with GPS), call-a-donor
    profile/     donor profile, eligibility countdown, donation history, badges,
                 edit-profile screen, digital Donor ID (QR) card
    notifications/  in-app notification inbox
    admin/       Admin Dashboard — create/cancel events, verify donations, resolve requests,
                 QR/phone donor check-in (walk-in registration + confirm in one flow)
  widgets/       shared UI (blood group chip, donor card, event card, eligibility badge)
  utils/         blood_compatibility.dart (donor-compatibility rules), geo.dart
                 (Haversine distance + device location), badges.dart (milestone tiers)
```

## 4. Feature summary (mapped to the original proposal's modules)

| # | Module (from proposal) | Status |
|---|---|---|
| 1 | Authentication | ✅ Phone + OTP (mocked), admin flag on specific accounts |
| 2 | Donor Repository | ✅ Search/filter by blood group, city, eligibility; donors can edit their own profile |
| 3 | Event Management | ✅ List (Upcoming/Live/Past) **and** calendar view |
| 4 | Event Self-Registration | ✅ Capacity-aware, prevents double-registration |
| 5 | Donation History | ✅ Self-reported vs admin-verified labelled distinctly; milestone badges |
| 6 | Emergency Blood Request | ✅ Compatibility + eligibility + **real GPS distance** ranked matching, one-tap call |
| 7 | Notifications | ✅ In-app inbox (match found, request status changes, donation verified, event registration, **referral joined**) |
| 8 | Admin Dashboard | ✅ Manage/cancel events, verify donations (with eligibility safety check), resolve requests, **QR/phone check-in for walk-in donors** |
| — | Referral Program | ✅ Every donor gets a shareable referral code; new signups can enter one; referrer gets notified and unlocks referral badges (Recruiter → Blood Champion) |

## 5. Key business logic

- **Eligibility rule** (`models/donor.dart`): a donor becomes eligible again
  `lastDonationDate + 90 days` from their last donation (WHO/NBTC standard gap).
- **Compatibility matching** (`utils/blood_compatibility.dart`): standard donor→
  recipient compatibility chart (e.g. O- is the universal donor, AB+ the universal
  recipient).
- **Request matching** (`services/data_repository.dart` → `findMatchingDonors`):
  filters donors to compatible blood groups, then ranks by (1) eligible-now first,
  (2) **real GPS distance** (Haversine formula) when both the request and a donor
  have coordinates, falling back to same-city string matching otherwise, (3) longest
  time since last donation. Returns a `DonorMatch` (donor + distance in km) so the UI
  can show "2.4 km away" next to each result.
- **Donation verification integrity**: donation records distinguish
  *"Self-reported"* (logged by the donor from their own Profile) from
  *"Verified by &lt;Admin Name&gt;"* (confirmed by a coordinator, including via
  QR/phone Check-In) — so the history never falsely claims a donation was verified
  when it wasn't.
- **Admin safety check**: confirming a donation for a donor who isn't yet
  90 days past their last one triggers a warning dialog before proceeding.
- **Digital Donor ID**: each donor's QR encodes `raktsetu:donor:<id>` — a
  prefixed, namespaced payload so the Check-In scanner can reject unrelated
  QR codes instead of misreading them as a donor ID.
- **Referral codes**: deterministically derived from each donor's id
  (`generateReferralCode` in `models/donor.dart`), so they never collide and
  never need a separate database uniqueness check. A new signup can enter an
  existing donor's code in the referral field; it's validated against the
  loaded donor list before the account is created. The referral count for
  badge purposes (`utils/badges.dart` → `countReferrals`) is computed live by
  counting how many donors have that code recorded as `referredByCode` —
  no separate counter to keep in sync.
- **In-app notifications**: since there's no push backend yet, notifications
  are written to a per-donor inbox at the moment they're triggered (request
  raised → matched donors notified; admin resolves a request → the original
  requester notified; admin confirms a donation → that donor notified; donor
  registers for an event → self-notified as a confirmation). They appear
  immediately for the signed-in user and are waiting in the inbox next time
  any other affected donor logs in — the same "eventually delivered" model
  real push notifications would need a backend for (see §7).

## 6. Native permissions added for the new features

Camera (QR scanning) and location (GPS distance matching) require platform
permission entries, already added to this project:

- **Android** (`android/app/src/main/AndroidManifest.xml`): `CAMERA`,
  `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`, plus a `<queries>` entry
  so the `tel:` dialer intent resolves reliably on Android 11+.
- **iOS** (`ios/Runner/Info.plist`): `NSCameraUsageDescription`,
  `NSLocationWhenInUseUsageDescription`.

On first use of "Scan Donor QR Code" or "Use my current location", the OS
will prompt for permission — accept it to use those features. If denied,
the app degrades gracefully (manual phone-number lookup instead of scanning;
city-name matching instead of GPS distance) rather than crashing.

**Platform notes:**
- QR **scanning** (`mobile_scanner`) works on Android, iOS, and — via ZXing —
  Chrome/web using your webcam. It has no camera to use on Windows desktop.
- **Location** (`geolocator`) works on Android, iOS, web, and Windows.
- For the fullest demo of Check-In scanning, test on a physical Android phone
  or in Chrome with a webcam; Windows desktop will still work fine for every
  other feature (manual phone lookup instead of QR scan).

## 7. Firebase integration (for production / going beyond the demo)

The mock layer exists purely so the app runs without setup. To go live:

1. Run `flutterfire configure` in the project root (after creating a Firebase
   project in the console) to generate `firebase_options.dart`.
2. In `pubspec.yaml`, uncomment the `firebase_core`, `firebase_auth`,
   `cloud_firestore`, `firebase_messaging` dependencies, then `flutter pub get`.
3. Create `lib/services/firebase_auth_service.dart` implementing `AuthService`
   using `FirebaseAuth.instance.verifyPhoneNumber(...)` for `sendOtp` and
   `signInWithCredential(PhoneAuthProvider.credential(...))` for `verifyOtp`.
4. Create `lib/services/firestore_data_repository.dart` implementing
   `DataRepository`, mapping each method to Firestore collections:
   `donors`, `events`, `donationRecords`, `bloodRequests`, `notifications`.
   Keep the same method signatures — no screen code needs to change.
5. In `main.dart`, swap `MockAuthService()` → `FirebaseAuthService()` and
   `InMemoryDataRepository()` → `FirestoreDataRepository()`.
6. For real push notifications, add a Cloud Function trigger on new
   `notifications` documents (or on the events that create them — new
   `bloodRequests`, request status changes, donation confirmations) that
   sends an FCM push to the recipient's device token, replacing the current
   "in-app inbox on next login" model with an actual real-time push.

## 8. Known limitations & suggested future work

Worth mentioning if asked about production-readiness during viva:

- **No real backend yet** — everything resets when the app restarts (in-memory only). See §7.
- **Notifications are in-app only, not push** — they're written to the
  recipient's inbox immediately, but a donor only sees them next time they
  open the app (no FCM wired up yet). See §7 for the upgrade path.
- **Admin cannot edit an existing event**, only create or cancel it.
- **Seeded/demo coordinates only** — donors, events, and the sample request
  have hand-placed demo coordinates near Ahmedabad/Gandhinagar/Surat; a real
  deployment would capture these from actual device GPS at signup (which the
  app already supports going forward) rather than needing manual seeding.
- **Race condition (very low risk)**: if an admin double-taps "Confirm"
  extremely fast before the UI refreshes, it's theoretically possible to log
  two donation records for the same donor/event. Not observed in normal use.
- **Privacy consideration for real deployment**: matched donors' phone
  numbers are visible directly to whoever raises a request, and a donor's QR
  code, if shared with the wrong person, reveals their internal donor ID
  (though not any other data by itself). A production version should likely
  route contact through a masked number/consent flow and treat the QR ID as
  sensitive-but-not-secret.
- **No automated tests** — `test/widget_test.dart` is the Flutter-generated
  placeholder; given more time, unit tests for `blood_compatibility.dart`,
  `haversineDistanceKm`, and `findMatchingDonors` ranking logic would be the
  highest-value additions.

## 9. Building a release APK

```bash
flutter build apk --release
# output: build/app/outputs/flutter-apk/app-release.apk
```
