import 'package:eeztour/common/config.dart';
import 'package:eeztour/utils/constants/colors.dart';
import 'package:flutter/material.dart';



import 'package:intl/intl.dart'; // For date formatting
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'dart:convert';

import '../../itinerary_Menu/screens/itineraryMenu.dart';
import '../controllers/share_code.dart';

class Itinerary {
  final int itineraryId;
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final String locationAddress;
  final DateTime createdAt;

  Itinerary({
    required this.itineraryId,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.locationAddress,
    required this.createdAt,
  });

  factory Itinerary.fromJson(Map<String, dynamic> json) {
    return Itinerary(
      itineraryId: json['itinerary_id'],
      title: json['title'],
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      locationAddress: json['location_id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  String getStatus() {
    final today = DateTime.now();
    if (endDate.isBefore(today)) {
      return 'past';
    } else if (startDate.difference(today).inDays <= 10) {
      return 'upcoming';
    } else {
      return 'future';
    }
  }
}

class ItineraryService {
  // Make a real API call to fetch itineraries
  Future<List<Itinerary>> getAllItineraries(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/itinerary/get_all_itinerary/$userId'),
        headers: {'accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        return jsonData.map((json) => Itinerary.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load itineraries: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching itineraries: $e');
    }
  }
}

class ItineraryListPage extends StatefulWidget {
  const ItineraryListPage({Key? key}) : super(key: key);

  @override
  _ItineraryListPageState createState() => _ItineraryListPageState();
}

class _ItineraryListPageState extends State<ItineraryListPage> {
  final ItineraryService _itineraryService = ItineraryService();
  late Future<List<Itinerary>> _itinerariesFuture;
  late int userId;

  String _currentFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadData();
  }
  Future<void> _loadData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.loadUser(); // Ensure fresh data

    final userId = userProvider.userId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    _itinerariesFuture = _itineraryService.getAllItineraries(userId);
  }
  List<Itinerary> _filterItineraries(List<Itinerary> itineraries, String filter) {
    switch (filter) {
      case 'Upcoming':
        return itineraries.where((i) => i.getStatus() == 'upcoming').toList();
      case 'Past':
        return itineraries.where((i) => i.getStatus() == 'past').toList();
      // case 'Shared with me':
      // // This would require additional data - for now just return empty list
      //   return [];
      default:
        return itineraries;
    }
  }

  int _countItineraries(List<Itinerary> itineraries, String status) {
    return itineraries.where((i) => i.getStatus() == status).length;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
        builder: (context, userProvider, _) {
          if (userProvider.userId == null) {
            return _buildAuthError();
          }
          return Scaffold(
            backgroundColor: Colors.grey[50],
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black87),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              title: const Text(
                "My Itineraries",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              backgroundColor: Colors.white,
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.search, color: Colors.black87),
                  onPressed: () {

                  },
                ),
                IconButton(
                  icon: const Icon(Icons.filter_list, color: Colors.black87),
                  onPressed: () {
                    // Implement filter functionality
                  },
                ),
              ],
            ),
            body: FutureBuilder<List<Itinerary>>(
              future: _itinerariesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF4285F4)),
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Color(
                            0xFFEF5350), size: 60),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load itineraries',
                          style: TextStyle(fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${snapshot.error}',
                          style: TextStyle(color: Colors.grey[700]),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _itinerariesFuture =
                                  _itineraryService.getAllItineraries(userId);
                            });
                          },
                          child: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF4285F4),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_today, color: Colors.grey[400],
                            size: 60),
                        const SizedBox(height: 16),
                        Text(
                          'No itineraries found',
                          style: TextStyle(
                              fontSize: 18, color: Colors.grey[700]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create a new trip to get started',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  );
                }

                final allItineraries = snapshot.data!
                  ..sort((a, b) => b.startDate.compareTo(a.startDate));
                final filteredItineraries = _filterItineraries(
                    allItineraries, _currentFilter);

                final upcomingCount = _countItineraries(
                    allItineraries, 'upcoming');
                final pastCount = _countItineraries(allItineraries, 'past');

                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 26),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.shade200,
                              width: 1),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,

                        children: [
                          _buildStat('Total Itineraries', allItineraries.length
                              .toString()),
                          _buildStat('Upcoming Trips', upcomingCount.toString(),
                              color: AppColors.primaryRed),
                          _buildStat('Past Trips', pastCount.toString(),
                              color: Colors.grey),
                        ],
                      ),
                    ),

                    // Filter buttons
                    Container(

                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 26),
                        child: SingleChildScrollView(
                          child: Row(
                            children: [
                              _buildFilterChip('All'),
                              const SizedBox(width: 8),
                              _buildFilterChip('Upcoming'),
                              const SizedBox(width: 8),
                              _buildFilterChip('Past'),
                              // const SizedBox(width: 8),
                              // _buildFilterChip('Shared with me'),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Itinerary list
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async {
                          setState(() {
                            _itinerariesFuture =
                                _itineraryService.getAllItineraries(userId);
                          });
                          await _itinerariesFuture;
                        },
                        child: filteredItineraries.isEmpty
                            ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(height: 100),
                            Center(
                              child: Text(
                                'No ${_currentFilter
                                    .toLowerCase()} itineraries found',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ),
                          ],
                        )
                            : ListView.builder(
                          itemCount: filteredItineraries.length,
                          itemBuilder: (context, index) {
                            final itinerary = filteredItineraries[index];
                            return ItineraryListItem(itinerary: itinerary);
                          },
                        ),
                      ),
                    ),

                  ],
                );
              },
            ),
          );
        }
    );
  }



  Widget _buildStat(String label, String value, {Color color = Colors.black}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _currentFilter == label;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentFilter = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryRed : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
  Widget _buildAuthError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: Colors.red),
          const SizedBox(height: 20),
          const Text('Authentication Required'),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/'),
            child: const Text('Go to Login'),
          ),
        ],
      ),
    );
  }

}


class ItineraryListItem extends StatelessWidget {
  final Itinerary itinerary;

  const ItineraryListItem({
    Key? key,
    required this.itinerary,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Calculate trip duration
    final difference = itinerary.endDate.difference(itinerary.startDate).inDays + 1;
    final dateFormat = DateFormat('MMM d');

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ItineraryMenu(id: itinerary.itineraryId),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            itinerary.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                color: AppColors.primaryRed.withOpacity(0.9),
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                itinerary.locationAddress,
                                style: TextStyle(
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '$difference days',
                        style: TextStyle(
                          color: AppColors.primaryRed.withOpacity(0.8),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${dateFormat.format(itinerary.startDate)} - ${dateFormat.format(itinerary.endDate)}, ${itinerary.startDate.year}',
                      style: TextStyle(
                        color: Colors.grey[800],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Created ${_getTimeAgo(itinerary.createdAt)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.visibility_outlined, size: 16),
                        label: const Text('View'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ItineraryMenu(id: itinerary.itineraryId),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black87,
                          side: BorderSide(color: Colors.grey[300]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.share_outlined, size: 16),
                        label: const Text('Share'),
                        onPressed: () {
                          fetchAndShowShareCode(context,itinerary.itineraryId);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black87,
                          side: BorderSide(color: Colors.grey[300]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);

    if (difference.inDays >= 7) {
      return '${(difference.inDays / 7).floor()} week${difference.inDays >= 14 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else {
      return '${difference.inMinutes} minute${difference.inMinutes != 1 ? 's' : ''} ago';
    }
  }
}
