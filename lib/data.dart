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

/// Shared application state.
/// Business-related values are loaded from backend APIs.
class AppState {
  // Selected deity
  static Deity? deity;

  // Sankalp target
  // 0 means target is not selected or loaded yet.
  static int target = 0;
  static int? sankalpTargetId;

  // Sankalp details
  static String forWhom = 'Myself';
  static String name = '';
  static String intention = '';

  // Design details
  static int? design;
  static int? designId;
  static String? designName;
  static String? designPreviewImageUrl;
  static String? designAssetUrl;

  // Total progress
  static int written = 0;

  // Daily progress
  static int? todayGoal;
  static int todayWritten = 0;

  // Streak
  static int streak = 0;

  // Sankalp member
  static int? sankalpMemberId;

  // Created Sankalp
  static int? createdSankalpId;

  // Daily summary API state
  static bool isDailySummaryLoading = false;
  static bool hasDailySummaryLoaded = false;
  static String? dailySummaryError;

  /// Reset daily summary when Sankalp changes.
  static void resetDailySummary() {
    todayGoal = null;
    todayWritten = 0;

    isDailySummaryLoading = false;
    hasDailySummaryLoaded = false;
    dailySummaryError = null;
  }

  /// Reset progress when a new Sankalp is created.
  static void resetSankalpProgress() {
    written = 0;
    streak = 0;

    resetDailySummary();
  }
}
