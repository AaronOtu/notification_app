import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EtzTest extends StatelessWidget {
  final String text;
  final double? fontSize;
  final FontWeight? fontWeight;
  final Color? color;

  const EtzTest(
      {super.key,
      required this.text,
      this.fontSize,
      this.fontWeight,
      this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.outfit(
          textStyle: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color ?? Colors.black,
      )),
    );
  }
}
