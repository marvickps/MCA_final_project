import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class GraphDataScreen extends StatelessWidget {
  final dynamic rawJson;

  const GraphDataScreen({Key? key, required this.rawJson}) : super(key: key);

  /// If the JSON is a Map with specific keys, create a unified list.
  List<dynamic> _prepareData(dynamic decodedJson) {
    if (decodedJson is Map<String, dynamic>) {
      // Check for keys "top_3_selling_events" and "total_other_events"
      if (decodedJson.containsKey("top_3_selling_events") &&
          decodedJson.containsKey("total_other_events")) {
        List<dynamic> items =
            List<dynamic>.from(decodedJson["top_3_selling_events"]);
        // Append an extra item for "Other Events" using total_other_events
        items.add({
          "total_bookings": decodedJson["total_other_events"],
        });
        return items;
      }
    }
    // Otherwise, try extracting the first List found in the JSON.
    return _extractDataList(decodedJson);
  }

  /// Extracts the first list found in the JSON.
  List<dynamic> _extractDataList(dynamic decodedJson) {
    if (decodedJson is List) {
      return decodedJson;
    }
    if (decodedJson is Map<String, dynamic>) {
      for (final key in decodedJson.keys) {
        if (decodedJson[key] is List) {
          return List<dynamic>.from(decodedJson[key]);
        }
      }
    }
    return [];
  }

  /// Extracts a numeric value from the map.
  /// It checks for "total_bookings" first, then "count", and then any numeric field.
  int _extractNumericValue(Map<String, dynamic> item) {
    if (item.containsKey("total_bookings")) {
      final raw = item["total_bookings"];
      if (raw is int) return raw;
      if (raw is String) return int.tryParse(raw) ?? 0;
    }
    if (item.containsKey("count")) {
      final raw = item["count"];
      if (raw is int) return raw;
      if (raw is String) return int.tryParse(raw) ?? 0;
    }
    for (final value in item.values) {
      if (value is int) return value;
      if (value is String) {
        final parsed = int.tryParse(value);
        if (parsed != null) return parsed;
      }
    }
    return 0;
  }

  /// Builds pie chart sections using an index-based label.
  List<PieChartSectionData> _buildPieChartSections(List<dynamic> data) {
    final colors = [
      Colors.deepOrange,
      Colors.blueAccent,
      Colors.amber,
      Colors.greenAccent,
      Colors.purpleAccent,
      Colors.cyan,
      Colors.pinkAccent,
      Colors.teal,
      Colors.lime,
      Colors.indigo,
    ];

    return data.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value as Map<String, dynamic>;
      final value = _extractNumericValue(item);
      // Use an index-based label, e.g. "Item 1", "Item 2", etc.
      final label = "Item ${index + 1}";
      return PieChartSectionData(
        color: colors[index % colors.length],
        value: value.toDouble(),
        title: label,
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.8), width: 2),
      );
    }).toList();
  }

  /// Builds a legend using an index-based label.
  Widget _buildLegend(List<dynamic> data) {
    final colors = [
      Colors.deepOrange,
      Colors.blueAccent,
      Colors.amber,
      Colors.greenAccent,
      Colors.purpleAccent,
      Colors.cyan,
      Colors.pinkAccent,
      Colors.teal,
      Colors.lime,
      Colors.indigo,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: data.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value as Map<String, dynamic>;
        final value = _extractNumericValue(item);
        String displayValue;
        if (value >= 100000) {
          displayValue = "${(value / 100000).toStringAsFixed(1)}L";
        } else if (value >= 1000) {
          displayValue = "${(value / 1000).round()}K";
        } else {
          displayValue = value.toString();
        }
        // Use index-based label.
        final label = "Item ${index + 1}";
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 14,
                height: 14,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors[index % colors.length],
                ),
              ),
              Text(
                "$label: ",
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              Text(
                displayValue,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    String prettyJson;
    dynamic decodedJson;
    List<dynamic> items = [];

    try {
      decodedJson = rawJson is String ? json.decode(rawJson) : rawJson;
      prettyJson = const JsonEncoder.withIndent('  ').convert(decodedJson);
      items = _prepareData(decodedJson);
    } catch (e) {
      prettyJson = rawJson.toString();
    }

    final totalValue = items.fold<int>(
      0,
      (sum, item) =>
          sum + _extractNumericValue(item as Map<String, dynamic>),
    );

    return Scaffold(
      appBar: AppBar(title: const Text("Analytics Overview")),
      body: items.isEmpty
          ? const Center(child: Text("No data found"))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const Text(
                    "Analytics Chart",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 240,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        PieChart(
                          PieChartData(
                            sectionsSpace: 3,
                            centerSpaceRadius: 70,
                            sections: _buildPieChartSections(items),
                            startDegreeOffset: -90,
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              totalValue.toString(),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              "Total",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  _buildLegend(items),
                  const Divider(height: 32),
                  Text(
                    "Total: ${totalValue.toString()}",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Raw JSON Data:",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    prettyJson,
                    style: const TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
