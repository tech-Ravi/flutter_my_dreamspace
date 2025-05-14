import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/dream.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  late final SupabaseClient _client;

  Future<void> initialize() async {
    await dotenv.load(fileName: ".env");
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );
    _client = Supabase.instance.client;
  }

  // Authentication Methods
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
      data: data,
      emailRedirectTo: null, // Disable email confirmation
    );
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }
// Sign in as Guest
  Future<AuthResponse> signInAnonymously() async {
   
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final email = 'temp.$timestamp@mydreamspace.app';
    final password = 'Temp${timestamp}123!';

    final signUpResponse = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'is_guest': true, 'created_at': DateTime.now().toIso8601String()},
    );
    if (signUpResponse.user == null) {
      throw Exception('Failed to create guest account');
    }

    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

//   Future<AuthResponse> signInAnonymously() async {
   
//     final timestamp = DateTime.now().millisecondsSinceEpoch;
//     final email = generateRandomEmail();
//     final password = 'guest@123';

//     final signUpResponse = await _client.auth.signUp(
//       email: email,
//       password: password,
//       data: {'is_guest': true, 'created_at': DateTime.now().toIso8601String()},
//     );
//     return await _client.auth.signInWithPassword(
//       email: email,
//       password: password,
//     );
//   }

//   String generateRandomEmail() {
//   const _chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
//   final random = Random();
//   final prefix = List.generate(8, (index) => _chars[random.nextInt(_chars.length)]).join();
//   return '$prefix@mydreamspace.com';
// }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  User? get currentUser => _client.auth.currentUser;

  // Dream CRUD operations
  Future<List<Dream>> getDreams({int? limit, int? offset}) async {
    try {
      final userId = currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _client
          .from('dreams')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .range(offset ?? 0, (offset ?? 0) + (limit ?? 1000) - 1);

      return (response as List).map((json) => Dream.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get dreams: $e');
    }
  }

//Create dream
  Future<Dream> createDream(Dream dream) async {
    final response =
        await _client.from('dreams').insert(dream.toJson()).select();
    return Dream.fromJson(response.first);
  }

//Edit Dream card
  Future<Dream> updateDream(Dream dream) async {
    final response =
        await _client
            .from('dreams')
            .update(dream.toJson())
            .eq('id', dream.id)
            .select();
    return Dream.fromJson(response.first);
  }

//delete dream
  Future<void> deleteDream(String id) async {
    await _client.from('dreams').delete().eq('id', id);
  }

//Fetch specific dream by Id
  Future<Dream> getDreamById(String id) async {
    try {
      final response =
          await _client.from('dreams').select().eq('id', id).single();
      return Dream.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get dream: $e');
    }
  }

  // get all dream data via mood
  Future<Map<DreamMood, int>> getMoodStatistics() async {
    final userId = currentUser?.id;
    if (userId == null) return {for (var mood in DreamMood.values) mood: 0};
    final response = await _client
        .from('dreams')
        .select('mood')
        .eq('user_id', userId);
    final Map<DreamMood, int> statistics = {};
    for (var mood in DreamMood.values) {
      statistics[mood] = 0;
    }
    for (var item in response) {
      final mood = DreamMood.values.firstWhere(
        (e) => e.toString().split('.').last == item['mood'],
      );
      statistics[mood] = (statistics[mood] ?? 0) + 1;
    }
    return statistics;
  }
}
