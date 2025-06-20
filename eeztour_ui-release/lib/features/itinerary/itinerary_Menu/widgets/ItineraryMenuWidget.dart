import 'package:flutter/material.dart';
import '../models/ItineraryModel.dart';
import '../../ItineraryTimeline/screens/ItineraryTImeline.dart';
import '../../ItineraryTimeline/controller/itinerary_controller.dart';

class ItineraryHeader extends StatelessWidget {
  final ItineraryModel itinerary;

  const ItineraryHeader({Key? key, required this.itinerary}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => ItineraryTimelineScreen(
                  controller: ItineraryController(
                    itineraryName: itinerary.itineraryName,
                  ),
                  id: itinerary.itineraryId,
                ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Calendar Icon
            Image.asset(
              'assets/images/calendar_icon.png',
              width: 80,
              height: 140,
            ),
            const SizedBox(width: 20),
            // Itinerary text info
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Itinerary',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${itinerary.startDate} - ${itinerary.endDate}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class MenuItemWidget extends StatelessWidget {
  final MenuItemModel menuItem;

  const MenuItemWidget({Key? key, required this.menuItem}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.pushNamed(context, menuItem.route);
      },
      child: Container(
        width: MediaQuery.of(context).size.width * 0.3,
        height: MediaQuery.of(context).size.width * 0.3,
        decoration: BoxDecoration(
          color: const Color(0xFF05103A),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getIconData(menuItem.iconPath),
              color: Colors.white,
              size: 30,
            ),
            const SizedBox(height: 8),
            Text(
              menuItem.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconData(String iconPath) {
    // Map your icon paths to Flutter icons
    switch (iconPath) {
      case 'map':
        return Icons.map_outlined;
      case 'places':
        return Icons.place_outlined;
      case 'hotels':
        return Icons.hotel_outlined;
      case 'rental':
        return Icons.car_rental;
      case 'activities':
        return Icons.interests_outlined;
      case 'about':
        return Icons.article_outlined;
      case 'cost':
        return Icons.receipt_long_outlined;
      default:
        return Icons.circle;
    }
  }
}

class ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const ActionButton({
    Key? key,
    required this.label,
    required this.color,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.45,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
