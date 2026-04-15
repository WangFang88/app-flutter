import 'package:flutter/material.dart';

const _purple = Color(0xFF6366F1);
const _purpleVariant = Color(0xFF8B5CF6);

final appTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(seedColor: _purple),
  fontFamily: 'sans-serif',
);

const gradientPurple = LinearGradient(
  colors: [_purple, _purpleVariant],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);
