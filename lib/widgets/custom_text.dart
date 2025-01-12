import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EtzText extends StatelessWidget {
  final String text;
  final double? fontSize;
  final FontWeight? fontWeight;
  final Color? color;
  final TextOverflow? overflow;
  final bool? softWrap; 
  final int? maxLines;

  const EtzText({
    super.key,
    required this.text,
    this.fontSize,
    this.fontWeight,
    this.color,
    this.overflow = TextOverflow.clip, 
    this.softWrap = true, 
    this.maxLines, 
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
      overflow: overflow, 
      softWrap: softWrap, 
      maxLines: maxLines, 
    );
  }
}
