# Dokumentasi Backend - Werk Ticketing

## 📋 Daftar Isi

1. [Overview](#overview)
2. [Arsitektur](#arsitektur)
3. [Struktur Direktori](#struktur-direktori)
4. [Teknologi yang Digunakan](#teknologi-yang-digunakan)
5. [Konfigurasi](#konfigurasi)
6. [Database](#database)
7. [Modul-Modul](#modul-modul)
8. [API Endpoints](#api-endpoints)
9. [Middleware](#middleware)
10. [Integrasi InvGate Armmada](#integrasi-invgate-armmada)
11. [Security](#security)
12. [Cara Menjalankan](#cara-menjalankan)

---

## Overview

Backend Werk Ticketing adalah aplikasi REST API yang dibangun dengan **Go (Golang)** menggunakan framework **Gin**. Aplikasi ini berfungsi sebagai sistem manajemen tiket yang terintegrasi dengan **InvGate Armmada** untuk mengelola insiden dan user management.

### Fitur Utama:
- ✅ Autentikasi dan otorisasi dengan JWT
- ✅ Manajemen user (register, login)
- ✅ Manajemen tiket (create, list, detail)
- ✅ Integrasi dengan InvGate Armmada API
- ✅ Logging dan error handling
- ✅ Database MySQL dengan GORM

---

## Arsitektur

Backend ini mengikuti pola arsitektur **Layered Architecture** dengan pemisahan yang jelas antara:

```
┌─────────────────────────────────────┐
│         HTTP Layer (Gin)            │
│         (Handlers)                  │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│      Business Logic Layer           │
│         (Services)                  │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│      Data Access Layer              │
│      (Repositories)                 │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│         Database (MySQL)            │
│      External API (InvGate)         │
└─────────────────────────────────────┘
```

### Flow Request:
1. **Request** masuk melalui Gin Router
2. **Middleware** memproses (logging, auth, recovery)
3. **Handler** menerima request dan memvalidasi input
4. **Service** menjalankan business logic
5. **Repository/External API** mengakses data
6. **Response** dikembalikan ke client

---

## Struktur Direktori

```
backend/
├── cmd/
│   └── server/
│       └── main.go              # Entry point aplikasi
├── internal/
│   ├── auth/                    # Modul autentikasi
│   │   ├── handler.go          # HTTP handlers untuk auth
│   │   ├── service.go          # Business logic auth
│   │   └── dto.go              # Data Transfer Objects
│   ├── ticket/                  # Modul tiket
│   │   ├── handler.go          # HTTP handlers untuk tiket
│   │   ├── service.go          # Business logic tiket
│   │   ├── model.go            # Model Ticket
│   │   ├── repository.go       # Data access layer
│   │   └── dto.go              # DTO untuk tiket
│   ├── user/                    # Modul user
│   │   ├── model.go            # Model User
│   │   └── repository.go       # Data access layer
│   ├── invgate/                 # Integrasi InvGate API
│   │   ├── service.go          # HTTP client untuk InvGate
│   │   └── types.go            # Type definitions
│   ├── config/                  # Konfigurasi aplikasi
│   │   └── config.go
│   ├── database/                # Database connection
│   │   └── mysql.go
│   ├── middleware/              # HTTP middleware
│   │   ├── auth.go             # JWT authentication
│   │   ├── logging.go          # Request logging
│   │   └── recover.go          # Panic recovery
│   └── response/                # Response utilities
│       └── json.go
├── migrations/                  # SQL migrations
│   ├── 001_create_users.sql
│   └── 002_create_tickets.sql
├── Dockerfile                   # Docker configuration
├── go.mod                       # Go dependencies
├── go.sum                       # Dependency checksums
└── env.example                  # Contoh environment variables
```

---

## Teknologi yang Digunakan

### Core Framework & Libraries:
- **Go 1.25.3** - Bahasa pemrograman
- **Gin v1.10.0** - HTTP web framework
- **GORM v1.25.11** - ORM untuk database
- **MySQL Driver v1.5.7** - Driver untuk MySQL
- **JWT v5.3.0** - JSON Web Token untuk autentikasi
- **Logrus v1.9.3** - Structured logging
- **godotenv v1.5.1** - Environment variable management
- **bcrypt** (via golang.org/x/crypto) - Password hashing

---

## Konfigurasi

Aplikasi menggunakan environment variables untuk konfigurasi. File `.env` harus dibuat berdasarkan `env.example`.

### Environment Variables:

```env
# Server Configuration
SERVER_PORT=8080

# Database Configuration
DB_HOST=db
DB_PORT=3306
DB_USER=armmada
DB_PASSWORD=armmada
DB_NAME=armmada

# JWT Configuration
JWT_SECRET=supersecretjwt

# InvGate Armmada API Configuration
ARMMADA_BASE_URL=https://support.armmada.id/api/v1/
ARMMADA_USERNAME=armmadaweb
ARMMADA_PASSWORD=j8f2yDzuVhYI4eG67hbsbck0
ARMMADA_PAGE_KEY=eyJsYXN0X2lkIjoxMDAwfQ==
```

### Konfigurasi Wajib:
- `JWT_SECRET` - **WAJIB** untuk signing JWT tokens
- `ARMMADA_BASE_URL`, `ARMMADA_USERNAME`, `ARMMADA_PASSWORD` - **WAJIB** untuk integrasi InvGate

### Konfigurasi Opsional:
- `SERVER_PORT` - Default: 8080
- `DB_*` - Default values tersedia untuk development

---

## Database

### Database: MySQL

Aplikasi menggunakan **MySQL** sebagai database utama dengan **GORM** sebagai ORM.

### Connection Pool Settings:
- Max Open Connections: 25
- Max Idle Connections: 25
- Connection Max Lifetime: 5 minutes
- Connection Max Idle Time: 5 minutes

### Schema:

#### Tabel `users`
```sql
CREATE TABLE users (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(190) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

#### Tabel `tickets`
```sql
CREATE TABLE tickets (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    inv_gate_id VARCHAR(100) NOT NULL,
    source_id INT NOT NULL,
    creator_id INT NOT NULL,
    customer_id INT NOT NULL,
    category_id INT NOT NULL,
    type_id INT NOT NULL,
    priority_id INT NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    creator_email VARCHAR(190) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_inv_gate_id (inv_gate_id),
    INDEX idx_creator_email (creator_email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### Auto Migration:
Aplikasi menggunakan GORM AutoMigrate untuk memastikan tabel `users` dan `tickets` selalu tersedia saat startup.

---

## Modul-Modul

### 1. Auth Module (`internal/auth/`)

Modul ini menangani autentikasi dan otorisasi pengguna.

#### Komponen:
- **Handler** (`handler.go`): HTTP endpoints untuk register dan login
- **Service** (`service.go`): Business logic untuk autentikasi
- **DTO** (`dto.go`): Request/Response structures

#### Fitur:
- ✅ User registration dengan validasi email unik
- ✅ User login dengan verifikasi password
- ✅ JWT token generation (expires in 24 hours)
- ✅ Password hashing dengan bcrypt
- ✅ Integrasi dengan InvGate untuk create user

#### Endpoints:
- `POST /api/auth/register` - Register user baru
- `POST /api/auth/login` - Login user

### 2. Ticket Module (`internal/ticket/`)

Modul ini menangani operasi CRUD untuk tiket/insiden.

#### Komponen:
- **Handler** (`handler.go`): HTTP endpoints untuk tiket
- **Service** (`service.go`): Business logic untuk tiket
- **Model** (`model.go`): Ticket entity structure
- **Repository** (`repository.go`): Database operations
- **DTO** (`dto.go`): Request structures

#### Fitur:
- ✅ Create ticket baru (disimpan di InvGate dan database lokal)
- ✅ List tickets dengan pagination
- ✅ Get ticket detail
- ✅ Filter by creator_id
- ✅ Integrasi dengan InvGate API
- ✅ Penyimpanan lokal di database MySQL

#### Endpoints:
- `POST /api/tickets` - Create ticket baru (Protected)
- `GET /api/tickets` - List tickets (Protected)
- `GET /api/tickets/:id` - Get ticket detail (Protected)

### 3. User Module (`internal/user/`)

Modul ini menangani data access layer untuk user.

#### Komponen:
- **Model** (`model.go`): User entity structure
- **Repository** (`repository.go`): Database operations

#### Fitur:
- ✅ Create user
- ✅ Get user by email
- ✅ GORM-based repository pattern

### 4. InvGate Module (`internal/invgate/`)

Modul ini menangani komunikasi dengan InvGate Armmada API.

#### Komponen:
- **Service** (`service.go`): HTTP client untuk InvGate API
- **Types** (`types.go`): Payload structures

#### Fitur:
- ✅ Create user di InvGate
- ✅ Create ticket/incident di InvGate
- ✅ Get ticket list dari InvGate
- ✅ Get ticket detail dari InvGate
- ✅ Basic authentication dengan InvGate
- ✅ Request timeout: 15 seconds
- ✅ Error handling untuk API responses

#### API Methods:
- `CreateUser(ctx, payload)` - Membuat user di InvGate
- `CreateTicket(ctx, payload)` - Membuat ticket di InvGate
- `GetTicketList(ctx, filters)` - Mendapatkan list tickets
- `GetTicketDetail(ctx, ticketID)` - Mendapatkan detail ticket

---

## API Endpoints

### Base URL
```
http://localhost:8080/api
```

### Authentication Endpoints

#### 1. Register User
```http
POST /api/auth/register
Content-Type: application/json

{
  "name": "John",
  "lastname": "Doe",
  "email": "john@example.com",
  "password": "password123"
}
```

**Response (201 Created):**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "name": "John",
  "lastname": "Doe",
  "email": "john@example.com"
}
```

#### 2. Login User
```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "john@example.com",
  "password": "password123"
}
```

**Response (200 OK):**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "name": "John",
  "lastname": "Doe",
  "email": "john@example.com"
}
```

### Ticket Endpoints (Protected - Requires JWT)

#### 3. Create Ticket
```http
POST /api/tickets
Authorization: Bearer <token>
Content-Type: application/json

{
  "source_id": 1,
  "creator_id": 100,
  "customer_id": 200,
  "category_id": 1,
  "type_id": 1,
  "priority_id": 1,
  "title": "Ticket Title",
  "description": "Ticket Description"
}
```

**Response (201 Created):**
```json
{
  "id": 123,
  "title": "Ticket Title",
  ...
}
```

#### 4. List Tickets
```http
GET /api/tickets?creator_id=user@example.com&page_key=eyJsYXN0X2lkIjoxMDAwfQ==
Authorization: Bearer <token>
```

**Query Parameters:**
- `creator_id` (optional): Filter by creator email
- `page_key` (optional): Pagination key

**Response (200 OK):**
```json
{
  "page_key": "eyJsYXN0X2lkIjoxMDAwfQ==",
  "data": [...]
}
```

#### 5. Get Ticket Detail
```http
GET /api/tickets/:id
Authorization: Bearer <token>
```

**Response (200 OK):**
```json
{
  "id": 123,
  "title": "Ticket Title",
  "description": "Ticket Description",
  ...
}
```

### Error Response Format
```json
{
  "error": "Error message here"
}
```

---

## Middleware

Aplikasi menggunakan beberapa middleware untuk menangani berbagai aspek HTTP request:

### 1. Logging Middleware (`middleware/logging.go`)
- Mencatat semua HTTP requests
- Menyimpan informasi: status code, method, path, duration
- Menggunakan Logrus untuk structured logging

### 2. Recover Middleware (`middleware/recover.go`)
- Menangkap panic yang terjadi
- Mengkonversi panic menjadi 500 Internal Server Error
- Mencegah aplikasi crash

### 3. Auth Middleware (`middleware/auth.go`)
- Memvalidasi JWT token dari Authorization header
- Format: `Authorization: Bearer <token>`
- Menyimpan user email ke context untuk digunakan handler
- Mengembalikan 401 Unauthorized jika token invalid

**Usage:**
```go
ticketRoutes.Use(middleware.WithAuth(authService))
```

---

## Integrasi InvGate Armmada

Backend terintegrasi dengan **InvGate Armmada** untuk:
1. **User Management**: Membuat user baru di sistem InvGate saat registrasi
2. **Ticket Management**: Create, read tickets melalui InvGate API

### Konfigurasi:
- Base URL: `ARMMADA_BASE_URL`
- Authentication: Basic Auth (username + password)
- Default Page Key: `ARMMADA_PAGE_KEY` (untuk pagination)

### Flow Integrasi:

#### Saat Register:
1. User register di aplikasi
2. Backend membuat user di database lokal
3. Backend juga membuat user di InvGate Armmada
4. Jika InvGate gagal, registrasi tetap berhasil (dapat disesuaikan)

#### Saat Create Ticket:
1. User membuat ticket melalui API
2. Backend meneruskan request ke InvGate Armmada
3. InvGate mengembalikan ticket yang dibuat (dengan ID)
4. Backend menyimpan ticket ke database lokal dengan:
   - InvGate ID (untuk referensi silang)
   - Semua data ticket
   - Creator email (dari JWT token)
5. Response dikembalikan ke client

---

## Flow Create Ticket (Detail)

Berikut adalah penjelasan lengkap flow create ticket dari awal sampai akhir:

### Diagram Flow:

```
┌─────────────┐
│   Client    │
│  (Frontend) │
└──────┬──────┘
       │
       │ 1. POST /api/tickets
       │    Authorization: Bearer <JWT_TOKEN>
       │    Body: { title, description, source_id, ... }
       │
       ▼
┌─────────────────────────────────────┐
│      Gin Router (main.go)           │
│      Route: POST /api/tickets       │
└──────┬──────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────┐
│   Middleware: Logging               │
│   - Mencatat request masuk          │
└──────┬──────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────┐
│   Middleware: Recover               │
│   - Menangkap panic jika terjadi    │
└──────┬──────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────┐
│   Middleware: WithAuth              │
│   - Extract Authorization header    │
│   - Parse JWT token                 │
│   - Validate token signature        │
│   - Extract user email dari token   │
│   - Set email ke context            │
└──────┬──────────────────────────────┘
       │
       │ Jika token invalid → 401 Unauthorized
       │
       ▼
┌─────────────────────────────────────┐
│   Ticket Handler (handler.go)       │
│   Create() method                   │
└──────┬──────────────────────────────┘
       │
       │ 2. Bind JSON body ke TicketRequest
       │    - Validasi format JSON
       │    - Jika error → 400 Bad Request
       │
       │ 3. Validasi required fields
       │    - Title tidak boleh kosong
       │    - Description tidak boleh kosong
       │    - Jika error → 400 Bad Request
       │
       ▼
┌─────────────────────────────────────┐
│   Ticket Service (service.go)       │
│   CreateTicket() method             │
└──────┬──────────────────────────────┘
       │
       │ 4. Transform TicketRequest ke
       │    invgate.CreateTicketPayload
       │    - Mapping semua field
       │
       ▼
┌─────────────────────────────────────┐
│   InvGate Service (invgate/         │
│   service.go)                       │
│   CreateTicket() method             │
└──────┬──────────────────────────────┘
       │
       │ 5. Build HTTP Request
       │    - Method: POST
       │    - URL: ARMMADA_BASE_URL + "incidents"
       │    - Body: JSON payload
       │    - Header: Basic Auth (username + password)
       │    - Header: Content-Type: application/json
       │
       ▼
┌─────────────────────────────────────┐
│   HTTP Client                       │
│   - Timeout: 15 seconds             │
│   - Send request ke InvGate API     │
└──────┬──────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────┐
│   InvGate Armmada API               │
│   (External Service)                │
│   - Create incident/ticket          │
│   - Return created ticket data      │
└──────┬──────────────────────────────┘
       │
       │ 6. Receive Response
       │    - Status Code check
       │    - Jika >= 400 → Error
       │    - Decode JSON response
       │
       ▼
┌─────────────────────────────────────┐
│   Response Flow (Backward)          │
│   - InvGate Service → Ticket Service│
│   - Ticket Service → Ticket Handler │
│   - Ticket Handler → Response       │
└──────┬──────────────────────────────┘
       │
       │ 7. Return Response
       │    - Status: 201 Created
       │    - Body: Ticket data dari InvGate
       │
       ▼
┌─────────────────────────────────────┐
│   Middleware: Logging               │
│   - Mencatat response (status,      │
│     duration, path)                 │
└──────┬──────────────────────────────┘
       │
       ▼
┌─────────────┐
│   Client    │
│  (Frontend) │
│  Receive    │
│  Response   │
└─────────────┘
```

### Step-by-Step Detail:

#### **Step 1: Client Request**
```http
POST /api/tickets
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json

{
  "source_id": 1,
  "creator_id": 100,
  "customer_id": 200,
  "category_id": 1,
  "type_id": 1,
  "priority_id": 1,
  "title": "Ticket Title",
  "description": "Ticket Description"
}
```

#### **Step 2: Middleware Chain**

**a. Logging Middleware:**
- Mencatat waktu mulai request
- Mencatat method, path, status, duration

**b. Recover Middleware:**
- Menangkap panic jika terjadi
- Convert panic menjadi 500 error

**c. Auth Middleware (`WithAuth`):**
```go
// Extract token dari header
Authorization: Bearer <token>

// Parse dan validate JWT
claims, err := authService.ParseToken(token)

// Set user email ke context
c.Set("userEmail", claims.Subject)
```
- Jika token tidak ada → **401 Unauthorized**
- Jika token invalid → **401 Unauthorized**
- Jika valid → lanjut ke handler

#### **Step 3: Ticket Handler (`handler.go:Create`)**

```go
// 1. Bind JSON body
var req TicketRequest
c.ShouldBindJSON(&req)
// Jika error → 400 Bad Request: "invalid JSON body"

// 2. Validasi required fields
if req.Title == "" || req.Description == "" {
    // → 400 Bad Request: "title and description are required"
}

// 3. Call service
resp, err := h.service.CreateTicket(ctx, req)
// Jika error → 502 Bad Gateway: error message

// 4. Return response
response.Write(c, 201, resp)
```

#### **Step 4: Ticket Service (`service.go:CreateTicket`)**

```go
// Transform request ke InvGate payload
payload := invgate.CreateTicketPayload{
    SourceID:    req.SourceID,
    CreatorID:   req.CreatorID,
    CustomerID:  req.CustomerID,
    CategoryID:  req.CategoryID,
    TypeID:      req.TypeID,
    PriorityID:  req.PriorityID,
    Title:       req.Title,
    Description: req.Description,
}

// 1. Create ticket di InvGate Armmada
invgateResp, err := s.client.CreateTicket(ctx, payload)

// 2. Extract InvGate ID dari response
invGateID := extractID(invgateResp)

// 3. Simpan ticket ke database lokal
ticket := &Ticket{
    InvGateID:    invGateID,
    SourceID:     req.SourceID,
    CreatorID:    req.CreatorID,
    CustomerID:   req.CustomerID,
    CategoryID:   req.CategoryID,
    TypeID:       req.TypeID,
    PriorityID:   req.PriorityID,
    Title:        req.Title,
    Description:  req.Description,
    CreatorEmail: creatorEmail,
}
s.repository.Create(ctx, ticket)

return invgateResp, nil
```

#### **Step 5: InvGate Service (`invgate/service.go:CreateTicket`)**

```go
// Call doRequest dengan:
// - Method: POST
// - Path: "incidents"
// - Body: payload
return s.doRequest(ctx, http.MethodPost, "incidents", payload, nil)
```

#### **Step 6: HTTP Request ke InvGate (`doRequest`)**

```go
// 1. Marshal payload ke JSON
payloadBytes, _ := json.Marshal(payload)

// 2. Build URL
fullURL := "https://support.armmada.id/api/v1/incidents"

// 3. Create HTTP request
req := http.NewRequestWithContext(ctx, "POST", fullURL, bytes.NewBuffer(payloadBytes))

// 4. Set headers
req.SetBasicAuth(username, password)  // Basic Auth
req.Header.Set("Content-Type", "application/json")

// 5. Send request (timeout: 15 seconds)
resp, err := s.client.Do(req)

// 6. Check status code
if resp.StatusCode >= 400 {
    // → Error: "armmada error: ..."
}

// 7. Decode response
var result map[string]interface{}
json.NewDecoder(resp.Body).Decode(&result)
return result, nil
```

#### **Step 7: Response Flow (Backward)**

Response mengalir kembali melalui layer yang sama:
1. **InvGate Service** → return `map[string]interface{}`
2. **Ticket Service** → return response dari InvGate
3. **Ticket Handler** → write response dengan status 201
4. **Middleware Logging** → log response
5. **Client** → receive response

#### **Step 8: Success Response**

```json
HTTP/1.1 201 Created
Content-Type: application/json

{
  "id": 12345,
  "title": "Ticket Title",
  "description": "Ticket Description",
  "source_id": 1,
  "creator_id": 100,
  "status": "open",
  "created_at": "2024-01-01T10:00:00Z",
  ...
}
```

### Error Scenarios:

#### **1. Missing/Invalid Token**
```
Status: 401 Unauthorized
Body: { "error": "missing authorization header" }
atau
Body: { "error": "invalid token" }
```

#### **2. Invalid JSON Body**
```
Status: 400 Bad Request
Body: { "error": "invalid JSON body" }
```

#### **3. Missing Required Fields**
```
Status: 400 Bad Request
Body: { "error": "title and description are required" }
```

#### **4. InvGate API Error**
```
Status: 502 Bad Gateway
Body: { "error": "armmada error: <error message>" }
```

#### **5. Network/Timeout Error**
```
Status: 502 Bad Gateway
Body: { "error": "context deadline exceeded" }
```

### Catatan Penting:

1. **Dual Storage**: Ticket disimpan di **InvGate Armmada** (sumber utama) dan **database lokal** (backup/referensi)
2. **User Email dari Token**: Email user diambil dari JWT token (tidak dari request body) dan disimpan sebagai `creator_email`
3. **InvGate ID**: ID dari InvGate disimpan sebagai `inv_gate_id` untuk referensi silang
4. **Error Handling**: 
   - Jika InvGate gagal, request gagal (502 Bad Gateway)
   - Jika database lokal gagal, request tetap sukses (karena ticket sudah dibuat di InvGate)
5. **Context Propagation**: Context digunakan untuk timeout dan cancellation

---

## Security

### 1. Password Security
- Password di-hash menggunakan **bcrypt** dengan default cost
- Password tidak pernah disimpan dalam plain text
- Password tidak pernah dikembalikan dalam response

### 2. JWT Authentication
- Token menggunakan algoritma **HS256**
- Token expires dalam **24 jam**
- Token berisi:
  - `sub` (subject): User email
  - `iat` (issued at): Waktu token dibuat
  - `exp` (expires at): Waktu token expired

### 3. Input Validation
- Validasi JSON body di handler level
- Validasi required fields
- Error messages yang informatif

### 4. Database Security
- Prepared statements melalui GORM (mencegah SQL injection)
- Connection pooling untuk performa dan security
- Unique constraint pada email

### 5. Error Handling
- Tidak mengekspos error internal ke client
- Generic error messages untuk security
- Detailed logging untuk debugging

---

## Cara Menjalankan

### Prerequisites:
- Go 1.25.3 atau lebih baru
- MySQL database
- Environment variables dikonfigurasi

### 1. Setup Environment
```bash
cd backend
cp env.example .env
# Edit .env dengan konfigurasi yang sesuai
```

### 2. Install Dependencies
```bash
go mod download
```

### 3. Setup Database
```bash
# Pastikan MySQL running
# Database akan dibuat otomatis atau buat manual:
mysql -u root -p
CREATE DATABASE armmada;
```

### 4. Run Migrations (Optional)
```bash
# Migration SQL tersedia di migrations/
mysql -u root -p armmada < migrations/001_create_users.sql
```

### 5. Run Application
```bash
# Dari root backend/
go run cmd/server/main.go

# Atau build terlebih dahulu:
go build -o server cmd/server/main.go
./server
```

### 6. Using Docker
```bash
# Build image
docker build -t werk-ticketing-backend .

# Run container
docker run -p 8080:8080 --env-file .env werk-ticketing-backend
```

### 7. Verify
```bash
# Test health (akan return 404 karena tidak ada endpoint health)
curl http://localhost:8080/api/auth/register
```

---

## Development Notes

### Project Structure Best Practices:
- ✅ Separation of concerns (Handler → Service → Repository)
- ✅ Dependency injection
- ✅ Interface-based design untuk testability
- ✅ Error handling yang konsisten
- ✅ Structured logging

### Future Improvements:
- [ ] Unit tests dan integration tests
- [ ] API documentation dengan Swagger/OpenAPI
- [ ] Rate limiting middleware
- [ ] CORS configuration
- [ ] Health check endpoint
- [ ] Metrics dan monitoring
- [ ] Database migrations dengan tool seperti golang-migrate
- [ ] Graceful shutdown
- [ ] Request validation dengan validator library

---

## Troubleshooting

### Common Issues:

1. **Database Connection Error**
   - Pastikan MySQL running
   - Check DB_HOST, DB_PORT, DB_USER, DB_PASSWORD
   - Pastikan database sudah dibuat

2. **JWT_SECRET Error**
   - Pastikan JWT_SECRET sudah di-set di .env
   - JWT_SECRET tidak boleh kosong

3. **InvGate API Error**
   - Check ARMMADA credentials
   - Pastikan network dapat mengakses ARMMADA_BASE_URL
   - Check API response untuk detail error

4. **Port Already in Use**
   - Change SERVER_PORT di .env
   - Atau kill process yang menggunakan port 8080

---

## License

[Your License Here]

---

**Dokumentasi ini dibuat untuk membantu memahami struktur dan cara kerja backend Werk Ticketing.**

