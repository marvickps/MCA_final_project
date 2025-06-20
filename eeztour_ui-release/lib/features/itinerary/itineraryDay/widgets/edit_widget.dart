import 'dart:convert';

import 'package:eeztour/common/functions.dart';
import 'package:eeztour/utils/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../../common/config.dart';

class StopDetailsModal extends StatelessWidget {
  final int stopID;
  final int? cost;
  final int stayDuration;
  final String description;
  final Future<void> Function() onDelete;
  final String name;
  final VoidCallback onUpdate;

  const StopDetailsModal({
    super.key,
    required this.cost,
    required this.stayDuration,
    required this.description,
    required this.onDelete,
    required this.name, required this.stopID, required this.onUpdate,
  });


  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.location_on,
                      color: Colors.redAccent,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),

                  Expanded(
                    child: Text(
                      name,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 30, thickness: 1.5),
              _buildDetailItem(context, 'Cost', '${cost?.toStringAsFixed(2)}',
                  Icons.currency_rupee),
              _buildDetailItem(
                  context, 'Stay Duration', formatDuration(stayDuration), Icons.timer),
              _buildDetailItem(
                  context, 'Description', description, Icons.description),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await onDelete();
                    onUpdate();
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.delete_outline, size: 24),
                  label: const Text(
                    'Delete Stop',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(
      BuildContext context,
      String title,
      String value,
      IconData icon,
      ) {

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[700])),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              if (title == 'Cost') {
                showEditCostModal(context, value, (newValue) async {
                  final url = Uri.parse('$baseUrl/itinerary/update_item_cost');
                  final response = await http.put(
                    url,
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode({
                      'itinerary_item_id': stopID,
                      'cost': newValue,
                    }),
                  );
                  if (response.statusCode == 200 || response.statusCode == 201) {
                    Navigator.pop(context);
                    Navigator.pop(context);
                    onUpdate();
                  } else {
                    print('Failed to edit item: ${response.body}');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to edit item')),
                    );
                  }
                }
                );
              } else if (title == 'Stay Duration') {
                final seconds = int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

                showEditDurationModal(context, parseDuration(value), (newValue) async{
                  final url = Uri.parse('$baseUrl/itinerary/update_item_duration');
                  final response = await http.put(
                    url,
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode({
                      'itinerary_item_id': stopID,
                      'stay_duration': newValue,
                    }),
                  );
                  if (response.statusCode == 200 || response.statusCode == 201) {
                    Navigator.pop(context);
                    Navigator.pop(context);
                    onUpdate();
                  } else {
                    print('Failed to edit item: ${response.body}');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to edit item')),
                    );
                  }
                });
              } else if (title == 'Description') {
                showEditDescriptionModal(context, value, (newValue) async{
                  final url = Uri.parse('$baseUrl/itinerary/update_item_description');
                  final response = await http.put(
                    url,
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode({
                      'itinerary_item_id': stopID,
                      'description': newValue,
                    }),
                  );
                  if (response.statusCode == 200 || response.statusCode == 201) {
                    Navigator.pop(context);
                    onUpdate();
                  } else {
                    print('Failed to edit item: ${response.body}');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to edit item')),
                    );
                  }
                });
              }
            },
            icon: Icon(Icons.edit, size: 24, color: AppColors.gray.withOpacity(0.5)),
            padding: EdgeInsets.only(bottom: 50),
            constraints: const BoxConstraints(),
            splashRadius: 24,
          ),
        ],
      ),
    );
  }

}

void showEditCostModal(BuildContext context, String currentValue, Function(String) onSave) {
  final controller = TextEditingController(text: currentValue);
  bool isLoading = false;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (context) {
      return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 20, left: 20, right: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Edit Cost', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Cost',
                      border: OutlineInputBorder(),
                      prefixText: '₹',
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () {
                      setState(() {
                        isLoading = true;
                      });
                      onSave(controller.text); // onSave already has the API call and will trigger onUpdate after success
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.commissionGreen,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 26,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: isLoading
                        ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 3,
                      ),
                    )
                        : const Text(
                      'Save the cost',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          }
      );
    },
  );
}

void showEditDurationModal(BuildContext context, int currentSeconds, Function(int) onSave) {
  double sliderValue = currentSeconds.toDouble().clamp(0, 43200);
  bool isLoading = false;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          final duration = Duration(seconds: sliderValue.toInt());
          final hours = duration.inHours;
          final minutes = duration.inMinutes.remainder(60);

          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Edit Stay Duration', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Text('$hours hours ${minutes.toString().padLeft(2, '0')} min', style: const TextStyle(fontSize: 18)),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: Colors.redAccent,
                    inactiveTrackColor: Colors.grey,
                    thumbColor: Colors.red,
                    overlayColor: Colors.redAccent.withAlpha(32),
                    valueIndicatorColor: Colors.redAccent,
                  ),
                  child: Slider(
                    value: sliderValue,
                    onChanged: (value) => setState(() => sliderValue = value),
                    min: 0,
                    max: 43200,
                    divisions: 1000,
                    label: '$hours h ${minutes.toString().padLeft(2, '0')} m',
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () {
                    setState(() {
                      isLoading = true;
                    });
                    onSave(sliderValue.toInt());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.commissionGreen,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: 26,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: isLoading
                      ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 3,
                    ),
                  )
                      : const Text(
                    'Save your stay duration',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

void showEditDescriptionModal(BuildContext context, String currentValue, Function(String) onSave) {
  final controller = TextEditingController(text: currentValue);
  bool isLoading = false;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (context) {
      return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 20, left: 20, right: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Edit Description', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    maxLines: 5,
                    minLines: 3,
                    keyboardType: TextInputType.multiline,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () {
                      setState(() {
                        isLoading = true;
                      });
                      onSave(controller.text);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.commissionGreen,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 26,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: isLoading
                        ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 3,
                      ),
                    )
                        : const Text(
                      'Save your description',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          }
      );
    },
  );
}