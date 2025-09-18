import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Sign in with email and password
  Future<AuthResponse> signInWithEmailPassword(
    String email, String password) async {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Check profile status
        final profileResponse = await _supabase
            .from('profiles')
            .select('status')
            .eq('email', email)
            .single();

        final status = profileResponse['status'] as String?;
        if (status == 'pending') {
          // Sign out user immediately
          await _supabase.auth.signOut();
          throw Exception('You are not approved yet, contact admin balbalbalbalba');
        }
      }

      return response;
    }

  // Sign up with email and password
  Future<AuthResponse> signUpWithEmailPassword(
    String email, String password) async {
    return await _supabase.auth.signUp(
      email: email,
      password: password,
    );
  }

  // Sign out
  Future<void> signOut() async{
    await _supabase.auth.signOut();
  }

  // Get user email
  String? getCurrentUserEmail() {
    final session = _supabase.auth.currentSession;
    final user = session?.user;
    return user?.email;
  }

  // Get user role
  Future<String?> getUserRole() async {
    final email = getCurrentUserEmail();
    if (email == null) return null;

    try {
      final response = await _supabase
          .from('profiles')
          .select('role')
          .eq('email', email)
          .single();
      return response['role'] as String?;
    } catch (e) {
      debugPrint('Error fetching user role: $e');
      return null;
    }
  }

  // Get user status
  Future<String?> getUserStatus() async {
    final email = getCurrentUserEmail();
    if (email == null) return null;

    try {
      final response = await _supabase
          .from('profiles')
          .select('status')
          .eq('email', email)
          .single();
      return response['status'] as String?;
    } catch (e) {
      debugPrint('Error fetching user status: $e');
      return null;
    }
  }

  // Create profile with pending status
  Future<void> createProfile(String userId, String email, {String role = 'satgas'}) async {
    try {
      await _supabase.from('profiles').upsert({
        'id': userId,
        'email': email,
        'role': role,
        'status': 'pending',
      });
    } catch (e) {
      debugPrint('Error creating profile: $e');
      rethrow;
    }
  }

  // Get all pending profiles for admin approval
  Future<List<Map<String, dynamic>>> getPendingProfiles() async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('id, email, full_name, role, created_at')
          .eq('status', 'pending')
          .order('created_at', ascending: false);
      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error fetching pending profiles: $e');
      return [];
    }
  }

  // Approve or reject a profile
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
}
