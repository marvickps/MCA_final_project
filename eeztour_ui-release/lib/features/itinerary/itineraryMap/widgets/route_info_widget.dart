import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/route_controller.dart';

class ItineraryInfoWidget extends StatelessWidget {
  const ItineraryInfoWidget({Key? key}) : super(key: key);

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

        return DefaultTabController(
          length: controller.days.length,
          child: Column(
            children: [
              TabBar(
                isScrollable: true,
                labelColor: Theme.of(context).primaryColor,
                unselectedLabelColor: Colors.grey,
                tabs: controller.days.map((day) {
                  return Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: day.routeColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('Day ${day.dayId} - ${day.date}'),
                      ],
                    ),
                  );
                }).toList(),
              ),
              Expanded(
                child: TabBarView(
                  children: controller.days.map((day) {
                    final sortedPlaces = day.sortedPlaces;
                    
                    // Calculate total distance and duration for this day
                    double totalDistance = 0;
                    double totalDuration = 0;
                    
                    if (controller.dayRoutes.containsKey(day.dayId)) {
                      for (var route in controller.dayRoutes[day.dayId]!) {
                        totalDistance += route.distance;
                        totalDuration += route.duration;
                      }
                    }
                    
                    return Column(
                      children: [
                        // Day summary
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              if (totalDistance > 0)
                                Text(
                                  'Total Distance: ${(totalDistance / 1000).toStringAsFixed(2)} km',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              if (totalDuration > 0)
                                Text(
                                  'Estimated Travel Time: ${(totalDuration / 60).toStringAsFixed(0)} min',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                            ],
                          ),
                        ),
                        // Places list
                        Expanded(
                          child: ListView.builder(
                            itemCount: sortedPlaces.length,
                            itemBuilder: (context, index) {
                              final place = sortedPlaces[index];
                              
                              // Define icon based on place type
                              IconData iconData;
                              switch (place.placeType) {
                                case 'hotel':
                                  iconData = Icons.hotel;
                                  break;
                                case 'restaurant':
                                  iconData = Icons.restaurant;
                                  break;
                                default:
                                  iconData = Icons.place;
                              }
                              
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: day.routeColor,
                                    child: Text(
                                      place.order,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(place.name),
                                  subtitle: Text(place.address),
                                  trailing: Icon(iconData),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}