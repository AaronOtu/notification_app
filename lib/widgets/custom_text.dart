import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EtzText extends StatelessWidget {
  final String text;
  final double? fontSize;
  final FontWeight? fontWeight;
  final Color? color;
  final TextOverflow? overflow; // Added overflow property
  final bool? softWrap; // Added softWrap property
  final int? maxLines; // Added maxLines property

  const EtzText({
    super.key,
    required this.text,
    this.fontSize,
    this.fontWeight,
    this.color,
    this.overflow = TextOverflow.clip, // Default overflow behavior
    this.softWrap = true, // Default softWrap behavior
    this.maxLines, // Optional max lines
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.outfit(
        textStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color ?? Colors.black,
        ),
      ),
      overflow: overflow, // Apply overflow behavior
      softWrap: softWrap, // Enable/disable softWrap
      maxLines: maxLines, // Limit lines if set
    );
  }
}
