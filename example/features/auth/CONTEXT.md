# Auth Module Context

## 🎯 Responsibility
> Handles user authentication, session management, and secure token storage.

## 🏗️ Internal Architecture
- `AuthService`: Communicates with the backend API.
- `AuthRepository`: Manages local storage of tokens.
- `AuthState`: Riverpod provider for current user status.

## 🔌 Public Interface
- **Providers**: `authProvider`, `userProvider`
- **Routes**: `/login`, `/register`

## 📏 Standards
- All tokens must be stored in secure storage.
- Never log passwords or tokens.
