import 'package:flutter/material.dart';
import 'package:sudokulegend/Models/badge_service.dart';
import 'package:sudokulegend/Widgets/helper.dart';

final 

class AllBadges extends StatelessWidget {
   const AllBadges({super.key});

  @override
  Widget build(BuildContext context) {
     final badgeService = BadgeService();
     final allBadgesMap = badgeService.getAllBadges();
     final allBadges = allBadgesMap.values;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Performance Badges', style: TextStyle(color: Colors.black87)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Scrollbar(
        thumbVisibility: false,
        interactive: true,
        trackVisibility: false,
        thickness: 10,
        radius: Radius.circular(8),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.85,
                children: allBadges.map((e) => buildBadgeItem(e.name, e.description, e.unlocked),).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }


}