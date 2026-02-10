# Werk Ticketing Mobile App

Aplikasi mobile Flutter untuk sistem ticketing Werk yang terintegrasi dengan backend Go.

## Fitur

- ✅ **Autentikasi**: Login dan Register
- ✅ **Manajemen Tiket**: 
  - Buat tiket baru
  - Lihat daftar tiket
  - Detail tiket
  - Edit tiket
  - Komentar pada tiket
- ✅ **UI Modern**: Material Design 3 dengan tema yang konsisten
- ✅ **State Management**: Menggunakan Provider pattern
- ✅ **Local Storage**: Token dan user data disimpan menggunakan SharedPreferences

## Struktur Proyek

```
lib/
├── main.dart                 # Entry point aplikasi
├── models/                   # Data models
│   ├── auth_model.dart
│   └── ticket_model.dart
├── services/                 # Business logic & API calls
│   ├── auth_service.dart
│   └── ticket_service.dart
├── screens/                  # UI Screens
│   ├── login_screen.dart
│   ├── register_screen.dart
│   ├── ticket_list_screen.dart
│   ├── ticket_detail_screen.dart
│   └── create_ticket_screen.dart
└── utils/                    # Utilities
    └── api_client.dart       # HTTP client wrapper
```

## Setup

### 1. Install Dependencies

```bash
cd frontend
flutter pub get
```

### 2. Konfigurasi API Base URL

**Cara Mudah - Edit `lib/utils/app_config.dart`:**

Buka file `lib/utils/app_config.dart` dan sesuaikan:

```dart
// Untuk Android Emulator
static const DeviceType deviceType = DeviceType.emulator;

// Untuk iOS Simulator  
static const DeviceType deviceType = DeviceType.simulator;

// Untuk Physical Device (HP beneran)
static const DeviceType deviceType = DeviceType.physical;
static const String ipAddress = '192.168.1.100'; // Ganti dengan IP komputer Anda
```

**Cara Mendapatkan IP Address Komputer:**

**Windows:**
1. Buka Command Prompt (CMD)
2. Ketik: `ipconfig`
3. Cari "IPv4 Address" di bagian:
   - "Wireless LAN adapter Wi-Fi" (jika pakai WiFi)
   - "Ethernet adapter" (jika pakai kabel)
4. Copy IP address (contoh: `192.168.1.100`)

**Mac/Linux:**
1. Buka Terminal
2. Ketik: `ifconfig` atau `ip addr`
3. Cari "inet" di bagian `en0` (WiFi) atau `eth0` (Ethernet)
4. Copy IP address

**Penting untuk Physical Device:**
- ✅ Pastikan HP dan komputer dalam **WiFi yang sama**
- ✅ Pastikan firewall tidak memblokir port 8080
- ✅ Pastikan backend listening di `0.0.0.0:8080` (bukan hanya `127.0.0.1:8080`)

### 3. Pastikan Backend Berjalan

Pastikan backend Go sudah berjalan di port 8080 (atau sesuai konfigurasi).

### 4. Run Aplikasi

```bash
flutter run
```

## API Endpoints yang Digunakan

### Authentication
- `POST /api/v1/auth/register` - Register user baru
- `POST /api/v1/auth/login` - Login user
- `POST /api/v1/auth/refresh` - Refresh token
- `POST /api/v1/auth/revoke` - Revoke token

### Tickets
- `GET /api/v1/tickets` - List semua tiket
- `GET /api/v1/tickets/:id` - Detail tiket
- `POST /api/v1/tickets` - Buat tiket baru
- `PUT /api/v1/tickets/:id` - Update tiket
- `GET /api/v1/tickets/:id/comments` - List komentar
- `POST /api/v1/tickets/:id/comments` - Tambah komentar

### Metadata
- `GET /api/v1/categories` - List kategori
- `GET /api/v1/statuses` - List status
- `GET /api/v1/ticket-meta` - Metadata lengkap (categories, statuses, types, priorities, sources)

## Dependencies

- `http`: HTTP client untuk API calls
- `shared_preferences`: Local storage untuk token dan user data
- `intl`: Format tanggal dan waktu
- `provider`: State management (optional, untuk future enhancement)

## Catatan Penting

1. **Token Management**: Token JWT disimpan di SharedPreferences dan otomatis ditambahkan ke setiap request yang memerlukan autentikasi.

2. **Error Handling**: Semua error dari API ditangani dan ditampilkan sebagai SnackBar.

3. **Refresh**: Pull-to-refresh tersedia di halaman ticket list.

4. **Navigation**: Aplikasi menggunakan Navigator standard Flutter untuk routing.

## Troubleshooting

### Error: Connection refused / Failed to connect

**Untuk Android Emulator:**
1. ✅ Pastikan `deviceType = DeviceType.emulator` di `app_config.dart`
2. ✅ Pastikan backend sudah berjalan
3. ✅ Test backend: `http://localhost:8080/health`

**Untuk Physical Device:**
1. ✅ Pastikan `deviceType = DeviceType.physical` di `app_config.dart`
2. ✅ Pastikan `ipAddress` sudah benar (cek dengan `ipconfig` atau `ifconfig`)
3. ✅ Pastikan HP dan komputer dalam **WiFi yang sama**
4. ✅ Test backend dari HP browser: `http://<IP_COMPUTER>:8080/health`
5. ✅ Pastikan firewall Windows tidak memblokir port 8080
   - Buka Windows Defender Firewall → Advanced Settings
   - Inbound Rules → New Rule → Port → TCP → 8080 → Allow
6. ✅ Pastikan backend listening di `0.0.0.0:8080` (bukan `127.0.0.1:8080`)

**Troubleshooting:**
- Coba ping IP dari HP: buka browser di HP, akses `http://<IP>:8080/health`
- Jika tidak bisa akses, cek firewall dan pastikan dalam network yang sama
- Cek log backend untuk melihat apakah request sampai

### Error: 401 Unauthorized
- Token mungkin expired, coba logout dan login lagi
- Pastikan backend JWT_SECRET sudah dikonfigurasi dengan benar

### Error: Failed to load ticket metadata
- Pastikan backend dapat mengakses InvGate API
- Periksa kredensial InvGate di backend `.env`

### Error: 401 Unauthorized
- Token mungkin expired, coba logout dan login lagi
- Pastikan backend JWT_SECRET sudah dikonfigurasi dengan benar

### Error: Failed to load ticket metadata
- Pastikan backend dapat mengakses InvGate API
- Periksa kredensial InvGate di backend

## Development Notes

- Aplikasi menggunakan Material Design 3
- Semua screens responsive dan mendukung dark mode (jika diaktifkan)
- Error handling sudah diimplementasikan di semua service layer
