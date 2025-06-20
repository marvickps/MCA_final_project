import 'package:flutter/material.dart';
import '../models/itinerary_day.dart';
import '../controllers/itinerary_day_controller.dart';
import 'dart:convert';

class ItineraryReorderableStopsWidget extends StatefulWidget {
  final ItineraryDay itineraryDay;

  const ItineraryReorderableStopsWidget({
    Key? key,
    required this.itineraryDay,
  }) : super(key: key);

  @override
  State<ItineraryReorderableStopsWidget> createState() => ItineraryReorderableStopsWidgetState();
}

class ItineraryReorderableStopsWidgetState extends State<ItineraryReorderableStopsWidget> {
  late List<itineraryStop> _stops;

  @override
  void initState() {
    super.initState();
    _stops = _getSortedStops();
  }

  List<itineraryStop> _getSortedStops() {
    final stops = List<itineraryStop>.from(widget.itineraryDay.stops);
    stops.sort((a, b) => a.order.compareTo(b.order));
    return stops;
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

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      // Handle the reordering logic
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }

      final item = _stops.removeAt(oldIndex);
      _stops.insert(newIndex, item);

      // Update the order values
      for (int i = 0; i < _stops.length; i++) {
        _stops[i].order = i + 1;
      }
    });
  }

  String _generateOrderJson() {
    final Map<String, dynamic> orderData = {
      "itinerary_day_id": widget.itineraryDay.itineraryId,
      "stops": _stops.map((stop) => {
        "stop_id": stop.stopId,
        "order": stop.order
      }).toList()
    };

    return jsonEncode(orderData);
  }

  @override
  Widget build(BuildContext context) {
    // Filter out starting points for the reorderable list
    final reorderableStops = _stops.where((stop) {
      final isStartingPoint = stop.type.toLowerCase().contains('starting_point');
      return !isStartingPoint;
    }).toList();

    return ReorderableListView(
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      buildDefaultDragHandles: false,
      onReorder: (oldIndex, newIndex) {
        // Map indices back to the original _stops list
        final actualOldIndex = _stops.indexOf(reorderableStops[oldIndex]);
        final actualNewIndex = newIndex >= reorderableStops.length
            ? _stops.indexOf(reorderableStops[reorderableStops.length - 1]) + 1
            : _stops.indexOf(reorderableStops[newIndex]);

        _onReorder(actualOldIndex, actualNewIndex);
      },
      children: _buildStopList(reorderableStops),
    );
  }

  List<Widget> _buildStopList(List<itineraryStop> stopsToShow) {
    return List.generate(stopsToShow.length, (index) {
      final stop = stopsToShow[index];
      final stopColor = _getColorForStopType(stop.type);

      return Card(
        key: ValueKey(stop.stopId),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: stopColor,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Icon(
              _getIconForType(stop.type),
              size: 32,
              color: Colors.white,
            ),
            title: Text(
              stop.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            trailing: ReorderableDragStartListener(
              index: index,
              child: const Icon(
                Icons.drag_handle,
                color: Colors.white,
              ),
            ),
          ),
        ),
      );
    });
  }

  String getUpdatedOrderJson() {
    return _generateOrderJson();
  }

  void updateItineraryStops() {
    widget.itineraryDay.stops = _stops;
  }
}