# Ngrok Interstitial Page Fix

## Problem
When uploading profile pictures, you get: "Server returned HTML instead of JSON. This might be an ngrok interstitial page."

## Root Cause
Ngrok's free tier shows an interstitial warning page before allowing access. This page is HTML, not JSON, so the app can't parse it.

## Solution 1: Visit URL in Browser First (RECOMMENDED)

1. **Open your browser** (Chrome, Firefox, etc.)
2. **Visit this URL**: `https://unfogged-maxton-irenically.ngrok-free.dev`
3. **Click "Visit Site"** button on the ngrok warning page
4. **Wait 2-3 seconds** for the page to load
5. **Go back to your Flutter app** and try uploading the profile picture again

This accepts the ngrok warning and allows subsequent API requests to work.

## Solution 2: Use ngrok Static Domain (Paid)

If you have ngrok paid plan:
1. Get a static domain from ngrok
2. Update `BASE_URL` in `lib/services/api_service.dart`
3. Static domains don't show interstitial pages

## Solution 3: Deploy to Railway/Heroku

Instead of ngrok, deploy your backend to:
- **Railway** (recommended - free tier available)
- **Heroku** (free tier limited)
- **Render** (free tier available)

Then update `BASE_URL` to your deployment URL.

## Current Implementation

The app now:
- ✅ Sends `ngrok-skip-browser-warning: any` header
- ✅ Uses custom HTTP client for better compatibility
- ✅ Detects HTML responses and shows helpful error messages
- ✅ Provides clear instructions when ngrok page is detected

## Quick Fix Steps

1. Open browser
2. Visit: `https://unfogged-maxton-irenically.ngrok-free.dev/api/health`
3. Click "Visit Site" on ngrok page
4. Try uploading profile picture in app again

The header should work after you've visited the URL once in a browser.

