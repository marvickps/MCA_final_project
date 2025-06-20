// lib/screens/home/widgets/dashboard_grid.dart

import 'package:flutter/material.dart';
import '../../models/dashboard_item.dart';
import '../widgets/dashboard_item_tile.dart';

class DashboardGrid extends StatelessWidget {
  final List<DashboardItem> items;
  final double screenWidth;

  const DashboardGrid({
    Key? key,
    required this.items,
    required this.screenWidth,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final int crossAxisCount = 3;

    return Container(
      width: double.infinity, // Use full width
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: 1.0,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          return DashboardItemTile(item: items[index]);
        },
      ),
    );
  }
}
