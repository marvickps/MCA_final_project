import 'package:flutter/material.dart';
import '../../itineraryDay/screens/itinerary_day_screen.dart';
import '../widgets/itinerary_summary_card.dart';
import '../widgets/timeline_day.dart';
import '../controller/itinerary_controller.dart';

class ItineraryTimelineScreen extends StatefulWidget {
  final ItineraryController controller;
  final int id;

  const ItineraryTimelineScreen({
    super.key,
    required this.controller,
    required this.id,
  });

  @override
  State<ItineraryTimelineScreen> createState() =>
      _ItineraryTimelineScreenState();
}

class _ItineraryTimelineScreenState extends State<ItineraryTimelineScreen> {
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      await widget.controller.fetchItineraryData(widget.id);
      if (mounted) {
        setState(() {
          _isLoading = widget.controller.isLoading;
          _error = widget.controller.error;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load data: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.controller.itineraryName),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error.isNotEmpty
            ? Center(child: Text('Error: $_error'))
            : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    return FutureBuilder<List<DayActivity>>(
      future: widget.controller.getActivities(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No activities found'));
        }

        final activities = snapshot.data!;

        return Column(
          children: [
            ItinerarySummaryCard(
              totalCost: widget.controller.formatedCost.toString(),
              totalDistance: widget.controller.formatedDistance,
              id: widget.id,
            ),
            Expanded(
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: activities.length,
                itemBuilder: (context, index) {
                  final activity = activities[index];
                  return GestureDetector(
                    onTap: () async {
                      // Navigate to itinerary day screen and wait for it to pop
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              itineraryDayScreen(
                                dayId: activity.dayId,
                                locationDay: activity.address,
                              ),
                        ),
                      );

                      // Refresh data when returning from day screen
                      _loadData();
                    },
                    child: TimelineDay(
                      activity: activity,
                      isLast: index == activities.length - 1,
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}