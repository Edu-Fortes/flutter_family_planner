#!/bin/bash

# 1. Install or Update Flutter
if [ -d "flutter" ]; then
  cd flutter && git pull && cd ..
else
  git clone https://github.com/flutter/flutter.git -b stable
fi

# 2. Enable Web Support
./flutter/bin/flutter config --enable-web

# 3. Recreate the .env file from Vercel Environment Variables
echo "SUPABASE_URL=$SUPABASE_URL" > .env
echo "SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY" >> .env

# 4. Build the App
./flutter/bin/flutter build web --release