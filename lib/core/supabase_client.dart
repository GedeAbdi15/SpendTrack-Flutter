import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static Future<void> init() async {
    await Supabase.initialize(
        url: "https://cxlonpgtoqcpzmzpuccy.supabase.co",
        anonKey:
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN4bG9ucGd0b3FjcHptenB1Y2N5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTY2OTIxMjYsImV4cCI6MjA3MjI2ODEyNn0.vkKrjxWDZN0JH_G8nqASt7-O0GIxyTub29SXrkcF_HY");
  }

  static SupabaseClient get client => Supabase.instance.client;
}
