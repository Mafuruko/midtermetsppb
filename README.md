# Aplikasi Absensi Latihan Paduan Suara

Proyek ini merupakan aplikasi mobile berbasis Flutter yang dikembangkan untuk membantu proses pengelolaan absensi latihan paduan suara. Aplikasi ini mendukung proses autentikasi pengguna, pemilihan tim, pengelolaan anggota, pengelolaan sesi latihan, pencatatan kehadiran, rekapitulasi kehadiran, pengambilan foto selfie sebagai bukti kehadiran, serta pengingat jadwal latihan melalui notifikasi.

Aplikasi dirancang untuk memenuhi kebutuhan tugas Ujian Tengah Semester mata kuliah Pemrograman Perangkat Bergerak dengan memanfaatkan Firebase dan sumber daya smartphone.

## Tujuan Pengembangan

Tujuan utama pengembangan aplikasi ini adalah:

1. Mempermudah admin atau pengelola tim dalam mencatat kehadiran latihan.
2. Menyimpan data secara terstruktur dan terpusat menggunakan Firebase.
3. Memisahkan data berdasarkan akun pengguna dan tim yang dipilih.
4. Menyediakan pengingat latihan agar jadwal lebih mudah dipantau.
5. Memanfaatkan kamera smartphone sebagai bagian dari proses absensi.

## Fitur Utama Aplikasi

Fitur-fitur yang telah diimplementasikan pada aplikasi ini meliputi:

1. Registrasi akun dan login menggunakan Firebase Authentication.
2. Penyimpanan profil pengguna ke Firestore.
3. Pemilihan tim yang terhubung dengan akun pengguna yang sedang login.
4. CRUD data tim.
5. CRUD data anggota pada setiap tim.
6. CRUD data sesi latihan pada setiap tim.
7. CRUD data kehadiran pada setiap sesi latihan.
8. Pengambilan foto selfie menggunakan kamera perangkat sebagai bukti kehadiran.
9. Penyimpanan data utama ke Cloud Firestore.
10. Penjadwalan reminder latihan menggunakan Awesome Notifications.
11. Rekapitulasi kehadiran bulanan berdasarkan data sesi dan absensi.

## Teknologi yang Digunakan

Teknologi dan package utama yang digunakan pada proyek ini adalah sebagai berikut:

- `Flutter`
- `firebase_core`
- `firebase_auth`
- `cloud_firestore`
- `firebase_storage`
- `awesome_notifications`
- `image_picker`
- `path_provider`

## Alur Penggunaan Aplikasi

Secara umum, alur penggunaan aplikasi adalah sebagai berikut:

1. Pengguna membuka aplikasi dan masuk melalui halaman login atau registrasi.
2. Setelah login berhasil, pengguna diarahkan ke halaman pemilihan tim.
3. Pengguna memilih salah satu tim yang dimiliki atau diikuti.
4. Pada dashboard, pengguna dapat masuk ke menu Members, Sessions, Attendance, dan Recap.
5. Pada menu Sessions, pengguna dapat menambah, mengubah, dan menghapus jadwal latihan.
6. Pada menu Members, pengguna dapat menambah, mengubah, dan menghapus data anggota sesuai tim yang dipilih.
7. Pada menu Attendance, pengguna memilih sesi latihan, lalu mengisi status kehadiran setiap anggota dan dapat mengambil foto selfie dengan kamera.
8. Pada menu Recap, pengguna dapat melihat ringkasan kehadiran anggota berdasarkan bulan.

## Struktur Data dan Relasi Database

Penyimpanan data menggunakan Cloud Firestore dengan pola relasi berbasis koleksi dan subkoleksi. Struktur utamanya adalah sebagai berikut:

```text
users/{userId}
teams/{teamId}
teams/{teamId}/members/{memberId}
teams/{teamId}/sessions/{sessionId}
teams/{teamId}/sessions/{sessionId}/attendance/{memberId}
```

Penjelasan relasi:

- Satu `user` dapat memiliki atau mengikuti satu atau lebih `team`.
- Setiap `team` memiliki banyak `members`.
- Setiap `team` memiliki banyak `sessions`.
- Setiap `session` memiliki banyak data `attendance`.
- Data `attendance` terhubung ke `member` dan `session`, sehingga membentuk relasi yang konsisten antar entitas.

Dengan demikian, kebutuhan CRUD dengan pendekatan relational database telah diterapkan menggunakan relasi dokumen Firestore.

## Pemenuhan Komponen Penilaian

Berikut adalah komponen penilaian yang telah digunakan pada aplikasi ini:

| Komponen | Bobot | Implementasi pada Proyek |
| --- | ---: | --- |
| CRUD with a relational database | 10% | Data disimpan dalam struktur relasional Firestore: `teams`, `members`, `sessions`, dan `attendance` dengan hubungan parent-child antarkoleksi. Seluruh entitas utama mendukung operasi Create, Read, Update, dan Delete. |
| Firebase authentication (login, etc.) | 5% | Autentikasi menggunakan Firebase Authentication untuk registrasi, login, dan logout pengguna. |
| Storing data in Firebase | 5% | Data pengguna, tim, anggota, sesi, dan absensi disimpan di Cloud Firestore. |
| Notifications | 5% | Pengingat jadwal latihan diimplementasikan menggunakan `awesome_notifications`. Reminder dibuat berdasarkan sesi latihan yang aktif pada tim yang dipilih pengguna. |
| Using one smartphone resource | 5% | Kamera smartphone digunakan melalui `image_picker` dengan `ImageSource.camera` untuk mengambil selfie sebagai bukti kehadiran. |

## Penjelasan Implementasi Komponen Penting

### 1. CRUD dengan Database Relasional

Aplikasi ini tidak hanya menyimpan data secara terpisah, tetapi menyusun data dalam hubungan yang jelas:

- Tim menjadi entitas utama.
- Setiap tim memiliki data anggota dan sesi latihan sendiri.
- Setiap sesi latihan memiliki data absensi sendiri.
- Dengan pendekatan ini, data anggota pada Team A tidak bercampur dengan Team B, begitu pula data sesi dan absensinya.

Operasi CRUD yang telah tersedia:

- CRUD Team
- CRUD Members
- CRUD Sessions
- CRUD Attendance

### 2. Firebase Authentication

Firebase Authentication digunakan untuk:

- registrasi akun baru,
- login akun yang sudah terdaftar,
- menyimpan status login pengguna,
- logout dari aplikasi.

Saat registrasi berhasil, nama pengguna juga disimpan sebagai `displayName` pada akun Firebase Auth dan profil pengguna disimpan ke koleksi `users` di Firestore.

### 3. Penyimpanan Data pada Firebase

Penyimpanan data utama aplikasi menggunakan Cloud Firestore, antara lain:

- profil pengguna,
- data tim,
- data anggota,
- data sesi latihan,
- data absensi.

Untuk foto selfie absensi, aplikasi mendukung penyimpanan melalui Firebase Storage. Jika Firebase Storage belum aktif pada project, aplikasi tetap menyediakan fallback penyimpanan lokal agar proses absensi tetap dapat berjalan.

### 4. Notifications

Fitur notifikasi menggunakan package `awesome_notifications`. Sistem reminder bekerja sebagai berikut:

- notifikasi dibuat saat sesi latihan ditambahkan atau diperbarui,
- reminder dijadwalkan 30 menit sebelum waktu mulai latihan,
- jika waktu latihan sudah dekat, notifikasi dapat dikirim langsung,
- notifikasi mengikuti tim yang sedang dipilih oleh pengguna pada device tersebut,
- saat logout atau berganti tim, reminder lama dibersihkan agar tidak tercampur dengan data tim lain.

Isi notifikasi menampilkan informasi:

- nama tim,
- lokasi latihan,
- waktu mulai latihan.

### 5. Pemanfaatan Sumber Daya Smartphone

Aplikasi menggunakan kamera smartphone pada fitur absensi. Pengguna dapat mengambil foto selfie langsung dari aplikasi sebagai bukti kehadiran anggota. Fitur ini diimplementasikan dengan package `image_picker` menggunakan sumber `camera`.

## Struktur Halaman Utama

Halaman-halaman utama pada aplikasi ini meliputi:

- Splash Page
- Login Page
- Register Page
- Select Teams Page
- Dashboard Page
- Members Page
- Sessions Page
- Attendance Page
- Recap Page

## Cara Menjalankan Proyek

Langkah-langkah menjalankan aplikasi:

1. Pastikan Flutter SDK sudah terinstal.
2. Pastikan project Firebase sudah dibuat.
3. Tempatkan file `google-services.json` pada folder:

```text
android/app/google-services.json
```

4. Jalankan perintah berikut:

```bash
flutter pub get
flutter run
```

## Catatan Pengujian

Pengujian dasar pada proyek telah dilakukan menggunakan:

```bash
flutter analyze
flutter test
```

## Kesimpulan

Aplikasi absensi latihan paduan suara ini telah memenuhi komponen utama yang dipersyaratkan pada tugas Ujian Tengah Semester, yaitu penggunaan CRUD dengan database relasional, Firebase Authentication, penyimpanan data di Firebase, notifikasi, dan pemanfaatan sumber daya smartphone berupa kamera. Dengan fitur tersebut, aplikasi mampu membantu pengelolaan latihan secara lebih terstruktur, terdokumentasi, dan praktis.
