// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_monopoly/providers/game_state.dart';
import 'package:flutter_monopoly/screens/start_screen.dart';
import 'package:google_fonts/google_fonts.dart'; // Google Fonts paketini import et
import 'package:provider/provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => GameState(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Temel temayı oluşturup üzerine Google Fonts'u uyguluyoruz
    final textTheme = Theme.of(context).textTheme;

    return MaterialApp(
      title: 'Duopoly',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF1a237e),
        scaffoldBackgroundColor: const Color(0xFF0d1117),
        // YENİ: Tüm metin stillerini Lato fontu ile güncelliyoruz
        textTheme: GoogleFonts.latoTextTheme(textTheme).copyWith(
          displayLarge: GoogleFonts.cinzel(textStyle: textTheme.displayLarge, color: Colors.white, fontWeight: FontWeight.bold),
          titleLarge: GoogleFonts.lato(textStyle: textTheme.titleLarge, color: Colors.white70, fontWeight: FontWeight.w600),
          bodyMedium: GoogleFonts.lato(textStyle: textTheme.bodyMedium, color: Colors.white, fontSize: 14),
          labelLarge: GoogleFonts.lato(textStyle: textTheme.labelLarge, color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF303f9f),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            textStyle: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      home: const StartScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
