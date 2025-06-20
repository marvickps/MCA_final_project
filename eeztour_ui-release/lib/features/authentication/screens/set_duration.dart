import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../../common/config.dart';
import '../../../common/user_session.dart';

class SetDurationScreen extends StatefulWidget {
  const SetDurationScreen({Key? key}) : super(key: key);

  @override
  State<SetDurationScreen> createState() => _SetDurationScreenState();
}

class _SetDurationScreenState extends State<SetDurationScreen> {
  UserSession? userSession;
  bool isLoading = true;
  bool isEditing = false;
  bool isSaving = false;

  // Default timing data
  Map<String, dynamic>? timingData;

  // Controllers for editing
  final TextEditingController dayStartTimeController = TextEditingController();

  // Slider values (in seconds)
  double placeDurationValue = 3600;
  double hotelDaytimeDurationValue = 7200;
  double activityDurationValue = 3600;
  double restaurantDurationValue = 3600;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    dayStartTimeController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    try {
      userSession = await UserSession.getInstance();
      await _fetchDefaultTiming();
    } catch (e) {
      print('Error initializing data: $e');
      _showErrorSnackBar('Failed to load user session');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchDefaultTiming() async {
    if (userSession?.userId == null) return;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/get_default_timing/${userSession!.userId}'),
        headers: {
          'Authorization': 'Bearer ${userSession!.accessToken}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          timingData = data;
          _populateControllers();
        });
      } else {
        _showErrorSnackBar('Failed to fetch default timing settings');
      }
    } catch (e) {
      print('Error fetching default timing: $e');
      _showErrorSnackBar('Network error occurred');
    }
  }

  void _populateControllers() {
    if (timingData != null) {
      dayStartTimeController.text = timingData!['day_start_time'] ?? '09:00:00';
      placeDurationValue = (timingData!['place_duration'] ?? 3600).toDouble();
      hotelDaytimeDurationValue = (timingData!['hotel_daytime_duration'] ?? 7200).toDouble();
      activityDurationValue = (timingData!['activity_duration'] ?? 3600).toDouble();
      restaurantDurationValue = (timingData!['restaurant_duration'] ?? 3600).toDouble();
    }
  }

  String _formatDuration(double seconds) {
    int hours = (seconds / 3600).floor();
    int minutes = ((seconds % 3600) / 60).floor();
    return '$hours h ${minutes.toString().padLeft(2, '0')} m';
  }

  Future<void> _updateDefaultTiming() async {
    if (timingData == null) return;

    setState(() {
      isSaving = true;
    });

    try {
      final body = {
        "day_start_time": dayStartTimeController.text,
        "place_duration": placeDurationValue.round(),
        "hotel_daytime_duration": hotelDaytimeDurationValue.round(),
        "activity_duration": activityDurationValue.round(),
        "restaurant_duration": restaurantDurationValue.round(),
      };
      final response = await http.put(
        Uri.parse('$baseUrl/users/update_default_timing/${timingData!['setting_id']}'),
        headers: {
          'Authorization': 'Bearer ${userSession!.accessToken}',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        _showSuccessSnackBar('Default timing updated successfully');
        await _fetchDefaultTiming(); // Refresh data
        setState(() {
          isEditing = false;
        });
      } else {
        _showErrorSnackBar('Failed to update default timing');
      }
    } catch (e) {
      print('Error updating default timing: $e');
      _showErrorSnackBar('Network error occurred');
    } finally {
      setState(() {
        isSaving = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _parseTimeString(dayStartTimeController.text),
    );
    if (picked != null) {
      setState(() {
        dayStartTimeController.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}:00';
      });
    }
  }

  TimeOfDay _parseTimeString(String timeString) {
    final parts = timeString.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 9,
      minute: int.tryParse(parts[1]) ?? 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Default Set Time'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!isEditing && timingData != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  isEditing = true;
                });
              },
              tooltip: 'Edit Settings',
            ),
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  isEditing = false;
                  _populateControllers(); // Reset to original values
                });
              },
              tooltip: 'Cancel',
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : timingData == null
          ? const Center(
        child: Text(
          'No default timing settings found',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red.shade700, Colors.redAccent.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.timer_outlined,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Default Duration Settings',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isEditing ? 'Edit your default timing preferences' : 'View your current default timing settings',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Settings List Container
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Day Start Time
                  _buildSettingItem(
                    title: 'Day Start Time',
                    icon: Icons.schedule,
                    color: Colors.orange,
                    isFirst: true,
                    child: isEditing
                        ? InkWell(
                      onTap: () => _selectTime(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              dayStartTimeController.text,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.access_time, size: 20),
                          ],
                        ),
                      ),
                    )
                        : Text(
                      dayStartTimeController.text,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  // Place Duration
                  _buildSliderItem(
                    title: 'Place Duration',
                    icon: Icons.place,
                    color: Colors.green,
                    value: placeDurationValue,
                    onChanged: isEditing ? (value) => setState(() => placeDurationValue = value) : null,
                  ),

                  // Hotel Daytime Duration
                  _buildSliderItem(
                    title: 'Hotel Daytime Duration',
                    icon: Icons.hotel,
                    color: Colors.blue,
                    value: hotelDaytimeDurationValue,
                    onChanged: isEditing ? (value) => setState(() => hotelDaytimeDurationValue = value) : null,
                  ),

                  // Activity Duration
                  _buildSliderItem(
                    title: 'Activity Duration',
                    icon: Icons.local_activity,
                    color: Colors.purple,
                    value: activityDurationValue,
                    onChanged: isEditing ? (value) => setState(() => activityDurationValue = value) : null,
                  ),

                  // Restaurant Duration
                  _buildSliderItem(
                    title: 'Restaurant Duration',
                    icon: Icons.restaurant,
                    color: Colors.orange,
                    value: restaurantDurationValue,
                    onChanged: isEditing ? (value) => setState(() => restaurantDurationValue = value) : null,
                    isLast: true,
                  ),
                ],
              ),
            ),

            if (isEditing) ...[
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: isSaving ? null : _updateDefaultTiming,
                  icon: isSaving
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : const Icon(Icons.save),
                  label: Text(isSaving ? 'Saving...' : 'Save Changes'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: isLast ? null : Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildSliderItem({
    required String title,
    required IconData icon,
    required Color color,
    required double value,
    required ValueChanged<double>? onChanged,
    bool isLast = false,
  }) {
    int hours = (value / 3600).floor();
    int minutes = ((value % 3600) / 60).floor();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: isLast ? null : Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$hours h ${minutes.toString().padLeft(2, '0')} m',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          if (isEditing) ...[
            const SizedBox(height: 16),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: color,
                inactiveTrackColor: Colors.grey.shade300,
                thumbColor: color,
                overlayColor: color.withAlpha(32),
                valueIndicatorColor: color,
              ),
              child: Slider(
                value: value,
                onChanged: onChanged,
                min: 1800, // 30 minutes minimum
                max: 43200, // 12 hours maximum
                divisions: 100,
                label: '${hours}h ${minutes.toString().padLeft(2, '0')}m',
              ),
            ),
          ],
        ],
      ),
    );
  }
}