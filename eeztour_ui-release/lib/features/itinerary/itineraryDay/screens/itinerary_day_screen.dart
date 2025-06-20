// screens/itinerary_day_screen.dart

import 'package:eeztour/features/itinerary/itineraryDay/screens/AddLocations.dart';
import 'package:eeztour/features/itinerary/itineraryDay/widgets/Dragable_content.dart';
import 'package:eeztour/features/itinerary/itineraryDay/widgets/day_summary.dart';
import 'package:flutter/material.dart';
import '../../ItineraryTimeline/controller/itinerary_controller.dart';
import '../controllers/itinerary_day_controller.dart';
import '../widgets/ItineraryStopsWidget.dart';

class itineraryDayScreen extends StatefulWidget {
  final int dayId;
  final String locationDay;

  const itineraryDayScreen({Key? key, required this.dayId, required this.locationDay}) : super(key: key);

  @override
  State<itineraryDayScreen> createState() => _itineraryDayScreenState();
}

class _itineraryDayScreenState extends State<itineraryDayScreen> with SingleTickerProviderStateMixin {
  late itineraryDayController _controller;
  bool _isEditing = false;
  bool _isSaving = false;
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _fabAnimation;

  // Keep a reference to the reorderable widget
  final GlobalKey<ItineraryReorderableStopsWidgetState> _reorderableKey = GlobalKey();

  // Store ScaffoldMessenger reference safely
  ScaffoldMessengerState? _scaffoldMessenger;

  @override
  void initState() {
    super.initState();
    _controller = itineraryDayController();

    // Animation setup
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fabAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Store the ScaffoldMessenger reference safely
    try {
      _scaffoldMessenger = ScaffoldMessenger.of(context);
    } catch (e) {
      _scaffoldMessenger = null;
    }
    _loaditineraryDay();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scaffoldMessenger = null;
    super.dispose();
  }

  void _navigateToNextPage(String ezType, String googlePlaceType) {
    setState(() => _isExpanded = false);
    _animationController.reverse();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddLocationsScreen(
          dayId: widget.dayId,
          location: widget.locationDay,
          ezType: ezType,
          googlePlaceType: googlePlaceType,
        ),
      ),
    );
  }

  Future<void> _loaditineraryDay() async {
    if (!mounted) return;

    await _controller.fetchitineraryDay(widget.dayId);
    if (mounted) {
      setState(() {});
    }
  }

  void _toggleEditMode() {
    if (!mounted) return;
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  void _showSnackBar(String message, {Color? backgroundColor}) {
    // Use the stored reference first, fall back to mounted check
    if (_scaffoldMessenger != null) {
      try {
        _scaffoldMessenger!.showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: backgroundColor ?? Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } catch (e) {
        // If the stored reference fails, try the mounted approach
        if (mounted) {
          try {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: backgroundColor ?? Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          } catch (e) {
            // Silently fail if both approaches don't work
            print('Failed to show snackbar: $e');
          }
        }
      }
    } else if (mounted) {
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: backgroundColor ?? Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } catch (e) {
        print('Failed to show snackbar: $e');
      }
    }
  }

  Future<void> _saveChanges() async {
    if (!mounted) return;

    final reorderableWidget = _reorderableKey.currentState;
    if (reorderableWidget == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      reorderableWidget.updateItineraryStops();
      final success = await _controller.updateitineraryStopsOrder(widget.dayId);

      if (!mounted) return;

      if (success) {
        await _loaditineraryDay();
        _showSnackBar('Itinerary stops updated successfully');
      } else {
        _showSnackBar('Failed to update itinerary stops', backgroundColor: Colors.red);
      }
    } catch (error) {
      if (mounted) {
        _showSnackBar('Error updating stops: $error', backgroundColor: Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isEditing = false;
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(_controller.itineraryDay?.dayTitle ?? 'Loading...'),
        centerTitle: true,
        actions: [
          if (!_isEditing)
            IconButton(icon: const Icon(Icons.edit), onPressed: _toggleEditMode)
          else if (_isSaving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.redAccent),
                  ),
                ),
              ),
            )
          else
            IconButton(icon: const Icon(Icons.check), onPressed: _saveChanges),
        ],
      ),
      body: _controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loaditineraryDay,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            children: [
              if (_controller.itineraryDay != null)
                ItineraryDaySummaryCard(
                  dayId: widget.dayId,
                  totalCost: _controller.itineraryDay!.dayCost,
                  totalDistance: _controller.itineraryDay!.dayDistanceKm,
                  id: _controller.itineraryDay!.itineraryId,
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _controller.itineraryDay!.date,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 20,
                                color: Color.fromARGB(255, 104, 104, 104),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Departure Time:',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Color.fromARGB(255, 104, 104, 104),
                                ),
                              ),
                              SizedBox(width: 6),
                            ],
                          ),
                          GestureDetector(
                            onTap: () {
                              // Add departure time edit functionality
                            },
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.edit,
                                  size: 18,
                                  color: Colors.blueAccent,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _controller.itineraryDay!.departureTime,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.hourglass_bottom,
                                size: 20,
                                color: Color.fromARGB(255, 104, 104, 104),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Estimated Travel Time:',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Color.fromARGB(255, 104, 104, 104),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _controller.itineraryDay!.estimatedTotalDuration,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.hourglass_bottom,
                                size: 20,
                                color: Color.fromARGB(255, 104, 104, 104),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Total Trip Time:',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Color.fromARGB(255, 104, 104, 104),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _controller.itineraryDay!.totalStayDuration.toString(),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _isEditing
                  ? ItineraryReorderableStopsWidget(
                key: _reorderableKey,
                itineraryDay: _controller.itineraryDay!,
              )
                  : ItineraryStopsWidget(
                itineraryDay: _controller.itineraryDay!,
                onRefresh: _loaditineraryDay,
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_isExpanded) ...[
            _buildSubButton(
              icon: Icons.hotel,
              label: 'Hotel',
              onPressed: () => _navigateToNextPage('hotel', 'lodging'),
            ),
            _buildSubButton(
              icon: Icons.restaurant,
              label: 'Restaurant',
              onPressed: () => _navigateToNextPage('restaurant', 'cafe, restaurant'),
            ),
            _buildSubButton(
              icon: Icons.place,
              label: 'Place',
              onPressed: () => _navigateToNextPage('place', ''),
            ),
            const SizedBox(height: 16),
          ],
          FloatingActionButton(
            backgroundColor: Colors.redAccent,
            onPressed: () {
              setState(() => _isExpanded = !_isExpanded);
              _isExpanded ? _animationController.forward() : _animationController.reverse();
            },
            child: Icon(
              _isExpanded ? Icons.close : Icons.add,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: ScaleTransition(
        scale: _fabAnimation,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(28),
                onTap: onPressed,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    children: [
                      Icon(icon, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}