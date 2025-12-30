# Family Planner 🏡

A robust, cross-platform family management application designed to run on **Android**, **iOS (via PWA)**, and **Raspberry Pi (Linux)**.

The app acts as a central hub for family organization, featuring a "Smart Mirror" dashboard for home displays and mobile views for on-the-go management.

![Status](https://img.shields.io/badge/Status-Active-success)
![Flutter](https://img.shields.io/badge/Flutter-3.x-blue)
![Supabase](https://img.shields.io/badge/Backend-Supabase-green)

## ✨ Features

- **🔐 Role-Based Authentication:**
  - **Admin:** Can generate invite codes and manage family members.
  - **Members:** Can view/edit data but cannot modify family structure.
  - **Virtual Members:** "Ghost" profiles for children (assigned colors/avatars) managed by Admins.
- **📅 Family Calendar:**
  - Real-time synchronization.
  - Color-coded events based on family members.
  - Support for "All Day" and specific time events.
- **🛒 Real-time Grocery List:**
  - Instant sync across devices using Supabase Realtime.
  - Categorized items (Produce, Dairy, etc.).
  - One-tap completion and "Clear Completed" cleanup.
- **🖥️ Responsive Dashboard:**
  - **Mobile:** Bottom navigation for quick access.
  - **Desktop/Pi:** "Smart Mirror" layout with Big Clock, Daily Quotes, and Sidebar navigation.

## 🛠️ Tech Stack

- **Frontend:** Flutter (Dart)
- **Backend:** Supabase (PostgreSQL, Auth, Realtime)
- **State Management:** Riverpod
- **Routing:** GoRouter
- **UI Components:** Material 3, Syncfusion Calendar

---

## 🚀 Getting Started

### Prerequisites

1.  **Flutter SDK:** [Install Flutter](https://flutter.dev/docs/get-started/install)
2.  **Supabase Account:** [Create a project](https://supabase.com/)

### 1. Environment Setup

Create a `.env` file in the root directory:

```env
SUPABASE_URL=[https://your-project-id.supabase.co](https://your-project-id.supabase.co)
SUPABASE_ANON_KEY=your-anon-key-here
```

_Note: Ensure .env is listed in your pubspec.yaml assets._

### 2. Database Setup

This project uses SQL migrations to structure the database.

Install Supabase CLI:

```
Bash

brew install supabase/tap/supabase  # macOS
# Or see Supabase docs for Windows/Linux
```

Login and Link:

```
Bash

supabase login
supabase link --project-ref your-project-id
```

Push Schema to Cloud:

```
Bash

supabase db push
```

### 3. Running Locally

```
Bash

# Get dependencies
flutter pub get

# Run on specific device
flutter run -d chrome      # Web
flutter run -d <device_id> # Android
flutter run -d linux       # Linux (Raspberry Pi)

```

## 📦 Deployment

### 🌐 Web (Vercel / PWA)

To deploy to Vercel, you must override the default build command to install Flutter first.

1. Push code to GitHub.

2. Import Project in Vercel.

3. Build Settings:

   - Framework Preset: Other

   - Build Command:

   ```
   Bash

   if [ -d "flutter" ]; then cd flutter && git pull && cd .. ; else git clone [https://github.com/flutter/flutter.git](https://github.com/flutter/flutter.git); fi && ls && flutter/bin/flutter doctor && flutter/bin/flutter clean && flutter/bin/flutter config --enable-web && flutter/bin/flutter build web --release

   ```

   - Output Directory: build/web

4. Environment Variables: Add SUPABASE_URL and SUPABASE_ANON_KEY in Vercel settings if you use them in the build process (though typically these are bundled in the .env file during build).

_Tip: For iOS usage, open the site in Safari, tap "Share", and select "Add to Home Screen"._

## 🤖 Android

1. Update android/app/src/main/AndroidManifest.xml to include Internet permissions.

2. Build the APK:

```
Bash

flutter build apk --release
```

3. Install build/app/outputs/flutter-apk/app-release.apk on your device.

## 🥧 Raspberry Pi (Linux)

**On the Raspberry Pi 5:**

1. Install Flutter dependencies:

```
Bash

sudo apt install -y curl git unzip xz-utils zip libglu1-mesa clang cmake ninja-build pkg-config libgtk-3-dev
```

2. Clone this repo and build:

```
Bash

flutter build linux --release

```

3. Run the bundle:

```
Bash

./build/linux/arm64/release/bundle/family_planner
```

## 🤝 Contributing

1. Fork the repository.

2. Create your feature branch (git checkout -b feature/AmazingFeature).

3. Commit your changes (git commit -m 'Add some AmazingFeature').

4. Push to the branch (git push origin feature/AmazingFeature).

5. Open a Pull Request.

## 📄 License

Distributed under the MIT License.
