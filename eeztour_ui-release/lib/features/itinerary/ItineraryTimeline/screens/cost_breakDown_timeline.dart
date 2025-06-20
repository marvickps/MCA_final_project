import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../../../common/config.dart';

class CostBreakdownScreen extends StatefulWidget {
  final int itineraryId;

  const CostBreakdownScreen({
    Key? key,
    required this.itineraryId,
  }) : super(key: key);

  @override
  State<CostBreakdownScreen> createState() => _CostBreakdownScreenState();
}

class _CostBreakdownScreenState extends State<CostBreakdownScreen> {
  bool _showDailyBreakdown = false;
  bool _isLoading = true;
  CostBreakdownData? _costData;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetchCostBreakdown();
  }

  Future<void> _fetchCostBreakdown() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      final response = await http.get(
        Uri.parse('$baseUrl/itinerary/itinerary_cost_breakup/${widget.itineraryId}'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        setState(() {
          _costData = CostBreakdownData.fromJson(jsonData);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load cost breakdown';
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

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Cost Breakdown',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
          ? Center(child: Text(_error))
          : _costData == null
          ? const Center(child: Text('No data available'))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTripSummary(),
            const SizedBox(height: 24),
            _buildDailyBreakdownToggle(),
            if (_showDailyBreakdown) ...[
              const SizedBox(height: 16),
              _buildDailyBreakdown(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTripSummary() {
    final totalCost = _costData!.getTotalCost();
    final totalDays = _costData!.costBreakupByDay.length;
    final placeData = _calculateItemTypeData('place');


    // Calculate aggregated data for hotels and restaurants
    final hotelData = _calculateItemTypeData('hotel');
    final restaurantData = _calculateItemTypeData('restaurant');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red[700]!, Colors.redAccent[400]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Trip Summary',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Days:',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              Text(
                '$totalDays',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Hotels breakdown
          if (hotelData['quantity'] > 0) ...[
            const Text(
              'Hotels:',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Quantity:',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      Text(
                        '${hotelData['quantity']}',
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Average Rate:',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      Text(
                        '₹ ${hotelData['avgRate'].toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Subtotal:',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      Text(
                        '₹ ${hotelData['subtotal'].toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Restaurants breakdown
          if (restaurantData['quantity'] > 0) ...[
            const Text(
              'Restaurants:',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Quantity:',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      Text(
                        '${restaurantData['quantity']}',
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Average Rate:',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      Text(
                        '₹ ${restaurantData['avgRate'].toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Subtotal:',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      Text(
                        '₹ ${restaurantData['subtotal'].toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (placeData['quantity'] > 0) ...[
            const Text(
              'Places:',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Quantity:',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      Text(
                        '${placeData['quantity']}',
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Average Rate:',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      Text(
                        '₹ ${placeData['avgRate'].toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Subtotal:',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      Text(
                        '₹ ${placeData['subtotal'].toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          // Total cost
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.white30, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Cost:',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '₹ ${totalCost.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

        ],
      ),
    );
  }

  Map<String, dynamic> _calculateItemTypeData(String itemType) {
    int totalQuantity = 0;
    double totalSubtotal = 0;
    double totalRateSum = 0;
    int validItemsCount = 0;

    for (var day in _costData!.costBreakupByDay) {
      for (var item in day.costBreakup) {
        if (item.itemType == itemType && item.isComplete) {
          totalQuantity += item.validQuantity;
          totalSubtotal += item.subTotal;
          if (item.avgRate != null) {
            totalRateSum += item.avgRate! * item.validQuantity;
            validItemsCount += item.validQuantity;
          }
        }
      }
    }

    double avgRate = validItemsCount > 0 ? totalRateSum / validItemsCount : 0;

    return {
      'quantity': totalQuantity,
      'avgRate': avgRate,
      'subtotal': totalSubtotal,
    };
  }

  Widget _buildExpenseItem(CostBreakupItem item) {
    final icon = item.itemType == 'hotel' ? Icons.hotel : Icons.restaurant;
    final color = item.itemType == 'hotel' ? Colors.blue : Colors.red;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.itemType.capitalize(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${item.validQuantity} of ${item.totalQuantity} items',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: item.isComplete ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    item.isComplete ? 'Complete' : 'Incomplete',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹ ${item.subTotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (item.avgRate != null)
                Text(
                  'Avg: ₹ ${item.avgRate!.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDailyBreakdownToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Daily Breakdown',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        Transform.scale(
          scale: 0.8,
          child: Switch(
            value: _showDailyBreakdown,
            onChanged: (value) {
              setState(() {
                _showDailyBreakdown = value;
              });
            },
            activeColor: Colors.red[600],
          ),
        )

      ],
    );
  }

  Widget _buildDailyBreakdown() {
    return Column(
      children: _costData!.costBreakupByDay.asMap().entries.map((entry) {
        final index = entry.key;
        final dayData = entry.value;
        return _buildDayBreakdown(index + 1, dayData);
      }).toList(),
    );
  }

  Widget _buildDayBreakdown(int dayNumber, DayCostBreakup dayData) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            title: Text(
              'Day $dayNumber',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: dayData.costBreakup
                      .map((item) => _buildDetailedExpenseItem(item))
                      .toList(),
                ),
              ),
            ],
          ),
        )
    );
  }

  Widget _buildDetailedExpenseItem(CostBreakupItem item) {
    final icon = _getItemIcon(item.itemType);
    final color = _getItemColor(item.itemType);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.itemType.capitalize(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                '₹ ${item.subTotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Quantity:', style: TextStyle(color: Colors.grey)),
              Text('${item.totalQuantity}'),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Valid Quantity:', style: TextStyle(color: Colors.grey)),
              Text('${item.validQuantity}'),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Average Rate:', style: TextStyle(color: Colors.grey)),
              Text(item.avgRate != null ? '₹ ${item.avgRate!.toStringAsFixed(2)}' : 'N/A'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Status:', style: TextStyle(color: Colors.grey)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: item.isComplete ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(4),
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
        ],
      ),
    );
  }
}

// Data Models
class CostBreakdownData {
  final int itineraryId;
  final List<DayCostBreakup> costBreakupByDay;

  CostBreakdownData({
    required this.itineraryId,
    required this.costBreakupByDay,
  });

  factory CostBreakdownData.fromJson(Map<String, dynamic> json) {
    return CostBreakdownData(
      itineraryId: json['itinerary_id'],
      costBreakupByDay: (json['cost_breakup_by_day'] as List)
          .map((dayJson) => DayCostBreakup.fromJson(dayJson))
          .toList(),
    );
  }

  double getTotalCost() {
    return costBreakupByDay.fold(0.0, (total, day) => total + day.getTotalCost());
  }
}

class DayCostBreakup {
  final int dayId;
  final List<CostBreakupItem> costBreakup;

  DayCostBreakup({
    required this.dayId,
    required this.costBreakup,
  });

  factory DayCostBreakup.fromJson(Map<String, dynamic> json) {
    return DayCostBreakup(
      dayId: json['day_id'],
      costBreakup: (json['cost_breakup'] as List)
          .map((itemJson) => CostBreakupItem.fromJson(itemJson))
          .toList(),
    );
  }

  double getTotalCost() {
    return costBreakup.fold(0.0, (total, item) => total + item.subTotal);
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
