Local auth server for Mukisa Farm Supply

This is a minimal local authentication server (Node.js + Express + sqlite) intended for on-premise deployments. It provides simple endpoints to register and login users and returns JWT tokens.

Quick start

1. Install Node.js (LTS) on the host machine.
2. In this folder run:

```bash
npm install
```

3. Copy `.env.example` to `.env` and set `JWT_SECRET`.

4. Start the server:

```bash
npm start
```

By default the server runs on `http://localhost:3000`.

API

- POST /register
  - body: { username, password, role? }
  - returns: { token, user }

- POST /login
  - body: { username, password }
  - returns: { token, user }

- GET /me
  - headers: Authorization: Bearer <token>
  - returns: { user }

Notes

- Users are stored in `auth.db` (sqlite) in the same folder.
- Passwords are hashed with bcrypt.
- This server is for local, on-premise use. In production, ensure proper firewalling, backups, and secure secret storage.

Client integration (Flutter)

- Use the `http` package to POST to `/login` and store the returned token in `flutter_secure_storage`.
- Add the `Authorization: Bearer <token>` header to subsequent requests.

If you want, I can:
- Add a small Flutter `LoginScreen` and `AuthProvider` wired to this server.
- Add a CLI script to create an initial admin user.
