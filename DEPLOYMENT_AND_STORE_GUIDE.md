# RaktSetu - Production Deployment & Store Submission Guide

This document outlines the complete architectural conversion of **RaktSetu** from a local/localhost environment to a secure, online, production-ready mobile application prepared for Google Play Store and Apple App Store distribution.

---

## 1. Architecture Overview

### Client (Flutter Mobile Application)
- **Application ID / Package Name**: `org.raktsetu.blooddonor`
- **Application Display Name**: `RaktSetu`
- **Minimum Android SDK**: API 21 (Android 5.0 Lollipop)
- **Target Android SDK**: API 34+ (Google Play requirement)
- **iOS Minimum Deployment**: iOS 13.0+
- **Environment Management**: Configuration injected via `--dart-define` parameters during build/CI. No secrets or localhost addresses embedded in application binary.
- **Offline & Fault Tolerance**: Network timeouts (15s), retry handling, caching layer in `RestDataRepository`, and graceful offline fallbacks.

### Backend Infrastructure
Two enterprise-ready backend topologies are supported out-of-the-box:

1. **Option A: Managed REST API + Cloud PostgreSQL (Included in `backend/`)**
   - **Runtime**: Node.js 18+ (Express)
   - **Security**: Helmet headers, CORS origin whitelisting, Rate limiting (100 req/15 min), JSON Web Tokens (JWT)
   - **Database**: PostgreSQL 15+ with migration runner (`backend/src/migrate.js` + `backend/migrations/init.sql`)
   - **Containerization**: `backend/Dockerfile` and `backend/docker-compose.yml`
   - **Hosting Platforms**: Render, Railway, Supabase + Koyeb, DigitalOcean App Platform, or Docker VPS

2. **Option B: Firebase Serverless (Pre-configured in `firestore.rules`)**
   - **Authentication**: Firebase Phone Auth (SMS OTP)
   - **Database**: Cloud Firestore (NoSQL) with strict security rules
   - **Notifications**: Firebase Cloud Messaging (FCM)
   - **Hosting**: 100% serverless, zero server maintenance

---

## 2. Itemized Cost Breakdown & Accounts Required

| Service | Provider | Purpose | Estimated Monthly Cost | Free Tier Available? |
| :--- | :--- | :--- | :--- | :--- |
| **Google Play Developer Account** | Google | Distribution on Google Play Store | **$25 (One-time fee)** | No |
| **Apple Developer Program** | Apple | Distribution on Apple App Store | **$99 / year** | No |
| **Domain & SSL** (e.g. `raktsetu.org`) | Namecheap / Cloudflare | Public HTTPS API endpoint | **~$8 - $12 / year** | Free SSL via Let's Encrypt / Cloudflare |
| **Option A Hosting: Managed REST + DB** | Render / Railway / Supabase | Container + PostgreSQL database | **$0 to $7 / month** | Yes (Render & Supabase have free tiers) |
| **Option B Hosting: Firebase** | Google Firebase | Phone Auth + Firestore + FCM | **$0 / month** (Spark Plan) | Yes (10k SMS/mo, 1GB Firestore free) |
| **CI/CD Cloud Builds** | GitHub Actions | Automated `.aab` & `.ipa` compilation | **$0** (Free for public, 2000 min/mo private) | Yes |

---

## 3. Step-by-Step Backend Deployment

### Method 1: Deploy to Render (Recommended for REST API)
1. Push your repository to GitHub.
2. Sign up at [Render.com](https://render.com).
3. **Create PostgreSQL Database**:
   - Click **New +** > **PostgreSQL**.
   - Name: `raktsetu-db`.
   - Copy the **Internal Database URL** and **External Database URL**.
4. **Create Web Service**:
   - Click **New +** > **Web Service** > Connect your GitHub repo.
   - Root Directory: `backend`.
   - Build Command: `npm install`.
   - Start Command: `npm start`.
   - Add Environment Variables:
     - `PORT`: `10000`
     - `NODE_ENV`: `production`
     - `DATABASE_URL`: *(Paste PostgreSQL URL from Step 3)*
     - `JWT_SECRET`: *(Generate a 64-character random string)*
     - `ALLOWED_ORIGINS`: `https://raktsetu.org`
5. **Run Database Migrations**:
   - In Render Web Service > **Shell** tab:
     ```bash
     npm run migrate
     ```
6. Your backend will be live at `https://<your-service-name>.onrender.com`.
7. Verify health check:
   ```bash
   curl -I https://<your-service-name>.onrender.com/health
   # Returns: HTTP/2 200 OK {"status":"healthy"}
   ```

---

## 4. Building the Android App Bundle (`.aab`)

### Option A: Via GitHub Actions Cloud CI/CD (No local Android SDK required)
1. Push this project to your GitHub repository.
2. In GitHub, go to **Settings** > **Secrets and variables** > **Actions**.
3. (Optional for signed release) Add Secrets:
   - `KEYSTORE_BASE64`: Base64 encoded `upload-keystore.jks`
   - `KEYSTORE_PASSWORD`: Password for keystore
   - `KEY_ALIAS`: Keystore alias (e.g. `upload`)
   - `KEY_PASSWORD`: Password for key alias
   - `PROD_API_URL`: `https://<your-backend-domain>.com`
4. Go to **Actions** > **Build Production Mobile Apps** > **Run workflow**.
5. Download the compiled `raktsetu-production-release-bundle.zip` directly from Artifacts!

### Option B: Local Android Build (When Android Studio / SDK is installed)
1. Run keystore generator:
   ```cmd
   scripts\generate_keystore.bat
   ```
2. Move `upload-keystore.jks` to `android/app/upload-keystore.jks`.
3. Copy `android/key.properties.example` to `android/key.properties` and fill in your passwords.
4. Run:
   ```bash
   flutter build appbundle --release --dart-define=API_URL=https://<your-backend-url> --dart-define=BACKEND_TYPE=rest
   ```
5. Output location: `build/app/outputs/bundle/release/app-release.aab`.

---

## 5. Google Play Console Submission Checklist

- [ ] **Google Play Console Account**: Created and identity verified ($25 fee paid).
- [ ] **Create App**: Select "RaktSetu", Category: "Medical" or "Health & Fitness", Default language: "English".
- [ ] **App Integrity / Play App Signing**: Enabled Google Play App Signing.
- [ ] **Store Listing**:
  - **App Title**: `RaktSetu` (under 30 chars).
  - **Short Description**: `Voluntary Blood Donor Registry & Emergency Request Platform`.
  - **Full Description**: Clear description explaining blood group matching, eligibility checks, emergency requests, and blood drives.
  - **App Icon**: 512 x 512 px 32-bit PNG.
  - **Feature Graphic**: 1024 x 500 px PNG/JPEG.
  - **Screenshots**: At least 4 screenshots (phone and 7-inch/10-inch tablets if supported).
- [ ] **Privacy Policy**: Public URL explaining data handling (phone number, voluntary donor details).
- [ ] **Data Safety Form**: Disclose that phone number and name are collected for account management and emergency donor contact, transmitted via HTTPS.
- [ ] **App Content Declarations**: Complete target audience (18+), news apps (No), COVID-19 apps (No), government apps (No).
- [ ] **Testing Track**: Upload `.aab` to Internal or Closed Testing track first. Conduct 14-day closed test with 20 testers (Google Play requirement for personal accounts).

---

## 6. Apple App Store Submission Checklist

- [ ] **Apple Developer Program**: Active membership ($99/year).
- [ ] **Bundle Identifier**: Register `org.raktsetu.blooddonor` in Apple Developer Portal.
- [ ] **Capabilities**: Push Notifications (if FCM enabled).
- [ ] **Xcode Build (Mac Required)**:
  ```bash
  flutter build ipa --release --dart-define=API_URL=https://<your-backend-url> --dart-define=BACKEND_TYPE=rest
  ```
- [ ] **App Store Connect**:
  - Create new iOS App with bundle ID `org.raktsetu.blooddonor`.
  - Primary Category: "Medical".
  - Age Rating: 17+ or 12+ (due to medical reference).
  - Privacy Nutrition Labels: Disclose Contact Info (Phone Number, Name) collected for App Functionality.
  - Upload screenshots: 6.7" iPhone display and 6.5" iPhone display.
  - Provide Demo Credentials for App Review team: Test phone number + static OTP bypass.

---

## 7. Future Upgrades & Maintenance Runbook

### Updating Mobile Application
1. Increment `version` in `pubspec.yaml` (e.g. `version: 0.1.1+2` where `+2` is the incremented versionCode).
2. Run test suite: `flutter test`.
3. Commit and push to Git to trigger GitHub Actions automated build.
4. Upload new `.aab` to Google Play Console and `.ipa` to App Store Connect.

### Updating Backend
1. Modify backend code in `backend/src/`.
2. If schema changes: create new migration in `backend/migrations/` and execute `npm run migrate`.
3. Commit and push to git. Render/Railway will automatically rebuild and redeploy with zero downtime.
