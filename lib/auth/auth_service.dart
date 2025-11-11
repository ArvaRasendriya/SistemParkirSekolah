import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _sessionKey = 'user_session';
  static const String _userIdKey = 'user_id';
  static const String _emailKey = 'user_email';

  // ===============================
  // 🔐 Hash Password
  // ===============================
  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  // ===============================
  // 💾 Save Session (Local Storage)
  // ===============================
  Future<void> _saveSession(String userId, String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, userId);
    await prefs.setString(_emailKey, email.toLowerCase());
    await prefs.setBool(_sessionKey, true);
    debugPrint('✅ Session saved for: $email');
  }

  // ===============================
  // 🗑️ Clear Session
  // ===============================
  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    await prefs.remove(_emailKey);
    await prefs.setBool(_sessionKey, false);
    debugPrint('✅ Session cleared');
  }

  // ===============================
  // 🔍 Check if Logged In
  // ===============================
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_sessionKey) ?? false;
  }

  // ===============================
  // 📧 Get Current User Email
  // ===============================
  Future<String?> getCurrentUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey);
  }

  // ===============================
  // 🆔 Get Current User ID
  // ===============================
  Future<String?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  // ===============================
  // 🔐 Sign In
  // ===============================
  Future<Map<String, dynamic>> signInWithEmailPassword(
      String email, String password) async {
    try {
      // Normalize email
      final normalizedEmail = email.trim().toLowerCase();
      final hashedPassword = _hashPassword(password);

      debugPrint('🔄 Attempting login for: $normalizedEmail');

      // Query database untuk cari user
      final result = await _supabase
          .from('profiles')
          .select('id, email, password, role, status, full_name, kelas, jurusan')
          .eq('email', normalizedEmail)
          .maybeSingle();

      if (result == null) {
        throw Exception('Email tidak terdaftar.');
      }

      // Cek password
      final storedPassword = result['password'] as String?;
      if (storedPassword != hashedPassword) {
        throw Exception('Password salah.');
      }

      // Cek status akun
      final status = result['status'] as String?;
      if (status == 'pending') {
        throw Exception(
            'Akun Anda belum disetujui. Silakan hubungi admin untuk menyetujui akun Anda.');
      }

      if (status == 'rejected') {
        throw Exception('Akun Anda ditolak oleh admin.');
      }

      // Save session
      await _saveSession(result['id'], normalizedEmail);

      debugPrint('✅ Sign in successful: $normalizedEmail');
      return result;
    } catch (e) {
      debugPrint('❌ Sign in error: $e');
      rethrow;
    }
  }

  // ===============================
  // 🧾 Sign Up
  // ===============================
  Future<Map<String, dynamic>> signUpWithEmailPassword(
    String email,
    String password, {
    String? fullName,
    String? kelas,
    String? jurusan,
  }) async {
    try {
      // Normalize email
      final normalizedEmail = email.trim().toLowerCase();
      final hashedPassword = _hashPassword(password);

      debugPrint('🔄 Starting sign up for: $normalizedEmail');

      // Cek apakah email sudah terdaftar
      final existing = await _supabase
          .from('profiles')
          .select('email')
          .eq('email', normalizedEmail)
          .maybeSingle();

      if (existing != null) {
        throw Exception('Email sudah terdaftar. Silakan gunakan email lain atau login.');
      }

      // Generate UUID untuk user ID
      final userId = _generateUUID();

      // Insert user baru
      final result = await _supabase.from('profiles').insert({
        'id': userId,
        'email': normalizedEmail,
        'password': hashedPassword,
        'role': 'satgas',
        'status': 'pending',
        'full_name': fullName,
        'kelas': kelas,
        'jurusan': jurusan,
      }).select().single();

      debugPrint('✅ Sign up successful: $normalizedEmail');
      debugPrint('⏳ Status: Pending approval');

      // TIDAK auto login karena butuh approval dulu
      return result;
    } catch (e) {
      debugPrint('❌ Sign up error: $e');
      rethrow;
    }
  }

  // ===============================
  // 🚪 Sign Out
  // ===============================
  Future<void> signOut() async {
    try {
      await _clearSession();
      debugPrint('✅ Sign out successful');
    } catch (e) {
      debugPrint('❌ Sign out error: $e');
    }
  }

  // ===============================
  // 🎭 Get User Role
  // ===============================
  Future<String?> getUserRole() async {
    final email = await getCurrentUserEmail();
    if (email == null) return null;

    try {
      final data = await _supabase
          .from('profiles')
          .select('role')
          .eq('email', email)
          .maybeSingle();
      return data?['role'] as String?;
    } catch (e) {
      debugPrint('Error fetching user role: $e');
      return null;
    }
  }

  // ===============================
  // 🧩 Get User Status
  // ===============================
  Future<String?> getUserStatus() async {
    final email = await getCurrentUserEmail();
    if (email == null) return null;

    try {
      final data = await _supabase
          .from('profiles')
          .select('status')
          .eq('email', email)
          .maybeSingle();
      return data?['status'] as String?;
    } catch (e) {
      debugPrint('Error fetching user status: $e');
      return null;
    }
  }

  // ===============================
  // 👤 Get User Profile
  // ===============================
  Future<Map<String, dynamic>?> getUserProfile() async {
    final email = await getCurrentUserEmail();
    if (email == null) return null;

    try {
      final data = await _supabase
          .from('profiles')
          .select('id, email, role, status, full_name, kelas, jurusan')
          .eq('email', email)
          .maybeSingle();
      return data;
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      return null;
    }
  }

  // ===============================
  // ⏳ Get All Pending Profiles
  // ===============================
  Future<List<Map<String, dynamic>>> getPendingProfiles() async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('id, email, full_name, role, kelas, jurusan, created_at')
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      if (response is List) {
        return response.cast<Map<String, dynamic>>();
      } else {
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching pending profiles: $e');
      return [];
    }
  }

  // ===============================
  // ✅ Approve / Reject Profile
  // ===============================
  Future<void> updateProfileStatus(String profileId, String status) async {
    try {
      final currentUserId = await getCurrentUserId();
      final updateData = {'status': status};
      
      if (currentUserId != null) {
        updateData['approved_by'] = currentUserId;
      }

      await _supabase.from('profiles').update(updateData).eq('id', profileId);

      debugPrint('✅ Profile status updated: $profileId -> $status');
    } catch (e) {
      debugPrint('Error updating profile status: $e');
      rethrow;
    }
  }

  // ===============================
  // 👥 Get All Satgas Accounts
  // ===============================
  Future<List<Map<String, dynamic>>> getSatgasAccounts() async {
    try {
      final response = await _supabase
          .from('profiles')
          .select(
              'id, email, full_name, role, kelas, jurusan, status, created_at')
          .eq('role', 'satgas')
          .order('created_at', ascending: false);

      if (response is List) {
        return response.cast<Map<String, dynamic>>();
      } else {
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching satgas accounts: $e');
      return [];
    }
  }

  // ===============================
  // 🗑️ Delete Satgas Account
  // ===============================
  Future<void> deleteSatgasAccount(String userId) async {
    try {
      // Hapus langsung dari tabel profiles
      await _supabase.from('profiles').delete().eq('id', userId);

      debugPrint('✅ Account deleted: $userId');
    } catch (e) {
      debugPrint('Error deleting satgas account: $e');
      rethrow;
    }
  }

  // ===============================
  // 🔄 Change Password
  // ===============================
  Future<void> changePassword(String oldPassword, String newPassword) async {
    try {
      final email = await getCurrentUserEmail();
      if (email == null) throw Exception('Not logged in');

      // Verify old password
      final hashedOldPassword = _hashPassword(oldPassword);
      final user = await _supabase
          .from('profiles')
          .select('password')
          .eq('email', email)
          .single();

      if (user['password'] != hashedOldPassword) {
        throw Exception('Password lama salah');
      }

      // Update password
      final hashedNewPassword = _hashPassword(newPassword);
      await _supabase
          .from('profiles')
          .update({'password': hashedNewPassword})
          .eq('email', email);

      debugPrint('✅ Password changed successfully');
    } catch (e) {
      debugPrint('Error changing password: $e');
      rethrow;
    }
  }

  // ===============================
  // 🔑 Reset Password (Admin only)
  // ===============================
  Future<void> resetPassword(String email, String newPassword) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();
      final hashedPassword = _hashPassword(newPassword);

      await _supabase
          .from('profiles')
          .update({'password': hashedPassword})
          .eq('email', normalizedEmail);

      debugPrint('✅ Password reset for: $normalizedEmail');
    } catch (e) {
      debugPrint('Error resetting password: $e');
      rethrow;
    }
  }

  // ===============================
  // 🆔 Generate UUID (helper)
  // ===============================
  String _generateUUID() {
    // Generate simple UUID v4
    return '${_randomHex(8)}-${_randomHex(4)}-4${_randomHex(3)}-${_randomHex(4)}-${_randomHex(12)}';
  }

  String _randomHex(int length) {
    final random = List.generate(length, (i) => '0123456789abcdef'[DateTime.now().microsecondsSinceEpoch % 16]);
    return random.join();
  }
}