# Flutter API Communication Fix - Complete

## ✅ Fixed Files

### 1. **`lib/services/api_service.dart`** - COMPLETELY REWRITTEN

**Key Changes:**
- ✅ **Base URL**: Changed to WiFi IP `http://192.168.29.232:5000`
- ✅ **Timeout**: Added 10-second timeout to all HTTP requests
- ✅ **Error Handling**: Comprehensive error handling with readable messages
- ✅ **Logging**: Detailed console logs for debugging
- ✅ **CORS**: Proper headers with `Content-Type` and `Accept`
- ✅ **Response Parsing**: Safe JSON parsing with error handling
- ✅ **Token Management**: Automatic token saving on login/signup

**Base URL Configuration:**
```dart
static const String BASE_URL = "http://192.168.29.232:5000";
static const String API_BASE = "$BASE_URL/api";
```

**To Change IP Address:**
1. Open `lib/services/api_service.dart`
2. Find line 8: `static const String BASE_URL = "http://192.168.29.232:5000";`
3. Replace `192.168.29.232` with your computer's WiFi IP address
4. Save the file

### 2. **`lib/screens/login_screen.dart`** - ENHANCED

**Key Changes:**
- ✅ Better error messages for different error types
- ✅ Success message on login
- ✅ Proper navigation after login
- ✅ Timeout and connection error handling

### 3. **`lib/screens/signup_screen.dart`** - ENHANCED

**Key Changes:**
- ✅ Better error messages for different error types
- ✅ Success message on signup
- ✅ Proper navigation after signup
- ✅ Timeout and connection error handling

## 🔧 Features Added

### 1. **Request Timeout**
All HTTP requests now have a 10-second timeout:
```dart
.timeout(Duration(seconds: 10))
```

### 2. **Error Handling**
- **Timeout Errors**: "Connection timeout. Please check your internet connection."
- **Connection Errors**: "Cannot connect to server. Please check: ..."
- **Authentication Errors**: "Invalid email or password."
- **Validation Errors**: Clear messages for missing/invalid fields

### 3. **Logging**
All API calls now log:
- Request URL
- Request body (password hidden)
- Response status code
- Response body
- Success/error messages

### 4. **Headers**
All requests include:
```dart
{
  'Content-Type': 'application/json',
  'Accept': 'application/json',
}
```

## 📋 API Endpoints Used

### Authentication
- `POST /api/auth/login` - User login
- `POST /api/auth/register-nurse` - Nurse registration
- `POST /api/auth/register-patient` - Patient registration
- `GET /api/auth/me` - Get current user (protected)

### Expected Request Format

**Login:**
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Register Nurse:**
```json
{
  "name": "John Doe",
  "email": "nurse@example.com",
  "password": "password123"
}
```

**Register Patient:**
```json
{
  "name": "Jane Doe",
  "email": "patient@example.com",
  "password": "password123"
}
```

### Expected Response Format

**Success:**
```json
{
  "success": true,
  "data": {
    "_id": "user_id",
    "name": "User Name",
    "email": "user@example.com",
    "role": "NURSE" | "PATIENT",
    "assignedDevice": null,
    "token": "jwt_token_here"
  }
}
```

**Error:**
```json
{
  "success": false,
  "message": "Error message here"
}
```

## 🧪 Testing

### 1. **Test Backend Connection**
```bash
# From your computer, test:
curl http://192.168.29.232:5000/api/health
```

Expected response:
```json
{
  "success": true,
  "message": "HEALINK Backend is running",
  "timestamp": "2024-01-01T00:00:00.000Z"
}
```

### 2. **Test from Flutter App**

1. **Start Backend:**
   ```bash
   cd backend
   npm start
   ```

2. **Run Flutter App:**
   ```bash
   flutter run
   ```

3. **Test Signup:**
   - Fill in signup form
   - Submit
   - Check console logs for API calls
   - Verify user is created in MongoDB

4. **Test Login:**
   - Use credentials from signup
   - Submit login
   - Check console logs
   - Verify navigation to dashboard

## 🔍 Debugging

### Console Logs

When you run the app, you'll see detailed logs:

```
🔐 Attempting login...
   Email: user@example.com
   URL: http://192.168.29.232:5000/api/auth/login
   Request body: {"email":"user@example.com","password":"***"}
📡 Login Response:
   Status Code: 200
   Body: {"success":true,"data":{...}}
✅ Login successful
   Token saved
   Role: NURSE
```

### Common Issues

1. **"Cannot connect to server"**
   - Check backend is running: `npm start` in backend folder
   - Verify IP address is correct
   - Check device is on same WiFi network
   - Check firewall isn't blocking port 5000

2. **"Connection timeout"**
   - Check internet connection
   - Verify backend is accessible
   - Try increasing timeout in `api_service.dart`

3. **"Invalid email or password"**
   - Verify credentials are correct
   - Check user exists in MongoDB
   - Verify password hasn't been changed

4. **"User already exists"**
   - Email is already registered
   - Use a different email or login instead

## 📱 Network Configuration

### For Android Emulator
- Use `10.0.2.2` instead of `localhost`
- Or use your computer's WiFi IP

### For Physical Device
- Must use your computer's WiFi IP address
- Device must be on same WiFi network
- Find IP: `ipconfig` (Windows) or `ifconfig` (Mac/Linux)

### For iOS Simulator
- Use `localhost` or WiFi IP
- Both should work

## ✅ Verification Checklist

- [ ] Backend is running on port 5000
- [ ] Backend accessible at `http://192.168.29.232:5000/api/health`
- [ ] Flutter app uses correct IP in `api_service.dart`
- [ ] Device/emulator is on same network
- [ ] Firewall allows port 5000
- [ ] Signup creates user in MongoDB
- [ ] Login works with created credentials
- [ ] Token is saved after login/signup
- [ ] Navigation works after login/signup

## 🎯 Next Steps

1. **Update IP Address** (if needed):
   - Edit `lib/services/api_service.dart`
   - Change `BASE_URL` to your WiFi IP

2. **Test Signup:**
   - Create a new account
   - Verify in MongoDB

3. **Test Login:**
   - Login with created account
   - Verify navigation

4. **Check Logs:**
   - Monitor console for API calls
   - Verify all requests succeed

---

**All fixes applied!** The Flutter app should now communicate correctly with your backend at `http://192.168.29.232:5000`.

