import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static bool isPendingSignOut = false;

  // ===============================
  // 🔐 Sign In
  // ===============================
  Future<AuthResponse> signInWithEmailPassword(
      String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user == null) {
        throw Exception('Invalid credentials.');
      }

      // Check if profile exists and is approved
      final profile = await _supabase
          .from('profiles')
          .select('status')
          .eq('email', email)
          .maybeSingle();

      if (profile == null) {
        throw Exception('Profile not found.');
      }

      final status = profile['status'] as String?;
      if (status == 'pending') {
        throw Exception(
            'You are not approved yet. Please contact an admin to approve your account.');
      }

      return response;
    } catch (e) {
      debugPrint('Sign in error: $e');
      rethrow;
    }
  }

  // ===============================
  // 🧾 Sign Up
  // ===============================
  Future<AuthResponse> signUpWithEmailPassword(
      String email, String password) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user != null) {
        await createProfile(user.id, email);
      }

      return response;
    } catch (e) {
      debugPrint('Sign up error: $e');
      rethrow;
    }
  }

  // ===============================
  // 🚪 Sign Out
  // ===============================
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      debugPrint('Sign out error: $e');
    }
  }

  // ===============================
  // 📧 Get current user email
  // ===============================
  String? getCurrentUserEmail() {
    final session = _supabase.auth.currentSession;
    final user = session?.user;
    return user?.email;
  }

  // ===============================
  // 🎭 Get user role
  // ===============================
  Future<String?> getUserRole() async {
    final email = getCurrentUserEmail();
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
  // 🧩 Get user status
  // ===============================
  Future<String?> getUserStatus() async {
    final email = getCurrentUserEmail();
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
  // 🧱 Create new profile
  // ===============================
  Future<void> createProfile(String userId, String email,
      {String role = 'satgas',
      String? full_name,
      String? kelas,
      String? jurusan}) async {
    try {
      await _supabase.from('profiles').upsert({
        'id': userId,
        'email': email,
        'role': role,
        'status': 'pending',
        'full_name': full_name,
        'kelas': kelas,
        'jurusan': jurusan,
      });
    } catch (e) {
      debugPrint('Error creating profile: $e');
      rethrow;
    }
  }

  // ===============================
  // ⏳ Get all pending profiles
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
  // ✅ Approve / Reject profile
  // ===============================
  Future<void> updateProfileStatus(String profileId, String status) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      final updateData = {'status': status};
      if (currentUserId != null) {
        updateData['approved_by'] = currentUserId;
      }

      await _supabase
          .from('profiles')
          .update(updateData)
          .eq('id', profileId);
    } catch (e) {
      debugPrint('Error updating profile status: $e');
      rethrow;
    }
  }

  // ===============================
  // 👥 Get all satgas accounts
  // ===============================
  Future<List<Map<String, dynamic>>> getSatgasAccounts() async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('id, email, full_name, role, kelas, jurusan, status, created_at')
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
  // 🗑️ Delete satgas account
  // ===============================
  Future<void> deleteSatgasAccount(String userId) async {
    try {
      final response = await _supabase.functions.invoke(
        'deleteUser',
        body: {'userId': userId},
      );

      if (response.status != 200) {
        throw Exception('Failed to delete account: ${response.data}');
      }
    } catch (e) {
      debugPrint('Error deleting satgas account: $e');
      rethrow;
    }
  }
}
