import 'package:flutter/material.dart';

const int defaultGridSize = 4;
const int winTile = 2048;
const int undoStackMax = 10;
const List<int> timePressureDurations = [10, 20, 40, 60];

const Map<int, Color> tileColors = {
  0: Color(0xFFCDC1B4),
  2: Color(0xFFEEE4DA),
  4: Color(0xFFEDE0C8),
  8: Color(0xFFF2B179),
  16: Color(0xFFF59563),
  32: Color(0xFFF67C5F),
  64: Color(0xFFF65E3B),
  128: Color(0xFFEDCF72),
  256: Color(0xFFEDCC61),
  512: Color(0xFFEDC850),
  1024: Color(0xFFEDC53F),
  2048: Color(0xFFEDC22E),
};

const Color tileColorHigh = Color(0xFF3C3A32);
const Color boardColor = Color(0xFFBBADA0);
const Color appBackground = Color(0xFFFAF8EF);

Color tileColor(int value) => tileColors[value] ?? tileColorHigh;

Color tileForeground(int value) =>
    value <= 4 ? const Color(0xFF776E65) : const Color(0xFFF9F6F2);
