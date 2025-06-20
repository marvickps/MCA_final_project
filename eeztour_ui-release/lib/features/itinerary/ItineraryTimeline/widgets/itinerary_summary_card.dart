// lib/itineraryTimeline/widgets/itinerary_summary_card.dart
import 'package:flutter/material.dart';
import '../../../../utils/constants/colors.dart';
import '../../itineraryMap/screens/itineraryMap_whole.dart';
import '../screens/cost_breakDown_timeline.dart';

class ItinerarySummaryCard extends StatelessWidget {
  final String totalCost;
  final String totalDistance;
  final int id;

  const ItinerarySummaryCard({
    super.key,
    required this.totalCost,
    required this.totalDistance, required this.id,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: AppColors.lightGray,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryRow(
                  'Total Cost: ₹',
                  totalCost,
                  Icons.receipt_outlined,
                  onIconTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CostBreakdownScreen(itineraryId: id),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                _buildSummaryRow('Total Distance: ', totalDistance, null),
              ],

            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ItineraryMapScreen(id: id, day: "all",),
                    ),
                );
              },
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.commissionGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.map_outlined,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
      String label,
      dynamic value,
      IconData? icon, {
        VoidCallback? onIconTap,
        Color iconColor = AppColors.gray,
        double iconSize = 18,
      }) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        if (icon != null)
          GestureDetector(
            onTap: onIconTap,
            child: Icon(
              icon,
              color: iconColor,
              size: iconSize,
            ),
          ),
      ],
    );
  }
}
