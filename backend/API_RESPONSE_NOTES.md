## API Response Notes – InvGate & Backend

### 1. Incident / Ticket Detail

**Contoh response dari InvGate (juga yang dikonsumsi frontend):**

```json
{
  "assigned_group_id": 133,
  "assigned_id": 144,
  "attachments": [23, 24],
  "category_id": 120,
  "closed_at": null,
  "closed_reason": null,
  "created_at": 1764656882,
  "creator_id": 157,
  "custom_fields": [],
  "data_cleaned": null,
  "date_ocurred": 1764656882,
  "description": "Lenovo Thinkpad",
  "id": 1864,
  "last_update": 1764658240,
  "location_id": 136,
  "pretty_id": "ARM-#1864",
  "priority_id": 5,
  "process_id": null,
  "rating": null,
  "sla_incident_first_reply": null,
  "sla_incident_resolution": null,
  "solved_at": null,
  "source_id": 2,
  "status": "Pending",
  "status_id": 3,
  "title": "Laptop Shutdown Sendiri",
  "type_id": 4,
  "user_id": 157
}
```

**Endpoint backend yang mengembalikan bentuk ini (hampir mentah dari InvGate):**

- `GET /api/v1/tickets/:id`  
  - Handler: `ticket.Handler.GetByID`  
  - Service: `ticket.Service.GetTicketDetail` → `invgate.Service.GetTicketDetail`  
  - Backend hanya menambahkan field `status` (string) berdasarkan `status_id` jika belum ada.

- `POST /api/v1/tickets`  
  - Handler: `ticket.Handler.Create`  
  - Service: `ticket.Service.CreateTicket` → `invgate.Service.CreateTicket` / `CreateTicketWithAttachments`  
  - Mengembalikan payload create dari InvGate (struktur mirip incident detail di atas).

- `GET /api/v1/tickets`  
  - Handler: `ticket.Handler.List`  
  - Service: ambil tiket dari DB lokal, lalu untuk setiap tiket memanggil `invgate.Service.GetTicketDetail`.  
  - Response:

```json
{
  "data": [
    { /* objek incident seperti di atas, plus status (string) */ },
    { /* ... */ }
  ]
}
```

---

### 2. Ticket Comments

**Contoh response comments dari InvGate:**

```json
{
  "data": [
    {
      "attached_files": [],
      "author_id": 157,
      "created_at": 1764656922,
      "customer_visible": true,
      "id": 266,
      "incident_id": 1864,
      "is_solution": false,
      "message": "test",
      "msg_num": 1,
      "reference": null
    },
    {
      "attached_files": [24],
      "author_id": 157,
      "created_at": 1764657946,
      "customer_visible": true,
      "id": 270,
      "incident_id": 1864,
      "is_solution": false,
      "message": "ini test file uploads",
      "msg_num": 5,
      "reference": null
    }
  ]
}
```

**Endpoint backend:**

- `GET /api/v1/tickets/:id/comments`  
  - Handler: `ticket.Handler.GetComments`  
  - Service: `ticket.Service.GetTicketComments` → `invgate.Service.GetTicketComments`  
  - Backend meneruskan payload InvGate **apa adanya** (wrapper `data` tetap).

- `POST /api/v1/tickets/:id/comments`  
  - Handler: `ticket.Handler.AddComment`  
  - Service: `ticket.Service.AddTicketComment` → `invgate.Service.AddTicketComment`  
  - Mengembalikan objek comment yang baru dibuat (struktur dari InvGate).

**Catatan tipe di frontend (`Comment`):**

```ts
interface Comment {
  id?: number;
  comment?: string;      // legacy
  message?: string;      // dari InvGate (field utama)
  author?: string;
  author_id?: number;
  created_at?: number;
  attachments?: number[] | Attachment[];
  attached_files?: number[] | Attachment[];
  [key: string]: any;
}
```

---

### 3. Attachments

**Contoh metadata attachment dari InvGate:**

```json
{
  "id": 17,
  "name": "Rts37YP2qF.png",
  "url": "/uploads/attached_files/requests/1/791ad33c157b408517ebb6fb222c6227/Rts37YP2qF.png",
  "hash": "469e703089bec696585cd9545f642d5e",
  "extension": "png"
}
```

Di payload incident / comments bisa muncul dua bentuk:

- Hanya ID:

```json
"attachments": [23, 24]
"attached_files": [24]
```

- Objek penuh (seperti contoh di atas) bila InvGate meng-embed data attachment.

**Tipe di frontend (`Attachment`):**

```ts
interface Attachment {
  id: number;
  name: string;
  url?: string;
  hash?: string;
  extension?: string;
}
```

**Endpoint backend terkait attachment:**

- `GET /api/v1/tickets/attachments/:attachment_id`  
  - Handler: `ticket.Handler.GetAttachment`  
  - Service: `ticket.Service.GetTicketAttachment` → `invgate.Service.GetTicketAttachment`  
  - Mengembalikan:
    - Body: binary file
    - Header: `Content-Type` dari InvGate (fallback `application/octet-stream`)  
    - Header: `Content-Disposition: attachment; filename="<name>"` jika metadata menyediakan nama file.

**Cara frontend memakai:**

- Jika hanya punya ID (`number`):
  - Pakai URL backend: `GET /api/v1/tickets/attachments/:id`.
- Jika sudah punya objek `Attachment` dengan `url`:
  - Bisa membangun direct URL ke InvGate: `ARMMADA_BASE_URL + url`.

---

### 4. Endpoint Backend yang Meneruskan Response InvGate

Daftar singkat endpoint yang responsenya berasal dari InvGate (langsung atau hampir langsung):

- Incident / Ticket:
  - `POST /api/v1/tickets`
  - `GET /api/v1/tickets`
  - `GET /api/v1/tickets/:id`
- Comments:
  - `GET /api/v1/tickets/:id/comments`
  - `POST /api/v1/tickets/:id/comments`
- Attachments:
  - `GET /api/v1/tickets/attachments/:attachment_id`
- Solution:
  - `PUT /api/v1/tickets/:id/solution`
  - `PUT /api/v1/tickets/:id/solution/reject`
- Categories:
  - `GET /api/v1/categories` (data dari InvGate, difilter ID tertentu di service tiket)


