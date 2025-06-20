import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/place_search_controller.dart';
import '../../../../common/functions.dart';

class AddLocationsScreen extends StatefulWidget {
  final int dayId;
  final String location;
  final String ezType;
  final String googlePlaceType;

  const AddLocationsScreen({
    super.key,
    required this.dayId,
    required this.location,
    required this.ezType,
    required this.googlePlaceType,
  });

  @override
  _AddLocationsScreenState createState() => _AddLocationsScreenState();
}

class _AddLocationsScreenState extends State<AddLocationsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isInitialLoad = true;
  bool _isGlobalMode = true; // Toggle state: true for global, false for local

  @override
  void initState() {
    super.initState();
    // Load nearby places when screen initializes with force refresh
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData(forceRefresh: true);
    });
  }

  // Helper method to load data based on current mode
  void _loadData({bool forceRefresh = false}) {
    final placeSearchController = Provider.of<PlaceSearchController>(context, listen: false);
    if (_isGlobalMode) {
      placeSearchController.loadNearbyPlaces(widget.location, widget.googlePlaceType, forceRefresh: forceRefresh);
    } else {
      placeSearchController.loadLocalPlaces(context, widget.ezType, forceRefresh: forceRefresh);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _isGlobalMode = !_isGlobalMode;
      _searchController.clear(); // Clear search when switching modes
    });

    _loadData(forceRefresh: true); // Force refresh when switching modes
  }

  // Pull to refresh handler
  Future<void> _onRefresh() async {
    _loadData(forceRefresh: true);

    // Wait for loading to complete
    final placeSearchController = Provider.of<PlaceSearchController>(context, listen: false);
    while (placeSearchController.isLoading) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  @override
  Widget build(BuildContext context) {
    final placeSearchController = Provider.of<PlaceSearchController>(context);

    // Track when first load is complete
    if (_isInitialLoad && !placeSearchController.isLoading &&
        ((_isGlobalMode && placeSearchController.nearbyPlaces.isNotEmpty) ||
            (!_isGlobalMode && placeSearchController.localPlaces.isNotEmpty))) {
      setState(() {
        _isInitialLoad = false;
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Add ${widget.ezType}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Toggle between Global and Local
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (!_isGlobalMode) _toggleMode();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _isGlobalMode ? Colors.redAccent : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Global',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _isGlobalMode ? Colors.white : Colors.black54,
                            fontWeight: _isGlobalMode ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (_isGlobalMode) _toggleMode();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !_isGlobalMode ? Colors.redAccent : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'My Resources',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: !_isGlobalMode ? Colors.white : Colors.black54,
                            fontWeight: !_isGlobalMode ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Search field
            TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                labelText: 'Search ${widget.ezType}',
                hintText: 'Type to search for ${widget.ezType}...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(color: Colors.redAccent),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    if (_isGlobalMode) {
                      placeSearchController.searchPlaces('', widget.location, widget.googlePlaceType);
                    } else {
                      placeSearchController.searchLocalPlaces('', widget.ezType);
                    }
                  },
                )
                    : null,
              ),
              onChanged: (value) {
                if (_isGlobalMode) {
                  placeSearchController.searchPlaces(value, widget.location, widget.googlePlaceType);
                } else {
                  placeSearchController.searchLocalPlaces(value, widget.ezType);
                }
              },
            ),
            const SizedBox(height: 6),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Row(
                children: [
                  Icon(Icons.place, color: Colors.redAccent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _searchController.text.isEmpty
                          ? _isGlobalMode
                          ? 'Recommended ${widget.ezType} in ${widget.location}'
                          : 'My ${widget.ezType[0].toUpperCase()}${widget.ezType.substring(1)}'
                          : 'Search Results',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Loading, Error, or Places List
            if (placeSearchController.isLoading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (placeSearchController.error != null)
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _onRefresh,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.5,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                            const SizedBox(height: 16),
                            Text(
                              placeSearchController.error!,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.red.shade700),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadData(forceRefresh: true),
                              child: const Text('Retry'),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Pull down to refresh',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _onRefresh,
                  child: _buildPlacesList(placeSearchController),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlacesList(PlaceSearchController controller) {
    final places = _searchController.text.isEmpty
        ? (_isGlobalMode ? controller.nearbyPlaces : controller.localPlaces)
        : controller.searchSuggestions;

    if (places.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.4,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  _searchController.text.isEmpty
                      ? 'No ${widget.ezType} found in this area'
                      : 'No ${widget.ezType} matching your search',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pull down to refresh',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Show refresh indicator for search results when not actively searching
    if (_searchController.text.isNotEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: places.length,
        itemBuilder: (context, index) {
          final place = places[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _buildPlaceItem(place, controller),
          );
        },
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: places.length,
      itemBuilder: (context, index) {
        final place = places[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: _buildPlaceItem(place, controller),
        );
      },
    );
  }

  Widget _buildPlaceItem(PlaceSuggestion place, PlaceSearchController controller) {
    return InkWell(
      onTap: () {
        controller.selectPlace(place.placeId, place.name);

        // Navigate to map screen with selected place details
        Navigator.pushNamed(
          context,
          '/add_location_showMap',
          arguments: {
            'location': widget.location,
            'placeId': place.placeId,
            'placeName': place.name,
            'ezType': widget.ezType,
            'dayId': widget.dayId,
          },
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Place icon based on type
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: _getColorForType(widget.ezType),
                borderRadius: BorderRadius.circular(6.0),
              ),
              child: Icon(
                _getIconForType(widget.ezType),
                color: Colors.white,
                size: 25,
              ),
            ),
            const SizedBox(width: 16),

            // Place details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (place.address.isNotEmpty) ...[
                    Text(
                      place.address,
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (place.rating != null && place.rating != 'N/A' && place.rating!.isNotEmpty) ...[
                    _buildRatingRow(place.rating),
                  ],
                ],
              ),
            ),

            Icon(
              Icons.arrow_forward_ios,
              size: 12,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingRow(String? rating) {
    if (rating == null || rating == 'N/A') {
      return Text(
        'No ratings yet',
        style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
      );
    }

    // Convert rating to double and clamp to 5.0 max
    final ratingValue = double.tryParse(rating) ?? 0.0;
    final starCount = ratingValue.clamp(0.0, 5.0);

    return Row(
      children: [
        Row(
          children: List.generate(5, (index) {
            // Full star, half star or empty star
            IconData iconData;
            Color color;

            if (index < starCount.floor()) {
              iconData = Icons.star;
              color = Colors.amber;
            } else if (index == starCount.floor() && starCount % 1 > 0) {
              iconData = Icons.star_half;
              color = Colors.amber;
            } else {
              iconData = Icons.star_border;
              color = Colors.grey.shade400;
            }

            return Icon(iconData, size: 14, color: color);
          }),
        ),
        const SizedBox(width: 4),
        Text(
          rating,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            fontSize: 12,
          ),
        ),
      ],
    );
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

  Color _getColorForType(String ezType) {
    switch (ezType.toLowerCase()) {
      case 'restaurant':
        return Colors.orange;
      case 'hotel':
        return Colors.blue;
      default:
        return Colors.green;
    }
  }
}