// lib/itineraryTimeline/widgets/timeline_day.dart
import 'package:flutter/material.dart';
import '../../../../utils/constants/colors.dart';
import '../controller/itinerary_controller.dart';

class TimelineDay extends StatefulWidget {
  final DayActivity activity;
  final bool isLast;


  const TimelineDay({super.key, required this.activity, this.isLast = false});

  @override
  State<TimelineDay> createState() => _TimelineDayState();
}

class _TimelineDayState extends State<TimelineDay> {
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [_buildDateSection(),
        Expanded(child: _buildActivityCard())],
    );
  }

  Widget _buildDateSection() {
    return SizedBox(
      width: 100,
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.primaryRed,
              borderRadius: BorderRadius.circular(12),

            ),
            child: Text(
              widget.activity.date,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (!widget.isLast)
            Container(
              width: 3,
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.lightGray,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActivityCard() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGray.withOpacity(0.6)),

        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildIconsRow(),
              Text(
                widget.activity.dayOfWeek,
                style: TextStyle(
                  color: AppColors.gray,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTravelInfo(),
              _buildCostChip(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconsRow() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        if (widget.activity.hasBus)
          _buildIconContainer(
            Icons.directions_bus,
            AppColors.itineraryBlue,
          ),
        if (widget.activity.hasHotel)
          _buildIconContainer(
            Icons.hotel,
            AppColors.clientsTeal,
          ),
        if (widget.activity.hasRestaurant)
          _buildIconContainer(
            Icons.restaurant,
            AppColors.primaryRed,
          ),
        if (widget.activity.hasPlace)
          _buildIconContainer(
            Icons.place,
            AppColors.commissionGreen,
          ),
      ],
    );
  }

  Widget _buildIconContainer(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        // boxShadow: [
        //   BoxShadow(
        //     color: color.withOpacity(0.3),
        //     blurRadius: 4,
        //     offset: const Offset(0, 2),
        //   ),
        // ],
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: 20,
      ),
    );
  }

  Widget _buildCostChip() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.primaryRed,
        borderRadius: BorderRadius.circular(8),
        // boxShadow: [
        //   BoxShadow(
        //     color: AppColors.primaryRed.withOpacity(0.3),
        //     blurRadius: 4,
        //     offset: const Offset(0, 2),
        //   ),
        // ],
      ),
      child: Text(
        widget.activity.cost,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildTravelInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.directions_car, color: AppColors.gray, size: 18),
          const SizedBox(width: 8),
          Text(
            '${widget.activity.travelTime} - ${widget.activity.distance}',
            style: TextStyle(
              color: AppColors.gray,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}