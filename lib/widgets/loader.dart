// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

// class XcelLoader extends ConsumerStatefulWidget {
//   const XcelLoader({
//     super.key,
//     required this.child,
//     required this.isLoading,
//   });
//   final Widget child;
//   final bool isLoading;

//   @override
//   ConsumerState<ConsumerStatefulWidget> createState() => _XcelLoaderState();
// }

// class _XcelLoaderState extends ConsumerState<XcelLoader>
//     with SingleTickerProviderStateMixin {
//   late AnimationController controller;
//   late Animation<double> animation;

//   @override
//   void initState() {
//     super.initState();
//     controller = AnimationController(
//       duration: const Duration(milliseconds: 5000),
//       vsync: this,
//     );
//     animation = CurvedAnimation(parent: controller, curve: Curves.easeIn);
//     controller.repeat();
//   }

//   @override
//   void dispose() {
//     controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return ModalProgressHUD(
//         inAsyncCall: widget.isLoading,
//         opacity: 0.6,
//         progressIndicator: RotationTransition(
//           turns: animation,
//           child: Image.asset(
//             "assets/loading.png",
//             width: 90,
//             height: 90,
//           ),
//         ),
//         child: widget.child);
//   }
// }

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class XcelLoader extends ConsumerStatefulWidget {
  const XcelLoader({
    super.key,
    required this.child,
    required this.isLoading,
  });
  final Widget child;
  final bool isLoading;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _XcelLoaderState();
}

class _XcelLoaderState extends ConsumerState<XcelLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> animation;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      duration: const Duration(milliseconds: 5000),
      vsync: this,
    );
    animation = CurvedAnimation(parent: controller, curve: Curves.easeIn);
    controller.repeat();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.isLoading)
          AbsorbPointer(
            absorbing: true,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.black.withOpacity(0.6),
              child: Center(
                child: RotationTransition(
                  turns: animation,
                  child: Image.asset(
                    "assets/etapp.png",
                    width: 90,
                    height: 90,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}