import 'package:firebase_auth/firebase_auth.dart';

String authErrorMessage(FirebaseAuthException error) {
  final rawMessage = error.message ?? '';

  if (rawMessage.contains('CONFIGURATION_NOT_FOUND')) {
    return 'Firebase Authentication belum dikonfigurasi. Aktifkan Email/Password di Firebase Console.';
  }

  switch (error.code) {
    case 'invalid-email':
      return 'Format Gmail tidak valid.';
    case 'user-disabled':
      return 'Akun ini sedang dinonaktifkan.';
    case 'user-not-found':
      return 'Akun dengan Gmail ini belum terdaftar.';
    case 'wrong-password':
    case 'invalid-credential':
      return 'Gmail atau password salah.';
    case 'email-already-in-use':
      return 'Gmail ini sudah digunakan.';
    case 'weak-password':
      return 'Password terlalu lemah. Gunakan minimal 6 karakter.';
    case 'network-request-failed':
      return 'Koneksi bermasalah. Coba lagi setelah internet stabil.';
    case 'too-many-requests':
      return 'Terlalu banyak percobaan. Coba lagi nanti.';
    case 'operation-not-allowed':
      return 'Metode email/password belum aktif di Firebase Authentication.';
    case 'app-not-authorized':
      return 'Aplikasi Android ini belum terdaftar benar di Firebase. Cek package name dan SHA di Firebase Console.';
    default:
      return rawMessage.isEmpty ? 'Terjadi kesalahan autentikasi.' : rawMessage;
  }
}
