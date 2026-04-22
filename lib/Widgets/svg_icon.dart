import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Svgicon extends StatelessWidget {
  const Svgicon({
    super.key,
    required this.assetName,
    this.size = 22,
    this.color,
  });

  final String assetName;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      "assets/icons/$assetName.svg",
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(
        color ?? (Theme.of(context).brightness == Brightness.light
            ? Colors.black87
            : Colors.white54),
        BlendMode.srcIn,
      ),
      errorBuilder: (context, error, stackTrace) {
        debugPrintStack();
        debugPrint("svg error: $error");
        return Text("");
      },
    );
  }
}
