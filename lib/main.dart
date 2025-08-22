import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tefa_parkir/auth/auth.gate.dart';

void main() async {
  // supabase setup
  await Supabase.initialize(
    url: "https://rfpsfzbmhhxksisxciwx.supabase.co", 
    anonKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJmcHNmemJtaGh4a3Npc3hjaXd4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTUxMzM2MzMsImV4cCI6MjA3MDcwOTYzM30.OdBMWNBjgls2iw08JPqId9osfDTVE0W00H6zGHvOe_U",
  ); 

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key}); 

  @override

  Widget build(BuildContext context){
    return const MaterialApp(
      home: AuthGate(),
    );
  }
}