class RogueliteLayout {
  // ── Screen Layout Zones (% of available height) ───────────────────────────
  // Total: header + enemies + board + controls + spacer = 100%

  static const double zoneHeaderPercent = 4.0;        // Header height % of screen
  static const double zoneEnemiesPercent = 36.0;     // Enemies field height %
  static const double zoneBoardPercent = 49.0;       // Board container height %
  static const double zoneControlsPercent = 5.0;     // Controls height %
  static const double zoneTabsPercent = 6.0;         // Tab bar height %

  static const double bottomSpacer = 20.0;

  // ── Screen / Board ───────────────────────────────────────────────────────

  /// Total horizontal inset applied before clamping board size.
  static const double boardHPad = 40.0;
  static const double boardMin = 120.0;
  static const double boardMax = 400.0;

  /// Tile gap inside GameBoard — must match GameBoard's internal gap.
  static const double boardCellGap = 8.0;

  // ── Header ───────────────────────────────────────────────────────────────

  static const double headerPadH = 12.0;
  static const double headerPadV = 4.0;

  // stat chip (TALENTS / COINS)
  static const double chipPadH = 8.0;
  static const double chipPadV = 3.0;
  static const double chipRadius = 6.0;
  static const double chipIconGap = 4.0;
  static const double chipIconSize = 12.0;
  static const double chipLabelSize = 8.0;
  static const double chipValueSize = 13.0;

  // timer chip
  static const double timerPadH = 10.0;
  static const double timerPadV = 3.0;
  static const double timerFontSize = 18.0;
  static const double timerRadius = 6.0;
  static const double timerMinWidth = 64.0; // keeps chip stable as digits change

  // ── Enemy Pyramid ─────────────────────────────────────────────────────────

  static const double enemyBossSize = 44.0;
  static const double enemyMinSize = 16.0;
  static const double pyramidRowGap = 0.0;
  // Boss row height (based on boss sprite size).
  static const double pyramidRowHeight =
      enemyBossSize + enemyHpBarGap + enemyHpBarHeight;
  // Normal enemy row height — smaller than boss row.
static const double pyramidMidHPad = 3.0;   // horizontal padding per side, sparse rows
  static const double pyramidFrontHPad = 2.0; // horizontal padding per side, dense rows
  static const double pyramidDenseHPad = 1.0; // horizontal padding per side, very dense rows
  static const double pyramidPadV = 4.0;     // vertical padding inside pyramid container

  // ── Enemy Widget ──────────────────────────────────────────────────────────

  static const double enemyRadius = 6.0;
  static const double enemyBossBoderWidth = 2.0;
  static const double enemyHpBarGap = 1.0;
  static const double enemyHpBarHeight = 3.0;
  static const double enemyTextScale = 0.28; // fontSize = size * scale, clamped
  static const double enemyTextMin = 8.0;
  static const double enemyTextMax = 13.0;

  // ── Board Area ─────────────────────────────────────────────────────────────

  static const double boardAreaPadV = 8.0;   // vertical padding in board container

  // ── Control Bar ────────────────────────────────────────────────────────────

  static const double controlBarPadH = 12.0;
  static const double controlBarPadV = 4.0;
  static const double segmentedButtonFontSize = 9.0;
  static const double segmentedButtonPadH = 2.0;
  static const double filledButtonPadH = 12.0;
  static const double filledButtonPadV = 4.0;
  static const double filledButtonFontSize = 11.0;
}
