import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tefa_parkir/auth/auth.gate.dart';

void main() async {
  // supabase setup
  await Supabase.initialize(
    url: "https://cmtyyhsiuwmakwpvkdln.supabase.co", 
    anonKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNtdHl5aHNpdXdtYWt3cHZrZGxuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQyODc1ODMsImV4cCI6MjA2OTg2MzU4M30.E5g1HC9WKqRKtqt1N7YmoFmT-S5Ncfzmnb8GbBz1EkA",
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