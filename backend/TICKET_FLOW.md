# Ticket Creation Flow

Dokumen ini menjelaskan alur lengkap ketika client memanggil endpoint `POST /api/v1/tickets` pada backend Go.

## 1. Request Masuk (HTTP Layer)
1. Client mengirim request ke `POST /api/v1/tickets` dengan header `Authorization: Bearer <token>`:
   - Tanpa lampiran → body JSON.
   - Dengan lampiran → `multipart/form-data` (field `request` opsional berisi JSON, file `attachments[]`).
2. Router (`router/ticket_routes.go`) menempatkan endpoint ini dalam group yang dilindungi middleware `WithAuth`.

## 2. Middleware
1. **Auth Middleware (`middleware/auth.go`)**
   - Mengekstrak header Authorization.
   - Mem-parse dan memvalidasi JWT via `auth.Service.ParseToken`.
   - Jika token valid, menyimpan email user ke context (`creatorEmail`).
2. Middleware logging & recover tetap berjalan seperti biasa, mencatat request/response dan menangani panic.

## 3. Handler (`ticket/handler.go`)
1. Binding JSON ke `TicketRequest`.
2. Validasi basic field (title, description, dll).
3. Ambil `creatorEmail` dari context (hasil middleware auth).
4. Memanggil `ticket.Service.CreateTicket(ctx, req, creatorEmail)`.
5. Mengembalikan response dengan status `201 Created` menggunakan payload dari InvGate.

## 4. Service (`ticket/service.go`)
1. Membuat `invgate.CreateTicketPayload` dari `TicketRequest` (termasuk attachments jika ada).
2. Memanggil `invgate.Service.CreateTicket` (HTTP POST ke InvGate `incidents`).
3. Mengekstrak `inv_gate_id` dari response InvGate (backend otomatis mencari field `id`, `request_id`, atau `incident_id`).
4. Menyusun entity `ticket.Ticket` untuk penyimpanan lokal (termasuk `CreatorEmail`).
5. Memanggil `ticket.Repository.Create` untuk menyimpan ke database lokal.
   - Jika penyimpanan lokal gagal, error dicatat namun request tetap dianggap berhasil karena tiket sudah dibuat di InvGate.

## 5. Repository & Database
1. `ticket.Repository` menggunakan GORM untuk insert record ke tabel `tickets`.
2. Field yang disimpan meliputi semua metadata ticket, `InvGateID`, `CreatorEmail`, timestamp, dsb.

## 6. Response ke Client
1. Handler mengembalikan response JSON sesuai data dari InvGate.
2. Status HTTP: `201 Created`.

## Diagram Singkat
```
Client
   |
POST /api/v1/tickets (Bearer token)
   |
Gin Router + Middleware (auth/logging/recover)
   |
ticket.Handler.Create
   |
ticket.Service.CreateTicket
   |              \
   |               -> invgate.Service.CreateTicket (HTTP POST incidents)
   |
ticket.Repository.Create (simpan ke DB lokal)
   |
Response 201 (payload InvGate) -> Client
```

