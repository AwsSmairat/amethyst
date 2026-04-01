# Amethyst API — example requests & responses

Base URL: `http://localhost:4000/api`  
Replace `TOKEN` with JWT from `POST /auth/login`.

---

## Auth

### Login

```http
POST /api/auth/login
Content-Type: application/json

{"email":"sohaib@amethyst.local","password":"sohaib123"}
```

```json
{
  "success": true,
  "message": "Logged in",
  "data": {
    "user": {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "email": "sohaib@amethyst.local",
      "role": "super_admin",
      "fullName": "Super Admin",
      "phone": "+10000000001",
      "isActive": true,
      "createdAt": "2026-04-01T12:00:00.000Z",
      "updatedAt": "2026-04-01T12:00:00.000Z"
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

### Me

```http
GET /api/auth/me
Authorization: Bearer TOKEN
```

```json
{
  "success": true,
  "message": "OK",
  "data": { "id": "...", "email": "...", "role": "super_admin", "fullName": "...", "phone": "...", "isActive": true, "createdAt": "...", "updatedAt": "..." }
}
```

---

## Products

### List (paginated)

```http
GET /api/products?page=1&limit=10&sort=name&order=asc&isActive=true
Authorization: Bearer TOKEN
```

```json
{
  "success": true,
  "message": "OK",
  "data": {
    "items": [
      {
        "id": "...",
        "name": "Water Bottle",
        "unitType": "bottle",
        "type": "bottle",
        "price": 1.5,
        "stationStock": 500,
        "stock": 500,
        "isActive": true
      }
    ],
    "pagination": { "total": 3, "page": 1, "limit": 10, "totalPages": 1 }
  }
}
```

### Create

```http
POST /api/products
Authorization: Bearer TOKEN
Content-Type: application/json

{"name":"Water Gallon","type":"gallon","price":3.25,"stock":80}
```

---

## Vehicles

### List

```http
GET /api/vehicles?page=1&limit=20&sort=vehicleNumber&order=asc
Authorization: Bearer TOKEN
```

---

## Vehicle loads

### Create (admin / super_admin)

```http
POST /api/vehicle-loads
Authorization: Bearer TOKEN
Content-Type: application/json

{
  "vehicleId": "<uuid>",
  "driverId": "<uuid>",
  "productId": "<uuid>",
  "quantityLoaded": 50,
  "loadDate": "2026-04-01"
}
```

---

## Station sales

### Create

```http
POST /api/station-sales
Authorization: Bearer TOKEN
Content-Type: application/json

{"productId":"<uuid>","quantity":10,"unitPrice":1.5}
```

---

## Vehicle sales (driver)

### Create

```http
POST /api/vehicle-sales
Authorization: Bearer TOKEN
Content-Type: application/json

{"vehicleId":"<uuid>","productId":"<uuid>","quantity":2,"unitPrice":1.5}
```

### My sales

```http
GET /api/vehicle-sales/my?page=1&limit=20
Authorization: Bearer TOKEN
```

---

## Expenses (driver)

### Create

```http
POST /api/expenses
Authorization: Bearer TOKEN
Content-Type: application/json

{"amount":12.5,"note":"Fuel","vehicleId":"<uuid>"}
```

### My expenses

```http
GET /api/expenses/my?page=1&limit=20
Authorization: Bearer TOKEN
```

---

## Dashboards

### Super admin

```http
GET /api/dashboard/super-admin
Authorization: Bearer TOKEN
```

```json
{
  "success": true,
  "message": "OK",
  "data": {
    "role": "super_admin",
    "generatedAt": "2026-04-01T12:00:00.000Z",
    "metrics": {
      "totalSalesToday": 0,
      "stationSalesToday": 0,
      "vehicleSalesToday": 0,
      "totalExpensesToday": 0,
      "totalProfitToday": 0,
      "totalMonthlySales": 0,
      "remainingStationStock": 700,
      "remainingOnVehicles": 0,
      "remainingOnVehicle": null
    },
    "details": {
      "counts": { "users": 5, "admins": 1, "drivers": 2, "vehicles": 2 },
      "lowStockProducts": [],
      "recentActivities": []
    }
  }
}
```

### Admin

```http
GET /api/dashboard/admin
Authorization: Bearer TOKEN
```

### Driver

```http
GET /api/dashboard/driver
Authorization: Bearer TOKEN
```
