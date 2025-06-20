import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../../../../common/config.dart';
import '../../../../common/widgets/continue_button.dart';
import '../controllers/hotel_search_controller.dart';
import '../controllers/date_range_controller.dart';
import '../controllers/location_search.dart';
import '../widgets/locationSearchField.dart';
import '../widgets/hotel_search_field.dart';
import '../../itinerary_Menu/screens/itineraryMenu.dart';

class ItineraryDetailsScreen extends StatefulWidget {
  final String itineraryPlaceID;
  final String itineraryCityName;

  const ItineraryDetailsScreen({
    super.key,
    required this.itineraryPlaceID,
    required this.itineraryCityName,
  });

  @override
  State<ItineraryDetailsScreen> createState() => _ItineraryDetailsScreenState();
}

class _ItineraryDetailsScreenState extends State<ItineraryDetailsScreen> {
  // Text editing controllers
  late TextEditingController _tripToController;
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _startPointController = TextEditingController();
  final TextEditingController _accommodationController =
      TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Pre-fill Trip to with the provided city name, but make it editable
    _tripToController = TextEditingController(text: widget.itineraryCityName);

    // Reset the hotel controller when opening a new screen with a different city
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final hotelController = Provider.of<HotelSearchController>(
        context,
        listen: false,
      );
      if (hotelController.lastSearchCity != widget.itineraryCityName) {
        hotelController.reset();
        _accommodationController.clear();
      }
    });

  }

  @override
  void dispose() {
    _tripToController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _startPointController.dispose();
    _accommodationController.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange(DateRangeController dateRangeController) async {
    final DateTime now = DateTime.now();
    final DateTime lastDate = DateTime(now.year + 1);

    final pickedRange = await showDateRangePicker(
      context: context,
      firstDate: now,
      lastDate: lastDate,
    );

    if (pickedRange != null) {
      dateRangeController.updateDateRange(pickedRange.start, pickedRange.end);
      final dateFormat = DateFormat('yyyy-MM-dd');
      _startDateController.text = dateFormat.format(pickedRange.start);
      _endDateController.text = dateFormat.format(pickedRange.end);
    }
  }

  bool get _isFormValid {
    // Ensure Trip to, dates and accommodation are filled.
    return _tripToController.text.isNotEmpty &&
        _startDateController.text.isNotEmpty &&
        _endDateController.text.isNotEmpty &&
        _accommodationController.text.isNotEmpty &&
        _startPointController.text.isNotEmpty;
  }

  Future<void> _submitItineraryDetails() async {
    if (!_isFormValid) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final hotelController = Provider.of<HotelSearchController>(
      context,
      listen: false,
    );
    final locationController = Provider.of<LocationSearchController>(
      context,
      listen: false,
    );

    try {
      // Prepare data for API
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.loadUser();

      if (userProvider.userId == null) {
        throw Exception('User not authenticated');
      }

      final Map<String, dynamic> itineraryData = {
        "user_id": userProvider.userId!,
        "itineraryName": _tripToController.text,
        "itineraryPlaceID": widget.itineraryPlaceID,
        "startDate": _startDateController.text,
        "endDate": _endDateController.text,
        "startingPoint": locationController.selectedLocationId ?? "",
        "accommodation": hotelController.selectedHotelId ?? "",
      };

      print("$itineraryData AND TYPE: ${userProvider.tokenType} AND TOKEN: ${userProvider.accessToken}");

      final response = await http.post(
        Uri.parse('$baseUrl/itinerary/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': '${userProvider.tokenType} ${userProvider.accessToken}',
        },
        body: jsonEncode(itineraryData),
      );

      print(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final int itineraryId = jsonDecode(response.body);

        // Check if widget is still mounted before using context
        if (!mounted) return;

        // Navigate first, then show success message on the new screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ItineraryMenu(id: itineraryId),
          ),
        ).then((_) {
          // Show success message on the new screen after navigation completes
          if (Navigator.of(context).canPop()) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Itinerary details saved successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        });
      } else {
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _errorMessage =
            'API error: ${errorData['detail'] ?? 'Unknown error'}';
          });
        }
      }
    } catch (e) {
      print('Exception during API call: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Network error: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hotelSearchController = Provider.of<HotelSearchController>(context);
    final dateRangeController = Provider.of<DateRangeController>(context);
    bool _showFullError = false;

    return Scaffold(
      appBar: AppBar(title: const Text('Itinerary Details')),
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16, // Push content above keyboard
            top: 16,
            left: 16,
            right: 16,
          ),
          child: Column(
            children: [
              TextField(
                controller: _tripToController,
                decoration: InputDecoration(
                  labelText: 'Itinerary Name',
                  hintText: 'Enter name for your trip',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Start date
              GestureDetector(
                onTap: () => _pickDateRange(dateRangeController),
                child: AbsorbPointer(
                  child: TextField(
                    controller: _startDateController,
                    decoration: InputDecoration(
                      labelText: 'Start date',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // End date
              GestureDetector(
                onTap: () => _pickDateRange(dateRangeController),
                child: AbsorbPointer(
                  child: TextField(
                    controller: _endDateController,
                    decoration: InputDecoration(
                      labelText: 'End date',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Starting point of Trip
              LocationSearchField(
                controller: _startPointController,
                labelText: 'Starting point of Trip',
                hintText: 'Enter starting location...',
              ),
              const SizedBox(height: 16),

              // Accommodation
              HotelSearchField(
                placeId: widget.itineraryPlaceID,
                cityName: widget.itineraryCityName,
                controller: _accommodationController,
                labelText: 'Accommodation',
                hintText: 'Search Hotels...',
              ),
              const SizedBox(height: 16),

              // Error message (if any)
              // if (_errorMessage != null)
              //   Padding(
              //     padding: const EdgeInsets.only(bottom: 16.0),
              //     child: Text(
              //       _errorMessage!,
              //       style: TextStyle(color: Colors.red.shade700),
              //     ),
              //   ),

              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: StatefulBuilder(
                    builder: (context, setStateInner) {
                      return Container(
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          border: Border.all(color: Colors.red),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Route unavailable. Try adjusting your destinations.',
                                    style: TextStyle(
                                      color: Colors.red.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.info_outline, color: Colors.red.shade700),
                                  onPressed: () {
                                    setStateInner(() {
                                      _showFullError = !_showFullError;
                                    });
                                  },
                                  tooltip: 'Show error details',
                                ),
                              ],
                            ),
                            if (_showFullError)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0, left: 32.0),
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(
                                    color: Colors.red.shade900,
                                    fontSize: 13.0,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

              // Continue Button with loading state
              ContinueButton(
                label: _isLoading ? 'Saving...' : 'Save Itinerary',
                isEnabled: _isFormValid && !_isLoading,
                onPressed: _submitItineraryDetails,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
