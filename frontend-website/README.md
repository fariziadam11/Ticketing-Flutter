# Frontend - Werk Ticketing System

Frontend aplikasi ticketing menggunakan Vue 3, TypeScript, Carbon Design System, TanStack Query, dan Pinia.

## Tech Stack

- **Vue 3** (Composition API, `<script setup>`)
- **TypeScript** (strict mode)
- **Vue Router** - Routing
- **Axios** - HTTP client
- **TanStack Query** - Server state management
- **Pinia** - UI state management
- **Carbon Web Components** - UI components (Web Components, bukan Vue components)
- **Bun** - Runtime & package manager
- **Vite** - Build tool

## Setup

### 1. Install Dependencies

```bash
bun install
```

### 2. Environment Configuration

Copy `.env.example` to `.env` and configure:

```env
VITE_API_BASE_URL=http://localhost:8080/api/v1
```

### 3. Run Development Server

```bash
bun run dev
```

Aplikasi akan berjalan di `http://localhost:5173`

## Project Structure

```
src/
  api/              # API services
    http.ts         # Axios instance dengan interceptors
    tickets.ts      # Ticket API
    comments.ts     # Comments API
    attachments.ts  # Attachments API
    categories.ts   # Categories API
    types.ts        # TypeScript types
  composables/      # Vue composables
    useTickets.ts
    useTicketDetail.ts
    useCreateTicket.ts
    useComments.ts
    useCategories.ts
  stores/           # Pinia stores
    ui.ts           # UI state (sidebar, theme)
  components/       # Vue components
    tickets/
      TicketTable.vue
      TicketDetailCard.vue
    comments/
      CommentList.vue
      CommentItem.vue
    attachments/
      AttachmentPreview.vue
  pages/            # Page components
    Tickets/
      List.vue      # Ticket list page
      Detail.vue    # Ticket detail page
      Create.vue    # Create ticket page
  plugins/          # Vue plugins
    vueQuery.ts     # TanStack Query setup
    pinia.ts        # Pinia setup
  router/           # Vue Router
    index.ts
  utils/            # Utility functions
    date.ts         # Date formatting
```

## Features

### Ticket List Page (`/tickets`)

- DataTable dengan Carbon components
- Search functionality
- Pagination
- Status badges dengan Carbon Tag
- Row clickable untuk navigasi ke detail
- Format UNIX timestamp ke readable date

### Ticket Detail Page (`/tickets/:id`)

- Breadcrumb navigation
- StructuredList untuk detail ticket
- Comments list dengan add comment modal
- Attachment preview (gambar) atau download button
- Grid layout dengan Carbon Grid

### Create Ticket Page (`/tickets/create`)

- Form dengan Carbon components
- Category selection
- File upload support (multipart)
- Validation
- Redirect ke detail setelah sukses

## API Integration

### Endpoints

- `GET /api/v1/tickets` - List tickets
- `GET /api/v1/tickets/:id` - Ticket detail
- `POST /api/v1/tickets` - Create ticket (multipart)
- `GET /api/v1/tickets/:id/comments` - List comments
- `POST /api/v1/tickets/:id/comments` - Add comment (multipart)
- `GET /api/v1/tickets/attachments/:id` - Download attachment
- `GET /api/v1/categories` - List categories

### Authentication

Token authentication menggunakan Bearer token di header:
```
Authorization: Bearer <token>
```

Token disimpan di `localStorage` dengan key `token`.

## State Management

### TanStack Query (Server State)

- `useTickets()` - Fetch tickets list
- `useTicketDetail(id)` - Fetch ticket detail
- `useCreateTicket()` - Create ticket mutation
- `useComments(ticketId)` - Fetch comments
- `useCreateComment(ticketId)` - Add comment mutation
- `useCategories()` - Fetch categories

### Pinia (UI State)

- `useUiStore()` - UI state (sidebar, theme)

## Build

```bash
bun run build
```

Output akan berada di folder `dist/`.

## Preview Production Build

```bash
bun run preview
```

## Notes

- Semua timestamp menggunakan format UNIX (seconds)
- File upload menggunakan multipart/form-data
- Query invalidation otomatis setelah mutation sukses
- Error handling dengan interceptors Axios
- TypeScript strict mode enabled
- Menggunakan Carbon Web Components (bukan @carbon/vue yang deprecated)
- Lihat `CARBON_SETUP.md` untuk dokumentasi penggunaan Carbon Web Components
