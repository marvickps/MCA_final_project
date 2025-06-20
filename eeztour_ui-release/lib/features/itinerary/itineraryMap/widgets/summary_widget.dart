import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/route_controller.dart';

class TripSummaryWidget extends StatelessWidget {
  const TripSummaryWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ItineraryRouteController>(
      builder: (context, controller, child) {
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.days.isEmpty) {
          return const Center(child: Text('No itinerary data available'));
        }

        // Calculate total stats across all days
        double totalDistance = 0;
        double totalDuration = 0;
        int totalPlaces = 0;

        for (var day in controller.days) {
          totalPlaces += day.places.length;

          if (controller.dayRoutes.containsKey(day.dayId)) {
            for (var route in controller.dayRoutes[day.dayId]!) {
              totalDistance += route.distance;
              totalDuration += route.duration;
            }
          }
        }

        return SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Trip title
                const Text(
                  'Trip Summary',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${controller.days.first.date} - ${controller.days.last.date}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const Divider(height: 24),

                // Stats row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatColumn(
                      '${controller.days.length}',
                      'Days',
                      Icons.calendar_today,
                      Colors.blue,
                    ),
                    _buildStatColumn(
                      '$totalPlaces',
                      'Places',
                      Icons.place,
                      Colors.red,
                    ),
                    _buildStatColumn(
                      (totalDistance / 1000).toStringAsFixed(1),
                      'Kilometers',
                      Icons.directions_car,
                      Colors.green,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Travel time card
                Card(
                  elevation: 2,
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 32,
                          color: Colors.orange[700],
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Travel Time',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDuration(totalDuration),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                                color: Colors.orange[700],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Day by day breakdown
                const Text(
                  'Day by Day Breakdown',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: controller.days.length,
                  itemBuilder: (context, index) {
                    final day = controller.days[index];
                    double dayDistance = 0;
                    double dayDuration = 0;

                    if (controller.dayRoutes.containsKey(day.dayId)) {
                      for (var route in controller.dayRoutes[day.dayId]!) {
                        dayDistance += route.distance;
                        dayDuration += route.duration;
                      }
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      elevation: 1,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: day.routeColor,
                          child: Text(
                            day.dayId,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          'Day ${day.dayId} - ${day.date}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${day.places.length} places • ${(dayDistance / 1000).toStringAsFixed(1)} km • ${_formatDuration(dayDuration, shortFormat: true)}',
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatColumn(String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 28,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  String _formatDuration(double seconds, {bool shortFormat = false}) {
    final hours = (seconds / 3600).floor();
    final minutes = ((seconds % 3600) / 60).floor();

    if (shortFormat) {
      return hours > 0 ? '$hours h $minutes min' : '$minutes min';
    } else {
      return hours > 0
          ? '$hours hours $minutes minutes'
          : '$minutes minutes';
    }
  }
}
