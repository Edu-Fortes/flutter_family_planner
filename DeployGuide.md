# 🚀 Family Planner: Deployment Protocol

## The Database Migration (Supabase Cloud)

If the data base was altered proceed with the cloud update applying the migration files:

```
bash
supabase db push
```

_\* the project must be connected to the Supabase_

## Deploying For Web (Vercel)

### A. Go to Vercel Dashboard.

Select your Project -> Settings -> Environment Variables.

Add the new enveronmnt variables keys as needed

_\* **Note:** These will apply on the next deployment._

### B. Web Deployment (Wife's iPhone)

Since you use Vercel, this is triggered by Git.

Commit & Push your local changes o main branch:

```
bash

git add .
git commit -m "<Git commit message>"
git push origin main
```

**Wait:** Vercel detects the push and automatically rebuilds the site.

**Verify:** Open the URL on your wife's phone. Refresh the page.

## For Raspberry Pi (Linux)

The Smart Mirror needs to pull the code and rebuild the binary.

SSH into your Pi (or open the terminal on it):

```
Bash

ssh user@raspberrypi.local
cd ~/flutter_family_planner
```

Update Code:

```
Bash

git pull origin main
```

Update Secrets:

Edit the .env file: nano .env

Paste your newly environments variables at the bottom.

Save (Ctrl+O, Enter) and Exit (Ctrl+X).

Build & Run:

```
Bash

flutter build linux --release
```

Restart the App:

If you have it running as a service: sudo systemctl restart family_planner

If running manually: Close the old window and run ./build/linux/x64/release/bundle/family_planner

## Android Deployment (Your Phone)

We need to build a fresh APK and install it.

Connect your Phone to your PC via USB.

Clean & Build:

```
Bash

flutter clean
flutter pub get
flutter build apk --release
```

Install:

```
Bash

flutter install
```

(Or copy the file build/app/outputs/flutter-apk/app-release.apk to your phone and tap to install).
