import 'package:flutter/material.dart';

class Deity {
  final String id;
  final String hi;
  final String en;
  final String symbol;
  final Color c1;
  final Color c2;
  final String? imageUrl;
  final String? pa;

  const Deity(
    this.id,
    this.hi,
    this.en,
    this.symbol,
    this.c1,
    this.c2, {
    this.imageUrl,
    this.pa,
  });
}

const sankalpTargets = <int>[
  1008,
  5000,
  11000,
  21000,
  51000,
  100000,
];

/// App state.
/// Deity is selected dynamically from the API.
class AppState {
  static Deity? deity;

  static int target = 21000;
  static int? sankalpTargetId;

  static String forWhom = 'Myself';
  static String name = '';
  static String intention = '';
  static int design = 1;

  static int written = 0;
  static int todayGoal = 108;
  static int todayWritten = 0;
  static int streak = 0;

  static int? sankalpMemberId;

  static int? designId;
  static String? designName;
  static String? designPreviewImageUrl;
  static String? designAssetUrl;
  static int? createdSankalpId;
}
