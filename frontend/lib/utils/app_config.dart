class AppConfig {
  // ============================================
  // KONFIGURASI BASE URL
  // ============================================
  // 
  // Pilih salah satu sesuai dengan device yang digunakan:
  // 
  // 1. ANDROID EMULATOR: gunakan 'emulator'
  // 2. iOS SIMULATOR: gunakan 'simulator'  
  // 3. PHYSICAL DEVICE: gunakan 'physical' dan set IP_ADDRESS
  // ============================================
  
  static const DeviceType deviceType = DeviceType.physical;
  
  // IP Address komputer Anda (untuk physical device)
  // Cara mendapatkan IP:
  // - Windows: buka CMD, ketik: ipconfig
  //   Cari "IPv4 Address" di bagian "Wireless LAN adapter" atau "Ethernet adapter"
  // - Mac/Linux: buka Terminal, ketik: ifconfig
  //   Cari "inet" di bagian en0 atau eth0
  // Contoh: '192.168.1.100'
  static const String ipAddress = '192.168.0.133';
  
  // Port backend (default: 8080)
  static const int backendPort = 8080;
  
  // API version
  static const String apiVersion = 'v1';
  
  // Get base URL berdasarkan device type
  static String get baseUrl {
    switch (deviceType) {
      case DeviceType.emulator:
        // Android emulator menggunakan 10.0.2.2 untuk akses localhost
        return 'http://10.0.2.2:$backendPort/api/$apiVersion';
      case DeviceType.simulator:
        // iOS simulator bisa langsung akses localhost
        return 'http://localhost:$backendPort/api/$apiVersion';
      case DeviceType.physical:
        // Physical device perlu IP address komputer
        return 'http://$ipAddress:$backendPort/api/$apiVersion';
    }
  }
}

enum DeviceType {
  emulator,    // Android Emulator
  simulator,   // iOS Simulator
  physical,    // Physical Device (HP beneran)
}

