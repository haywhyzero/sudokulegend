import 'package:flutter/material.dart';

class MenuButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final bool isColor;
  final VoidCallback? onTap;

  const MenuButton({
    super.key,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.isColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 70,
        width: 300,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isColor ? Color(0xFF53698A) : Colors.black),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isColor ? Colors.white : Colors.black), textAlign: TextAlign.center,),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(fontSize: 10, color: isColor ? Color.fromARGB(124, 255, 255, 255) : Color(0xFF3d3d3d) )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
