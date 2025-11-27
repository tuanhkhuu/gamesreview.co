# OAuth Authentication API Endpoints

**Date**: November 27, 2025  
**Version**: 1.0  
**Base URL**: `https://gamesreview.com`

## Overview

This document describes the OAuth authentication endpoints for the Games Review platform. All authentication is handled via OAuth providers (Google, Twitter, Facebook) with no password-based authentication.

## Authentication Flow

### OAuth Provider Login

Initiates OAuth flow with specified provider.

**Endpoint**: `GET /auth/:provider`

**Parameters**:

- `provider` (path, required): OAuth provider name
  - Allowed values: `google_oauth2`, `twitter2`, `facebook`

**Example Requests**:

```
GET /auth/google_oauth2
GET /auth/twitter2
GET /auth/facebook
```

**Response**: Redirects to OAuth provider's authorization page

**Notes**:

- User will be redirected to provider's consent screen
- After authorization, provider redirects back to callback URL
- CSRF protection handled automatically via session

---

### OAuth Callback

Receives OAuth callback from provider and completes authentication.

**Endpoint**: `GET /auth/:provider/callback`

**Parameters**:

- `provider` (path, required): OAuth provider name
- `code` (query, auto): Authorization code from provider
- `state` (query, auto): CSRF protection state parameter

**Example Request**:

```
GET /auth/google_oauth2/callback?code=abc123&state=xyz789
```

**Success Response (302)**:

```
Location: /dashboard
Set-Cookie: session_id=...; HttpOnly; Secure; SameSite=Lax
```

**Response Details**:

- Creates or finds user account
- Creates or updates identity record
- Establishes authenticated session
- Redirects to dashboard or original destination

**Error Response (302)**:

```
Location: /auth/failure?message=invalid_credentials&strategy=google_oauth2
```

---

### OAuth Failure

Handles OAuth authentication failures.

**Endpoint**: `GET /auth/failure`

**Parameters**:

- `message` (query): Error message from OAuth provider
- `strategy` (query): OAuth provider that failed

**Example Request**:

```
GET /auth/failure?message=access_denied&strategy=google_oauth2
```

**Response (302)**:

```
Location: /sign_in
Flash: alert: "Authentication failed: User denied access"
```

**Common Error Messages**:

- `access_denied`: User cancelled OAuth flow
- `invalid_credentials`: Invalid client ID/secret
- `redirect_uri_mismatch`: Callback URL not configured

---

## Session Management

### Sign In Page

Displays OAuth provider sign-in options.

**Endpoint**: `GET /sign_in`

**Response (200 HTML)**:

```html
<!DOCTYPE html>
<html>
  <body>
    <h1>Sign In</h1>
    <a href="/auth/google_oauth2">Sign in with Google</a>
    <a href="/auth/twitter2">Sign in with Twitter</a>
    <a href="/auth/facebook">Sign in with Facebook</a>
  </body>
</html>
```

---

### Sign Out

Destroys user session and logs out.

**Endpoint**: `DELETE /sign_out`

**Headers**:

- `Cookie: session_id=...` (required)

**Example Request**:

```bash
curl -X DELETE https://gamesreview.com/sign_out \
  -H "Cookie: session_id=abc123" \
  -H "X-CSRF-Token: xyz789"
```

**Success Response (302)**:

```
Location: /
Set-Cookie: session_id=; expires=Thu, 01 Jan 1970 00:00:00 GMT
```

**Notes**:

- Requires CSRF token
- Clears session cookie
- Redirects to homepage

---

## Identity Management

### List Connected Identities

Retrieves user's connected OAuth providers.

**Endpoint**: `GET /identities`

**Authentication**: Required

**Headers**:

- `Cookie: session_id=...` (required)

**Example Request**:

```bash
curl https://gamesreview.com/identities \
  -H "Cookie: session_id=abc123"
```

**Success Response (200 HTML)**:

```html
<!DOCTYPE html>
<html>
  <body>
    <h1>Connected Accounts</h1>
    <ul>
      <li>
        Google - user@example.com
        <a href="/identities/1" data-method="delete">Disconnect</a>
      </li>
      <li>
        Twitter - @username
        <a href="/identities/2" data-method="delete">Disconnect</a>
      </li>
    </ul>
    <a href="/auth/facebook">Connect Facebook</a>
  </body>
</html>
```

**Unauthenticated Response (302)**:

```
Location: /sign_in
```

---

### Connect New Identity

Connects additional OAuth provider to existing account.

**Endpoint**: `POST /identities`

**Authentication**: Required

**Flow**:

1. User clicks "Connect [Provider]" button
2. Redirects to `/auth/:provider`
3. OAuth flow completes
4. New identity created and associated with current user

**Notes**:

- Must be signed in to connect additional providers
- Cannot connect same provider twice
- Email from new provider should match (or account linking logic needed)

---

### Disconnect Identity

Removes OAuth provider connection from account.

**Endpoint**: `DELETE /identities/:id`

**Authentication**: Required

**Parameters**:

- `id` (path, required): Identity ID to disconnect

**Headers**:

- `Cookie: session_id=...` (required)
- `X-CSRF-Token: ...` (required)

**Example Request**:

```bash
curl -X DELETE https://gamesreview.com/identities/123 \
  -H "Cookie: session_id=abc123" \
  -H "X-CSRF-Token: xyz789"
```

**Success Response (302)**:

```
Location: /identities
Flash: notice: "Facebook account disconnected"
```

**Error Response - Last Identity (422)**:

```
Location: /identities
Flash: alert: "Cannot disconnect your last login method"
```

**Error Response - Unauthorized (403)**:

```
Location: /identities
Flash: alert: "You can only manage your own connected accounts"
```

**Business Rules**:

- User must have at least one connected identity
- Can only disconnect own identities
- Successful disconnection redirects to identities list

---

## Authentication State

### Current User Session

Check if user is authenticated (for AJAX/API calls).

**Endpoint**: `GET /auth/session` _(Future Enhancement)_

**Headers**:

- `Cookie: session_id=...`

**Success Response (200 JSON)**:

```json
{
  "authenticated": true,
  "user": {
    "id": 123,
    "email": "user@example.com",
    "name": "John Doe",
    "avatar_url": "https://...",
    "connected_providers": ["google", "twitter"]
  }
}
```

**Unauthenticated Response (200 JSON)**:

```json
{
  "authenticated": false
}
```

---

## Error Responses

### Common HTTP Status Codes

| Code | Meaning               | Description                                         |
| ---- | --------------------- | --------------------------------------------------- |
| 200  | OK                    | Request successful                                  |
| 302  | Found                 | Redirect (most auth responses)                      |
| 401  | Unauthorized          | Authentication required                             |
| 403  | Forbidden             | Insufficient permissions                            |
| 422  | Unprocessable Entity  | Validation error (e.g., can't delete last identity) |
| 500  | Internal Server Error | Server error                                        |

### Error Flash Messages

All authentication errors redirect with flash messages:

```ruby
# Success
flash[:notice] = "Signed in successfully"

# Errors
flash[:alert] = "Authentication failed"
flash[:alert] = "You must sign in to access this page"
flash[:alert] = "Cannot disconnect your last login method"
```

---

## Security

### CSRF Protection

All state-changing requests (POST, DELETE) require CSRF token:

```html
<form action="/sign_out" method="post">
  <input type="hidden" name="_method" value="delete" />
  <input
    type="hidden"
    name="authenticity_token"
    value="<%= form_authenticity_token %>"
  />
  <button>Sign Out</button>
</form>
```

### Session Security

- **HttpOnly**: Cookies not accessible via JavaScript
- **Secure**: HTTPS only in production
- **SameSite**: Lax (prevents CSRF)
- **Timeout**: Sessions expire after 2 weeks of inactivity

### OAuth Security

- **State Parameter**: Prevents CSRF attacks
- **HTTPS Required**: All OAuth callbacks must use HTTPS in production
- **Token Storage**: Access tokens encrypted at rest
- **Minimal Scopes**: Request only necessary permissions

---

## Rate Limiting

_(Future Enhancement)_

```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 99
X-RateLimit-Reset: 1701100800
```

Limits:

- OAuth initiation: 10 requests per minute per IP
- Callback handling: 20 requests per minute per IP
- Identity management: 30 requests per minute per user

---

## Testing

### OmniAuth Test Mode

For testing, use OmniAuth test mode:

```ruby
# In test environment
OmniAuth.config.test_mode = true

# Mock auth hash
OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new({
  provider: 'google_oauth2',
  uid: '123456',
  info: {
    email: 'test@example.com',
    name: 'Test User',
    image: 'https://example.com/avatar.jpg'
  },
  credentials: {
    token: 'mock_token',
    refresh_token: 'mock_refresh_token',
    expires_at: Time.now + 1.week
  }
})
```

### Test Requests

```ruby
# Initiate OAuth (redirects to mock provider)
get '/auth/google_oauth2'

# Simulate callback
get '/auth/google_oauth2/callback'

# Check session
assert session[:user_id].present?
```

---

## Webhook Endpoints

_(Future Enhancement)_

### Provider Account Deletion

Handle account deletion webhooks from OAuth providers:

**Endpoint**: `POST /webhooks/oauth/:provider/account_deletion`

**Purpose**: Comply with provider requirements for user data deletion

---

## API Changelog

### Version 1.0 (2025-11-27)

- Initial OAuth authentication endpoints
- Support for Google, Twitter, Facebook
- Identity management endpoints
- Session management

### Planned Changes

- Add session endpoint for API clients
- Add rate limiting
- Add webhook support for provider events
- Add account linking flow

---

## Related Documentation

- [OAuth Feature Documentation](../features/20251127_oauth_authentication.md)
- [Setup Guide](../../README.md#authentication)
- [Security Best Practices](../security/oauth_security.md)

## Support

For API issues or questions:

- GitHub Issues: [github.com/tuanhkhuu/gamesreview.co/issues]
- Documentation: [docs/]
