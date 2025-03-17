import 'package:flutter/material.dart';
import 'package:flutter_svg_provider/flutter_svg_provider.dart';
import 'package:notification_app/widgets/custom_text.dart';

// ignore: camel_case_types
class showDialogs extends StatelessWidget {
  final String? title;
  final String? image;
  final bool isDelete;
  final String? hintText;
  final VoidCallback onPressed;
  final TextInputType? keyboardType;
  final TextEditingController? controller;

  showDialogs(
      {super.key,
      this.title,
      this.image,
      required this.isDelete,
      required this.onPressed,
      this.hintText,
      this.controller,
      this.keyboardType});

  Widget _buildImage(String? image) {
    if (image == null) return SizedBox.shrink();
    if (image.endsWith('.svg')) {
      return Image(image: Svg(image), height: 30, width: 30);
    } else {
      return Image(image: AssetImage(image), height: 30, width: 30);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
        backgroundColor: Colors.white,
        title: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildImage(image),
            const SizedBox(height: 10),
            EtzText(text: title!),
          ],
        ),
        content: isDelete
            ? const EtzText(text: 'Are you sure you want to delete?')
            : TextField(
                controller: controller!,
                keyboardType: keyboardType,
                decoration: InputDecoration(
                    hintText: hintText,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide:
                          BorderSide(color: Color(0xFFF4F6F9), width: 0.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide:
                          BorderSide(color: Colors.grey.shade300, width: 0.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide:
                          BorderSide(color: Colors.grey.shade500, width: 1.0),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide:
                          BorderSide(color: Color(0xFFF4F6F9), width: 0.5),
                    )),
              ),
        actions: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            SizedBox(
              height: 40,
              width: 100,
              child: ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDelete ? Colors.red : Color(0xFFD9D9D9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: isDelete
                    ? const EtzText(text: 'Yes', color: Colors.white)
                    : const EtzText(text: 'Add'),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 40,
              width: 100,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: Color(0xFFF4F6F9), width: 0.5)),
                ),
                child: isDelete
                    ? const EtzText(text: 'No')
                    : const EtzText(text: 'Cancel'),
              ),
            ),
          ])
        ]);
  }
}
