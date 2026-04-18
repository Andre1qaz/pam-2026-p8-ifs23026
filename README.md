# pam-2026-p8-ifs23026

**Delcom Todos Flutter App — PAM Praktikum 8**  
**Nama:** Andre Christian Saragih  
**NIM:** ifs23026 / IFS23026

---

## Deskripsi

Aplikasi Flutter fullstack untuk manajemen Todo menggunakan REST API backend Ktor (Kotlin).

## Fitur Utama (Improvement)

- ✅ **Home**: Progress LinearProgressIndicator (selesai/total) + persentase
- ✅ **Todos**: Filter chip (Semua / Selesai / Belum) + Search
- ✅ **Todos**: Paginasi infinite scroll (10 data per halaman, muat lebih saat scroll ke bawah)
- ✅ **Profil**: Upload foto profil (Web, Android, iOS) menggunakan Uint8List
- ✅ **Profil**: Edit nama & username + ganti kata sandi
- ✅ **Auth**: Login, Register, Logout dengan token persisten (SharedPreferences)
- ✅ **Theme**: Dark / Light mode toggle
- ✅ **Cover Todo**: Upload cover dari galeri

## Struktur Folder

```
lib/
├── core/
│   └── constants/
│       ├── api_constants.dart
│       └── route_constants.dart
├── data/
│   ├── models/
│   │   ├── api_response_model.dart
│   │   ├── todo_model.dart
│   │   └── user_model.dart
│   └── services/
│       ├── auth_service.dart
│       ├── auth_repository.dart
│       ├── todo_service.dart
│       └── todo_repository.dart
├── features/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   ├── home/
│   │   └── home_screen.dart
│   ├── profile/
│   │   └── profile_screen.dart
│   └── todos/
│       ├── todos_screen.dart
│       ├── todos_add_screen.dart
│       ├── todos_detail_screen.dart
│       └── todos_edit_screen.dart
├── providers/
│   ├── auth_provider.dart
│   ├── theme_provider.dart
│   └── todo_provider.dart
├── shared/
│   ├── widgets/
│   │   ├── app_snackbar.dart
│   │   ├── bottom_nav_widget.dart
│   │   ├── error_widget.dart
│   │   ├── loading_widget.dart
│   │   └── top_app_bar_widget.dart
│   └── shell_scaffold.dart
├── app_router.dart
└── main.dart
```

## Cara Menjalankan

```bash
# Install dependencies
flutter pub get

# Run di Android/iOS
flutter run

# Run di Web
flutter run -d chrome
```

## Backend API

- Repo: https://github.com/auxtern/pam-2026-p5-ifs18005-be  
- Deployed: https://pam-2026-p5-ifs18005-be.delcom.org:8080
