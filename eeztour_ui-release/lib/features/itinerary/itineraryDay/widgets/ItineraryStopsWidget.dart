import 'package:eeztour/common/config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../models/itinerary_day.dart';
import 'edit_widget.dart';

class ItineraryStopsWidget extends StatefulWidget {
  final ItineraryDay itineraryDay;
  final VoidCallback onRefresh;

  const ItineraryStopsWidget({
    super.key,
    required this.itineraryDay,
    required this.onRefresh,
  });

  @override
  State<ItineraryStopsWidget> createState() => _ItineraryStopsWidgetState();
}

class _ItineraryStopsWidgetState extends State<ItineraryStopsWidget> {
  @override
  Widget build(BuildContext context) {
    final sortedStops = _getSortedStops();

    return FutureBuilder<List<Widget>>(
      future: _buildStopList(context, sortedStops),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (snapshot.hasData) {
          return ListView(
            shrinkWrap: true,
            physics: const ClampingScrollPhysics(),
            children: snapshot.data!,
          );
        } else {
          return const Center(child: Text('No data available'));
        }
      },
    );
  }

  List<itineraryStop> _getSortedStops() {
    final stops = List<itineraryStop>.from(widget.itineraryDay.stops);
    stops.sort((a, b) => a.order.compareTo(b.order));
    return stops;
  }

  Future<List<Widget>> _buildStopList(BuildContext context, List<itineraryStop> stops) async {
    List<Widget> widgets = [];
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.loadUser();

    for (int i = 0; i < stops.length; i++) {
      Widget stopCard;
      if (i == 0) {
        // Don't wrap the first item with GestureDetector
        stopCard = _buildStopCardFirst(stops[i]);
      } else {
        // Check if userProvider.roleId is 2, if so don't add GestureDetector
        if (userProvider.roleId == 2) {
          stopCard = _buildStopCard(stops[i]);
        } else {
          // Wrap with GestureDetector for other roles
          stopCard = GestureDetector(
            onTap: () async {
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (context) {
                  return StopDetailsModal(
                    stopID: stops[i].stopId,
                    cost: stops[i].cost,
                    stayDuration: stops[i].stayDuration,
                    description: stops[i].desc,
                    name: stops[i].name,
                    onDelete: () async {
                      final url = Uri.parse('$baseUrl/itinerary/delete_item/${stops[i].stopId}');
                      try {
                        final response = await http.delete(url);
                        if (response.statusCode == 200) {
                          print('deleted');
                        }
                      } catch (e) {
                        print('Error occurred while deleting item: $e');
                      }
                    },
                    onUpdate: widget.onRefresh,
                  );
                },
              );
            },
            child: _buildStopCard(stops[i]),
          );
        }
      }
      widgets.add(stopCard);
      if (i < stops.length - 1) {
        widgets.add(_buildDurationRow(stops[i + 1].fromPreviousDuration));
      }
    }
    return widgets;
  }

  Color _getColorForStopType(String type) {
    final stopType = type.toLowerCase();

    if (stopType.contains('hotel')) {
      return Colors.blue;
    } else if (stopType.contains('restaurant')) {
      return Colors.orange;
    } else if (stopType.contains('starting_point')) {
      return Colors.redAccent;
    } else if (stopType.contains('place')) {
      return Colors.green;
    } else {
      return Colors.grey;
    }
  }

  String _convertTo12HourFormat(String time24) {
    try {
      final timeParts = time24.split(':');
      if (timeParts.length < 2) return time24;
      int hour = int.parse(timeParts[0]);
      final minute = timeParts[1];
      final period = hour >= 12 ? 'PM' : 'AM';
      hour = hour % 12;
      if (hour == 0) hour = 12;
      return '$hour:$minute $period';
    } catch (e) {
      return time24;
    }
  }

  IconData _getIconForType(String ezType) {
    switch (ezType.toLowerCase()) {
      case 'restaurant':
        return Icons.restaurant;
      case 'hotel':
        return Icons.hotel;
      default:
        return Icons.place;
    }
  }

  Widget _buildStopCard(itineraryStop stop) {
    final stopColor = _getColorForStopType(stop.type);
    final backgroundColor = stopColor;
    String formattedTime = _convertTo12HourFormat(stop.eta);
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  _getIconForType(stop.type),
                  size: 36,
                  color: Colors.white,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    stop.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        color: stopColor,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        ' $formattedTime',
                        style: TextStyle(
                          color: stopColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.currency_rupee,
                        color: stopColor,
                        size: 18,
                      ),
                      const SizedBox(width: 1),
                      Text(
                        '${stop.cost?.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: stopColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationRow(String? duration) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 0),
      child: Row(
        children: [
          Column(
            children: [
              Container(
                width: 2,
                height: 14,
                color: Colors.grey[300],
              ),
              Icon(Icons.directions_car, size: 20, color: Colors.grey[400]),
              Container(
                width: 2,
                height: 14,
                color: Colors.grey[300],
              ),
            ],
          ),
          const SizedBox(width: 12),
          Text(
            duration ?? '',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStopCardFirst(itineraryStop stop) {
    final stopColor = Colors.black54;
    final backgroundColor = stopColor;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(0),
      ),
      color: backgroundColor,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: SvgPicture.asset(
          'assets/icons/enter.svg',
          width: 32,
          height: 32,
          color: Colors.white,
        ),
        title: Text(
          stop.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        trailing: Text(
          stop.eta,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}