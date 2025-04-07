import 'package:flutter/material.dart';
import 'package:simple_icons/simple_icons.dart';
import '../config/theme.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final Color? color;

  const AppLogo({
    super.key,
    this.size = 80,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final logoColor = color ?? AppTheme.secondaryColor;
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
        border: Border.all(color: logoColor, width: 2),
      ),
      child: Center(
        child: Icon(
          Icons.attach_money_rounded,
          size: size * 0.6,
          color: logoColor,
        ),
      ),
    );
  }
} 