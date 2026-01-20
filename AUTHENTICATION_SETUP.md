# Authentication Setup Guide

## ✅ What's Been Fixed

### 1. **Signup Screen Integration**
- ✅ Signup now uses backend API (`ApiService.registerNurse` / `ApiService.registerPatient`)
- ✅ Data is stored in MongoDB database
- ✅ JWT token is saved after registration
- ✅ Automatic navigation after successful signup

### 2. **Login Screen Integration**
- ✅ Login uses backend API (`ApiService.login`)
- ✅ Validates credentials against database
- ✅ Role verification (ensures selected role matches backend role)
- ✅ JWT token is saved after login
- ✅ Automatic navigation based on role

### 3. **API Service Configuration**
- ✅ Base URL configured for Android emulator (`10.0.2.2:5000`)
- ✅ Better error handling with connection messages
- ✅ Token management with SharedPreferences

## 🔧 Configuration

### API Base URL
The app is configured for **Android emulator** by default.

**File:** `lib/services/api_service.dart`

```dart
// Current (Android emulator):
static const String baseUrl = 'http://10.0.2.2:5000/api';

// For iOS simulator, change to:
// static const String baseUrl = 'http://localhost:5000/api';

// For physical device, use your computer's IP:
// static const String baseUrl = 'http://YOUR_IP_ADDRESS:5000/api';
```

**To find your IP address:**
```bash
# Windows PowerShell:
ipconfig | findstr IPv4

# Or use:
(Invoke-WebRequest -Uri "https://api.ipify.org").Content
```

## 📱 Testing Authentication

### 1. **Start Backend Server**
```bash
cd backend
npm start
```

Expected output:
```
MongoDB Connected: ...
Server running on port 5000
MQTT Broker Connected
```

### 2. **Test Registration (Signup)**

**Nurse Registration:**
1. Open Flutter app
2. Go to Sign Up
3. Select "Nurse" role
4. Fill in:
   - Full Name
   - Email
   - Phone Number
   - Location (search for hospital)
   - Nursing License Number
   - Years of Experience
   - Password
   - Confirm Password
5. Agree to Terms & Conditions
6. Click "Sign Up as Nurse"

**Patient Registration:**
1. Select "Caretaker" role
2. Fill in patient details
3. Click "Sign Up as Patient"

**Verify in Database:**
- Check MongoDB Atlas → `healink_db` → `users` collection
- You should see the new user with hashed password

### 3. **Test Login**

1. Open Flutter app
2. Select role (Nurse or Caretaker)
3. Enter email and password
4. Click "Sign In"

**Verify:**
- Token is saved in SharedPreferences
- Navigation to correct dashboard
- User data retrieved from backend

## 🔍 Verify Data in Database

### Option 1: MongoDB Atlas Web Interface
1. Go to: https://cloud.mongodb.com/
2. Click your project → Browse Collections
3. Select `healink_db` database
4. View `users` collection

### Option 2: Test Script
```bash
cd backend
node test-auth-flow.js
```

This will show:
- All registered users
- User details (name, email, role)
- Test tokens for API testing

### Option 3: View All Data Script
```bash
cd backend
node view-all-data.js
```

## 📊 Data Flow

### Registration Flow:
```
Flutter App (Signup) 
  → ApiService.registerNurse/registerPatient()
  → Backend POST /api/auth/register-nurse or /register-patient
  → authController creates user in MongoDB
  → Returns JWT token
  → Flutter saves token in SharedPreferences
  → Navigates to dashboard
```

### Login Flow:
```
Flutter App (Login)
  → ApiService.login()
  → Backend POST /api/auth/login
  → authController verifies credentials
  → Returns JWT token + user data
  → Flutter saves token in SharedPreferences
  → Navigates to dashboard
```

## 🔐 Authentication Details

### JWT Token
- **Expires:** 30 days
- **Stored in:** SharedPreferences (`auth_token`)
- **Used in:** All protected API requests
- **Header format:** `Authorization: Bearer <token>`

### User Roles
- **NURSE:** Full access to all devices, alerts, commands
- **PATIENT:** Only access to assigned device

### Password Security
- Passwords are hashed using bcrypt (10 salt rounds)
- Never stored in plain text
- Not returned in API responses

## 🐛 Troubleshooting

### "Cannot connect to server"
- **Check:** Backend is running (`npm start` in backend folder)
- **Check:** Port 5000 is not blocked
- **Check:** API base URL matches your platform (emulator/device)

### "Invalid email or password"
- **Check:** User exists in database
- **Check:** Password is correct
- **Check:** Email is correct (case-insensitive)

### "Role mismatch"
- **Check:** Selected role matches registered role
- **Check:** User was registered with correct role

### Data not showing in MongoDB
- **Check:** Backend is connected to MongoDB
- **Check:** IP address is whitelisted in MongoDB Atlas
- **Check:** Connection string in `.env` is correct

## ✅ Success Indicators

When everything works:
1. ✅ User can register → Data appears in MongoDB
2. ✅ User can login → Token is saved
3. ✅ User can access protected routes
4. ✅ Data persists across app restarts
5. ✅ Role-based navigation works correctly

## 📝 Next Steps

1. **Test the full flow:**
   - Register a nurse
   - Register a patient
   - Login with both
   - Verify data in MongoDB

2. **Test device assignment:**
   - Assign device to patient (NURSE only)
   - Verify patient can see their device

3. **Test telemetry:**
   - Send MQTT data
   - Verify it's stored in database
   - Verify it appears in app

