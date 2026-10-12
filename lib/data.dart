import 'package:flutter/material.dart';

class Deity {
  final String id;
  final String hi; // Hindi name
  final String en; // English name
  final String symbol;
  final Color c1;
  final Color c2;
  const Deity(this.id, this.hi, this.en, this.symbol, this.c1, this.c2);
}

const deities = <Deity>[
  Deity('ram', 'राम', 'Ram', '🏹', Color(0xFFFFE2A8), Color(0xFFE8A53C)),
  Deity('radha', 'राधा', 'Radha', '🌸', Color(0xFFFFD9E4), Color(0xFFE67FA0)),
  Deity('krishna', 'कृष्ण', 'Krishna', '🦚', Color(0xFFCFE8FF), Color(0xFF4F8FD6)),
  Deity('shiv', 'शिव', 'Shiv', '🔱', Color(0xFFD9DEF2), Color(0xFF5B6AA8)),
  Deity('hanuman', 'हनुमान', 'Hanuman', '🚩', Color(0xFFFFD0A8), Color(0xFFE0642A)),
  Deity('durga', 'दुर्गा', 'Durga', '🌺', Color(0xFFFFCDC8), Color(0xFFCC3B3B)),
  Deity('ganesh', 'गणेश', 'Ganesh', '🐘', Color(0xFFFFE0B8), Color(0xFFE69A3A)),
  Deity('lakshmi', 'लक्ष्मी', 'Lakshmi', '🪷', Color(0xFFFFD8E6), Color(0xFFD9708F)),
  Deity('waheguru', 'वाहेगुरु', 'Waheguru', '☬', Color(0xFFFFE8A0), Color(0xFFD9A400)),
];

const sankalpTargets = <int>[1008, 5000, 11000, 21000, 51000, 100000];

/// Lightweight in-memory state for the design phase.
/// Replace with Provider/Riverpod + API sync in the MVP phase.
class AppState {
  static Deity deity = deities[0];
  static int target = 21000;
  static String forWhom = 'Myself';
  static String name = 'Madhvi';
  static String intention = 'For peace and spiritual discipline.';
  static int design = 1; // 0 simple, 1 traditional, 2 premium
  static int written = 8558;
  static int todayGoal = 108;
  static int todayWritten = 27;
  static int streak = 7;
}
