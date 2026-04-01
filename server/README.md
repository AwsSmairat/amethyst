# Amethyst API

REST API for the **Amethyst Water Station — Accounting & Management** system. Built with **Node.js**, **Express**, **PostgreSQL**, **Prisma**, and **JWT** authentication.

## Features

- JWT authentication (`Authorization: Bearer <token>`)
- Role-based access: `super_admin`, `admin`, `driver`
- Users, vehicles, products, vehicle loads, station sales, vehicle sales, expenses, returns
- Audit logging for critical mutations
- Dashboard and reporting endpoints
- Request validation (Zod), centralized errors
- **Consistent list queries**: `page`, `limit`, `sort`, `order`, `dateFrom`, `dateTo`, `vehicleId`, `driverId`, `productId`, `status`, `isActive` (where applicable)
- **OpenAPI 3** + **Swagger UI** at `/api/docs` and raw spec at `/api/openapi.json`

Base path for JSON resources: **`/api`**

## Requirements

- Node.js 18+
- PostgreSQL 14+

## Setup

1. **Create a PostgreSQL database** (example name: `amethyst`).

2. **Copy environment file**

   ```bash
   cd server
   cp .env.example .env
   ```

   Edit `DATABASE_URL` and `JWT_SECRET`.

3. **Install dependencies**

   ```bash
   npm install
   ```

4. **Generate Prisma Client & run migrations**

   ```bash
   npx prisma generate
   npx prisma migrate dev --name init
   ```

5. **Seed sample data**

   ```bash
   npx prisma db seed
   ```

6. **Start the server**

   ```bash
   npm run dev
   ```

7. **Smoke-test routes** (with the server running — from the `server` directory)

   ```bash
   npm run verify:routes
   npm run verify:protected
   ```

   - `verify:routes` — public endpoints (`/`, `/api/health`, `/api/docs`, OpenAPI).
   - `verify:protected` — login as seeded **super_admin**, **admin**, **driver**; checks `/auth/me`, RBAC on dashboards/users, driver isolation on vehicle sales / expenses / loads. Requires DB seed.

## URLs

| URL | Description |
|-----|-------------|
| `GET /` | Root message |
| `GET /health` | Legacy health |
| `GET /api/health` | API health JSON |
| `GET /api/docs` | **Swagger UI** |
| `GET /api/openapi.json` | OpenAPI document |
| **Swagger UI** | **[http://localhost:4000/api/docs](http://localhost:4000/api/docs)** — try endpoints with **Authorize** (Bearer JWT from login) |

## Seeded accounts

| Role | Email | Password |
|------|--------|----------|
| Super Admin | `super@amethyst.local` | `SuperAdmin123!` |
| Admin | `admin@amethyst.local` | `Admin123!` |
| Driver | `driver1@amethyst.local` | `Driver123!` |
| Driver | `driver2@amethyst.local` | `Driver123!` |

## How to test login

```bash
curl -s -X POST http://localhost:4000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"super@amethyst.local","password":"SuperAdmin123!"}'
```

**Example success shape:**

```json
{
  "success": true,
  "message": "Logged in",
  "data": {
    "user": {
      "id": "...",
      "email": "super@amethyst.local",
      "role": "super_admin",
      "fullName": "Super Admin",
      "phone": "+10000000001",
      "isActive": true,
      "createdAt": "...",
      "updatedAt": "..."
    },
    "token": "eyJhbGciOi..."
  }
}
```

Copy `data.token` for protected routes.

### First-time bootstrap

If the database has **no users**, `POST /api/auth/register` creates the first `super_admin` (see OpenAPI). After that, use `POST /api/users` (**super_admin only**) to create `admin` / `driver` accounts.

## How to test protected routes (Bearer token)

```bash
export TOKEN="<paste_jwt_here>"

curl -s http://localhost:4000/api/auth/me \
  -H "Authorization: Bearer $TOKEN"

curl -s "http://localhost:4000/api/products?page=1&limit=10&sort=name&order=asc" \
  -H "Authorization: Bearer $TOKEN"
```

## Pagination, filtering, sorting

List endpoints accept (validated where noted):

| Query | Meaning |
|-------|---------|
| `page` | Page number (default 1) |
| `limit` | Page size (max 100, default 20) |
| `sort` | Field name (resource-specific allowlist in code) |
| `order` | `asc` or `desc` (default `desc`) |
| `dateFrom` / `dateTo` | Date or ISO datetime filters (where supported) |
| `vehicleId`, `driverId`, `productId` | UUID filters |
| `status` | e.g. `open` / `closed` on vehicle loads |
| `isActive` | `true` / `false` (products, etc.) |

**Paginated list response:**

```json
{
  "success": true,
  "message": "OK",
  "data": {
    "items": [],
    "pagination": { "total": 0, "page": 1, "limit": 20, "totalPages": 0 }
  }
}
```

## Dashboard response shape

All dashboard endpoints return:

```json
{
  "success": true,
  "message": "OK",
  "data": {
    "role": "super_admin | admin | driver",
    "generatedAt": "ISO-8601",
    "metrics": { },
    "details": { }
  }
}
```

`metrics` always includes comparable keys (use `null` when not applicable for that role). See Swagger examples under **Dashboard**.

## Security behavior (summary)

| Role | Access |
|------|--------|
| **super_admin** | All management routes; `POST /users`; `DELETE /users`; `GET /dashboard/super-admin`; can also use `GET /dashboard/admin`. |
| **admin** | Operations + `GET /dashboard/admin`; **cannot** `POST /users`, `DELETE /users`, or `GET /dashboard/super-admin` / `GET /dashboard/driver`. User list excludes `super_admin`. |
| **driver** | Vehicle/expense/sales flows for **own** data; `GET /dashboard/driver`; **cannot** list users or station sales. |

- **Driver**: list/detail endpoints for sales, expenses, loads, vehicles filter to the authenticated driver (`driverId === req.user.id`) or assigned vehicle where required.
- **Admin**: cannot create users (`POST /users` is super_admin-only); cannot delete users; user lists exclude `super_admin`; cannot change another admin’s account (service rules).
- **Super admin**: full management access where routes allow.

## Common test flow

1. Start Postgres, run migrations, **seed** (`npx prisma db seed`).
2. `npm run dev` in `server/`.
3. `npm run verify:routes` then `npm run verify:protected`.
4. Open **[http://localhost:4000/api/docs](http://localhost:4000/api/docs)** → **Authorize** → `Bearer <token>` from `POST /auth/login`.
5. Exercise modules (users, products, vehicles, loads, sales, expenses, dashboards) from Swagger or curl below.

## Example curl commands

Set the base URL and token after login:

```bash
export API=http://localhost:4000/api

# Login (super admin)
curl -s -X POST "$API/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"super@amethyst.local","password":"SuperAdmin123!"}'

export TOKEN="<paste data.token from response>"

# Me
curl -s "$API/auth/me" -H "Authorization: Bearer $TOKEN"

# List products
curl -s "$API/products?page=1&limit=10" -H "Authorization: Bearer $TOKEN"

# Create product (admin or super_admin token)
curl -s -X POST "$API/products" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"Water Bottle","type":"bottle","price":1.5,"stock":100}'

# Create vehicle load — replace UUIDs from GET /vehicles, GET /users (driver), GET /products
curl -s -X POST "$API/vehicle-loads" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"vehicleId":"<uuid>","driverId":"<uuid>","productId":"<uuid>","quantityLoaded":20,"loadDate":"2026-04-01"}'

# Vehicle sale — use driver token; vehicle must belong to that driver
export DRIVER_TOKEN="<login as driver1@amethyst.local>"
curl -s -X POST "$API/vehicle-sales" \
  -H "Authorization: Bearer $DRIVER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"vehicleId":"<uuid>","productId":"<uuid>","quantity":1,"unitPrice":1.5}'

# Expense (driver)
curl -s -X POST "$API/expenses" \
  -H "Authorization: Bearer $DRIVER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"amount":10,"note":"Fuel","vehicleId":"<uuid>"}'

# Dashboards
curl -s "$API/dashboard/super-admin" -H "Authorization: Bearer $TOKEN"
curl -s "$API/dashboard/admin" -H "Authorization: Bearer $TOKEN"
curl -s "$API/dashboard/driver" -H "Authorization: Bearer $DRIVER_TOKEN"
```

## Example requests & responses

See **`docs/api-examples.md`** (request/response samples) and **`openapi/openapi.json`** (full OpenAPI). Quick samples:

### Auth — login

**Request:** `POST /api/auth/login`  
**Body:** `{ "email": "super@amethyst.local", "password": "SuperAdmin123!" }`  
**Response:** `{ "success": true, "message": "Logged in", "data": { "user": {...}, "token": "..." } }`

### Products — create

**Request:** `POST /api/products` (Bearer: admin or super_admin)  
**Body:** `{ "name": "Water Bottle", "type": "bottle", "price": 1.5, "stock": 500 }`  
(`type`/`stock` are aliases for `unitType` / `stationStock`.)

**Response:** `{ "success": true, "message": "Product created", "data": { "id": "...", "unitType": "bottle", "type": "bottle", "stationStock": 500, "stock": 500, ... } }`

### Vehicles — list

**Request:** `GET /api/vehicles?page=1&limit=20&sort=createdAt&order=desc`  
**Response:** paginated `items` with `driver` relation when present.

### Vehicle loads — create

**Request:** `POST /api/vehicle-loads`  
**Body:** `{ "vehicleId": "...", "driverId": "...", "productId": "...", "quantityLoaded": 50, "loadDate": "2026-04-01" }`  
**Effect:** decrements station stock for that product.

### Station sales — create

**Request:** `POST /api/station-sales`  
**Body:** `{ "productId": "...", "quantity": 10, "unitPrice": 1.5 }`

### Vehicle sales — create (driver)

**Request:** `POST /api/vehicle-sales`  
**Body:** `{ "vehicleId": "...", "productId": "...", "quantity": 2, "unitPrice": 1.5 }`  
**Rules:** vehicle must belong to driver; sale consumes open load stock (FIFO).

### Expenses — create (driver)

**Request:** `POST /api/expenses`  
**Body:** `{ "amount": 12.5, "note": "Fuel", "vehicleId": "..." }`

### Dashboards

- `GET /api/dashboard/super-admin` — super_admin only  
- `GET /api/dashboard/admin` — admin + super_admin  
- `GET /api/dashboard/driver` — driver only  

## Postman

Import **`docs/postman_collection.json`**. Set variables `baseUrl` = `http://localhost:4000/api` and `token` after login.

## Scripts

| Command | Description |
|---------|-------------|
| `npm run dev` | Dev server with watch |
| `npm start` | Production start |
| `npm run verify:routes` | Public route smoke test |
| `npm run verify:protected` | Auth + RBAC + driver isolation (needs seed + running server) |
| `npx prisma studio` | DB browser |
| `npx prisma migrate dev` | Create/apply migrations |

## License

Proprietary — internal use.
