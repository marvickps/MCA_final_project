import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../../../common/config.dart';

class DayBreakdownScreen extends StatefulWidget {
  final int dayId;


  const DayBreakdownScreen({
    Key? key,
    required this.dayId,

  }) : super(key: key);

  @override
  State<DayBreakdownScreen> createState() => _DayBreakdownScreenState();
}

class _DayBreakdownScreenState extends State<DayBreakdownScreen> {
  bool _isLoading = true;
  DayBreakdownData? _dayData;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetchDayBreakdown();
  }

  Future<void> _fetchDayBreakdown() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      final response = await http.get(
        Uri.parse('$baseUrl/itinerary/day_cost_breakup/${widget.dayId}'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        setState(() {
          _dayData = DayBreakdownData.fromJson(jsonData);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load day breakdown';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Day Breakdown',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),

      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              _error,
              style: TextStyle(
                color: Colors.red[600],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchDayBreakdown,
              child: const Text('Retry'),
            ),
          ],
        ),
      )
          : _dayData == null
          ? const Center(child: Text('No data available'))
          : RefreshIndicator(
        onRefresh: _fetchDayBreakdown,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDaySummary(),
              const SizedBox(height: 24),
              _buildExpensesList(),

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDaySummary() {
    if (_dayData == null) return const SizedBox.shrink();

    final totalCost = _dayData!.getTotalCost();
    final totalItems = _dayData!.getTotalItems();
    final validItems = _dayData!.getValidItems();
    final completionRate = totalItems > 0 ? (validItems / totalItems * 100) : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          // colors: [Colors.red[800]!, Colors.red[400]!],
          colors: [Colors.green[800]!, Colors.greenAccent[400]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Day Summary',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // Container(
              //   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              //   decoration: BoxDecoration(
              //     color: Colors.white.withOpacity(0.2),
              //     borderRadius: BorderRadius.circular(12),
              //   ),
              //   child: Text(
              //     'ID: ${_dayData!.dayId}',
              //     style: const TextStyle(
              //       color: Colors.white,
              //       fontSize: 12,
              //       fontWeight: FontWeight.w500,
              //     ),
              //   ),
              // ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem('Total Cost', '₹ ${totalCost.toStringAsFixed(2)}'),
              ),
              Expanded(
                child: _buildSummaryItem('Items', '$validItems / $totalItems'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem('Completion', '${completionRate.toStringAsFixed(0)}%'),
              ),
              Expanded(
                child: _buildSummaryItem('Status', _getOverallStatus()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _getOverallStatus() {
    if (_dayData == null) return 'Unknown';

    final hasIncomplete = _dayData!.costBreakup.any((item) => !item.isComplete);
    return hasIncomplete ? 'Incomplete' : 'Complete';
  }

  Widget _buildExpensesList() {
    if (_dayData == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cost Breakdown',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _dayData!.costBreakup.length,
          itemBuilder: (context, index) {
            return _buildExpenseCard(_dayData!.costBreakup[index], index);
          },
        ),
      ],
    );
  }

  Widget _buildExpenseCard(CostBreakupItem item, int index) {
    final icon = _getItemIcon(item.itemType);
    final color = _getItemColor(item.itemType);
    final   completionPercentage = item.totalQuantity > 0
        ? (item.validQuantity / item.totalQuantity * 100)
        : 0.0;

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),


      child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              item.itemType.capitalize(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '₹ ${item.subTotal.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: color
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '${item.validQuantity} of ${item.totalQuantity} items',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: item.isComplete ? Colors.green : Colors.orange,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                item.isComplete ? 'Complete' : 'Incomplete',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildDetailRow('Average Rate', item.avgRate != null ? '₹ ${item.avgRate!.toStringAsFixed(2)}' : 'N/A'),
              _buildDetailRow('Subtotal', '₹ ${item.subTotal.toStringAsFixed(2)}'),
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Cost configuration',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${completionPercentage.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[800],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: completionPercentage / 100,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                  ),
                ],
              ),

            ],
          ),
        ),

    );
  }


  IconData _getItemIcon(String itemType) {
    switch (itemType.toLowerCase()) {
      case 'hotel':
        return Icons.hotel;
      case 'restaurant':
        return Icons.restaurant;
      case 'transport':
        return Icons.directions_car;
      case 'activity':
        return Icons.local_activity;
      default:
        return Icons.place;
    }
  }

  Color _getItemColor(String itemType) {
    switch (itemType.toLowerCase()) {
      case 'hotel':
        return Colors.blue;
      case 'restaurant':
        return Colors.orange;
      case 'transport':
        return Colors.green;
      case 'activity':
        return Colors.purple;
      default:
        return Colors.green;
    }
  }

  void _showExpenseDetails(CostBreakupItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildExpenseDetailsSheet(item),
    );
  }

  Widget _buildExpenseDetailsSheet(CostBreakupItem item) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _getItemColor(item.itemType).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getItemIcon(item.itemType),
                          color: _getItemColor(item.itemType),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${item.itemType.capitalize()} Details',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: item.isComplete ? Colors.green : Colors.orange,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                item.isComplete ? 'Complete' : 'Incomplete',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildDetailRow('Total Quantity', '${item.totalQuantity}'),
                  _buildDetailRow('Valid Quantity', '${item.validQuantity}'),
                  _buildDetailRow('Invalid Quantity', '${item.totalQuantity - item.validQuantity}'),
                  _buildDetailRow('Average Rate', item.avgRate != null ? '₹ ${item.avgRate!.toStringAsFixed(2)}' : 'N/A'),
                  _buildDetailRow('Subtotal', '₹ ${item.subTotal.toStringAsFixed(2)}'),
                  const SizedBox(height: 24),

                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// Data Models
class DayBreakdownData {
  final int dayId;
  final List<CostBreakupItem> costBreakup;

  DayBreakdownData({
    required this.dayId,
    required this.costBreakup,
  });

  factory DayBreakdownData.fromJson(Map<String, dynamic> json) {
    return DayBreakdownData(
      dayId: json['day_id'],
      costBreakup: (json['cost_breakup'] as List)
          .map((itemJson) => CostBreakupItem.fromJson(itemJson))
          .toList(),
    );
  }

  double getTotalCost() {
    return costBreakup.fold(0.0, (total, item) => total + item.subTotal);
  }

  int getTotalItems() {
    return costBreakup.fold(0, (total, item) => total + item.totalQuantity);
  }

  int getValidItems() {
    return costBreakup.fold(0, (total, item) => total + item.validQuantity);
  }

  Map<String, Map<String, dynamic>> getItemTypeStats() {
    Map<String, Map<String, dynamic>> stats = {};

    for (var item in costBreakup) {
      if (!stats.containsKey(item.itemType)) {
        stats[item.itemType] = {
          'total': 0,
          'valid': 0,
          'cost': 0.0,
        };
      }

      stats[item.itemType]!['total'] += item.totalQuantity;
      stats[item.itemType]!['valid'] += item.validQuantity;
      stats[item.itemType]!['cost'] += item.subTotal;
    }

    return stats;
  }
}

class CostBreakupItem {
  final String itemType;
  final int totalQuantity;
  final int validQuantity;
  final double? avgRate;
  final double subTotal;
  final bool isComplete;

  CostBreakupItem({
    required this.itemType,
    required this.totalQuantity,
    required this.validQuantity,
    this.avgRate,
    required this.subTotal,
    required this.isComplete,
  });

  factory CostBreakupItem.fromJson(Map<String, dynamic> json) {
    return CostBreakupItem(
      itemType: json['item_type'],
      totalQuantity: json['total_quantity'],
      validQuantity: json['valid_quantity'],
      avgRate: json['avg_rate']?.toDouble(),
      subTotal: json['sub_total'].toDouble(),
      isComplete: json['is_complete'],
    );
  }
}

// Extension for string capitalization
extension StringCapitalization on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}