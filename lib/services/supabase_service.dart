import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/day_record.dart';

/// Singleton wrapper autour du client Supabase
class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  SupabaseClient get client => Supabase.instance.client;
  User? get currentUser => client.auth.currentUser;
  String? get userId => currentUser?.id;
  bool get isLoggedIn => currentUser != null;

  // ── Auth ───────────────────────────────────────────────────────
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String username,
    required String fullName,
  }) =>
      client.auth.signUp(
        email: email,
        password: password,
        data: {'username': username, 'full_name': fullName},
      );

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) =>
      client.auth.signInWithPassword(email: email, password: password);

  Future<void> signOut() => client.auth.signOut();

  Stream<AuthState> get authStream => client.auth.onAuthStateChange;

  // ── Day Records ────────────────────────────────────────────────
  Future<void> upsertRecord(DayRecord record) async {
    if (userId == null) return;
    await client.from('day_records').upsert({
      'user_id':  userId,
      'date_key': record.dateKey,
      'entries':  record.entries.map((e) => e.toJson()).toList(),
    }, onConflict: 'user_id,date_key');
  }

  Future<List<DayRecord>> fetchMyRecords() async {
    if (userId == null) return [];
    final data = await client
        .from('day_records')
        .select()
        .eq('user_id', userId!)
        .order('date_key');
    return (data as List).map((j) => DayRecord.fromSupabase(j)).toList();
  }

  Future<List<DayRecord>> fetchFriendRecords(String friendId) async {
    final data = await client
        .from('day_records')
        .select()
        .eq('user_id', friendId)
        .order('date_key');
    return (data as List).map((j) => DayRecord.fromSupabase(j)).toList();
  }

  // ── Profiles ──────────────────────────────────────────────────
  Future<Map<String, dynamic>?> fetchProfile(String uid) async {
    final data = await client
        .from('profiles')
        .select()
        .eq('id', uid)
        .maybeSingle();
    return data;
  }

  Future<List<Map<String, dynamic>>> searchProfiles(String query) async {
    final data = await client
        .from('profiles')
        .select()
        .ilike('username', '%$query%')
        .neq('id', userId ?? '')
        .limit(20);
    return List<Map<String, dynamic>>.from(data as List);
  }

  // ── Friendships ────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> fetchFriendships() async {
    if (userId == null) return [];
    final data = await client
        .from('friendships')
        .select('*, requester:requester_id(id,username,full_name), addressee:addressee_id(id,username,full_name)')
        .or('requester_id.eq.$userId,addressee_id.eq.$userId');
    return List<Map<String, dynamic>>.from(data as List);
  }

  Future<void> sendFriendRequest(String addresseeId) async {
    await client.from('friendships').insert({
      'requester_id': userId,
      'addressee_id': addresseeId,
    });
  }

  Future<void> acceptFriendRequest(String friendshipId) async {
    await client
        .from('friendships')
        .update({'status': 'accepted'})
        .eq('id', friendshipId);
  }

  Future<void> rejectFriendRequest(String friendshipId) async {
    await client
        .from('friendships')
        .update({'status': 'rejected'})
        .eq('id', friendshipId);
  }

  Future<void> removeFriend(String friendshipId) async {
    await client.from('friendships').delete().eq('id', friendshipId);
  }
}
