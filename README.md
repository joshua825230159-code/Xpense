# Dokumentasi Teknis & Arsitektur Aplikasi Xpense

https://github.com/user-attachments/assets/a01420fd-9b98-4182-a849-d2cfe123fd82

https://youtube.com/shorts/I1ZCUK5RzLQ?feature=share

Dokumen ini menjelaskan detail teknis, arsitektur, skema database, dan alur data yang digunakan dalam pengembangan aplikasi Xpense.

## 1. Arsitektur Aplikasi (MVVM)

Aplikasi ini menerapkan pola desain **Model-View-ViewModel (MVVM)** dengan **Provider** sebagai *State Management*.

* **Model**: Merepresentasikan struktur data (`Account`, `Transaction`, `User`). Menggunakan `Equatable` untuk membandingkan objek dan metode `toMap`/`fromMap` untuk serialisasi database.
* **View**: UI (Screen/Widget) yang hanya bertugas menampilkan data dan merespons input pengguna. UI bersifat reaktif mendengarkan perubahan pada ViewModel via `Consumer`.
* **ViewModel (`ChangeNotifier`)**:
    * `AuthViewModel`: Menangani status login, register, dan sesi user.
    * `MainViewModel`: Menangani logika bisnis utama (CRUD akun/transaksi, kalkulasi saldo, konversi kurs).
    * **Dependency Injection**: Menggunakan `ProxyProvider` di `main.dart` untuk menyuntikkan `AuthViewModel` ke dalam `MainViewModel`. Ini memastikan data di `MainViewModel` selalu sinkron dengan User ID yang sedang login.

## 2. Database Lokal (SQLite)

Penyimpanan data utama menggunakan **sqflite**. Akses database dibungkus dalam pola **Singleton** melalui class `SqliteService` untuk memastikan hanya ada satu koneksi database yang aktif.

### Skema Database (Relasional)
Database `xpense.db` memiliki versi skema 5.

**Tabel: `users`**

| Kolom | Tipe | Keterangan |
| :--- | :--- | :--- |
| `id` | INTEGER | Primary Key (Auto Increment) |
| `username` | TEXT | Unique, Not Null |
| `password` | TEXT | **Hashed (SHA-256)** |
| `isPremium` | INTEGER | 0 = Free, 1 = Premium |

**Tabel: `accounts`**

| Kolom | Tipe | Keterangan |
| :--- | :--- | :--- |
| `id` | TEXT | Primary Key (UUID String) |
| `userId` | INTEGER | **Foreign Key** -> `users.id` (ON DELETE CASCADE) |
| `balance` | REAL | Saldo saat ini |
| `currencyCode`| TEXT | Kode mata uang (ISO 4217) |
| `type`, `name`, `colorValue`, `budget` | ... | Metadata akun |

**Tabel: `transactions`**

| Kolom | Tipe | Keterangan |
| :--- | :--- | :--- |
| `id` | TEXT | Primary Key (UUID String) |
| `accountId` | TEXT | **Foreign Key** -> `accounts.id` (ON DELETE CASCADE) |
| `amount` | REAL | Nilai transaksi |
| `type` | TEXT | 'income' atau 'expense' |
| `date` | TEXT | ISO8601 String |
| `iconValue` | INTEGER | CodePoint ikon kategori |

> **Catatan**: `PRAGMA foreign_keys = ON` diaktifkan setiap kali koneksi dibuka, memastikan integritas referensial (Cascade Delete aktif).

## 3. API & Networking

Aplikasi menggunakan layanan pihak ketiga untuk konversi mata uang secara *real-time*.

* **Provider API**: [Frankfurter API](https://api.frankfurter.app) (Open Source).
* **Client**: `package:http`.
* **Endpoints**:
    1.  **Get All Rates**: `GET /latest?from={baseCurrency}`
        * Digunakan untuk menghitung "Total Balance" gabungan di Dashboard.
    2.  **Specific Conversion**: `GET /latest?from={A}&to={B}`
        * Digunakan saat mengedit akun dan mengubah mata uangnya untuk konversi saldo yang presisi.

## 4. Strategi Caching (Rate Limiting)

Untuk efisiensi bandwidth dan performa, aplikasi menerapkan strategi **Time-To-Live (TTL) Caching** manual menggunakan `SharedPreferences`.

**Alur Logika (`api_service.dart`):**
1.  **Cek Cache**: Saat meminta kurs, aplikasi memeriksa `SharedPreferences` untuk key `cached_all_rates_{currency}`.
2.  **Validasi Timestamp**: Aplikasi mengecek timestamp `rates_cache_timestamp_{currency}`.
    * **Hit**: Jika data ada DAN umur cache < 24 jam, gunakan data lokal.
    * **Miss**: Jika data tidak ada ATAU umur cache > 24 jam, panggil API.
3.  **Auto Update**: User dapat mematikan `isAutoUpdateEnabled`. Jika mati, aplikasi akan selalu menggunakan cache terakhir tanpa validasi waktu.

## 5. Keamanan (Security)

* **Password Hashing**:
    * Library: `crypto`.
    * Algoritma: **SHA-256**.
    * Implementasi: Password di-hash sebelum disimpan ke database (`register`) dan sebelum dicocokkan saat login (`login`).
* **Isolasi Data**:
    * Setiap query `accounts` menyertakan filter `WHERE userId = ?`.
    * Ini memastikan isolasi data antar pengguna meskipun menggunakan satu perangkat yang sama.

## 6. Mekanisme Ekspor (Premium)

Fitur ini menggunakan pengecekan flag `user.isPremium`.

* **PDF Generation**:
    * Library: `pdf`.
    * Membuat dokumen PDF secara programatik, menghitung total Pemasukan/Pengeluaran, dan merender tabel transaksi.
* **CSV Generation**:
    * Library: `csv`.
    * Mengonversi List objek `Transaction` menjadi format *Comma Separated Values*.
* **File Handling**:
    * File disimpan sementara di direktori dokumen aplikasi (`path_provider`).
    * File dibagikan ke aplikasi lain (WhatsApp, Email, Drive) menggunakan `share_plus`.

## 7. Visualisasi Statistik (Pie Chart)

Fitur statistik memvisualisasikan komposisi pengeluaran dan pemasukan berdasarkan kategori menggunakan pie chart interaktif.

* **Library**: `fl_chart`.
* **Logika Agregasi**:
    * Transaksi difilter berdasarkan periode yang dipilih (Harian, Mingguan, Bulanan, Tahunan).
    * Data dikelompokkan (*grouped*) berdasarkan kategori dan dijumlahkan nilainya.
    * Daftar kategori diurutkan dari nilai terbesar ke terkecil

* **Optimasi Performa**:
    * **Isolate (`compute`)**: Proses kalkulasi statistik yang berat dialihkan ke *background thread* jika jumlah transaksi melebihi 500 item, mencegah *UI freeze*.
    * **RepaintBoundary**: Membungkus widget chart untuk memisahkan *render layer*, sehingga animasi atau perubahan UI lain tidak memicu penggambaran ulang grafik.
* **Interaksi User**:
    * Implementasi `PieTouchData` untuk mendeteksi sentuhan pengguna, yang secara dinamis memperbesar radius sektor diagram yang dipilih.

## 8. Algoritma Kalkulasi "Total Balance"

Menghitung total kekayaan pengguna dengan portofolio multi-mata uang:

1.  Tentukan `baseCurrency` (biasanya mata uang akun yang sedang aktif).
2.  Ambil nilai tukar (Rates) untuk base currency tersebut.
3.  Iterasi semua akun milik user:
    * Jika `account.currency == baseCurrency`: Tambahkan `account.balance`.
    * Jika `account.currency != baseCurrency`:
        * Cari rate konversi.
        * Konversi: `Balance / Rate`.
        * Tambahkan hasil konversi ke total.
