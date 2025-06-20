import 'dart:async';

import 'package:eeztour/features/itinerary/itinerary_Creation/models/hotel_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/hotel_search_controller.dart';

class HotelSearchField extends StatefulWidget {
  final String placeId;
  final String cityName;
  final TextEditingController controller;
  final String labelText;
  final String hintText;

  const HotelSearchField({
    Key? key,
    required this.placeId,
    required this.cityName,
    required this.controller,
    this.labelText = 'Accommodation',
    this.hintText = 'Search Hotels...',
  }) : super(key: key);

  @override
  State<HotelSearchField> createState() => _HotelSearchFieldState();
}

class _HotelSearchFieldState extends State<HotelSearchField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  
  // Debounce for search
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);

    // Update the controller if a hotel was previously selected
    final controller = Provider.of<HotelSearchController>(context, listen: false);
    if (controller.selectedHotelName != null) {
      widget.controller.text = controller.selectedHotelName!;
    }
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });

    if (_focusNode.hasFocus) {
      _loadTopHotels();
      _showOverlay();
    } else {
      _hideOverlay();
      
      // Clear suggestions after a delay
      Future.delayed(const Duration(milliseconds: 200), () {
        if (!mounted) return;
        Provider.of<HotelSearchController>(context, listen: false).clearSuggestions();
      });
    }
  }

  void _loadTopHotels() {
    final hotelController = Provider.of<HotelSearchController>(context, listen: false);
    
    // Check if city has changed
    bool forceRefresh = widget.cityName != hotelController.lastSearchCity;
    
    // Load top rated hotels for this city
    hotelController.loadTopHotelsForCity(widget.cityName, forceRefresh: forceRefresh);
  }

  void _showOverlay() {
    // Remove any existing overlay
    _hideOverlay();

    _overlayEntry = OverlayEntry(builder: (context) => _buildOverlay());

    if (_overlayEntry != null) {
      Overlay.of(context).insert(_overlayEntry!);
    }
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Widget _buildOverlay() {
    // Get screen dimensions
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return Consumer<HotelSearchController>(
      builder: (context, hotelController, _) {
        final isLoading = hotelController.isLoading;
        final error = hotelController.error;
        
        // Determine which hotel list to show
        final suggestions = widget.controller.text.trim().isEmpty
            ? hotelController.topHotels  // Show top hotels when empty
            : hotelController.searchSuggestions;  // Show search results when typing

        return Positioned(
          width: size.width,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: const Offset(0.0, 60.0), // Adjust as needed
            child: Material(
              elevation: 4.0,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4, // 40% of screen height
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _buildSuggestionsList(suggestions, isLoading, error),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSuggestionsList(
    List<HotelSuggestion> suggestions,
    bool isLoading,
    String? error,
  ) {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (error != null) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(error, style: TextStyle(color: Colors.red.shade700)),
      );
    }

    if (suggestions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: widget.controller.text.trim().isEmpty
            ? const Text('Loading top hotels...')
            : const Text('No hotels found. Try different search terms.'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8.0, left: 12.0),
          child: Text(
            widget.controller.text.trim().isEmpty
                ? 'Top Hotels Nearby'
                : 'Search Results',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.blue,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            itemCount: suggestions.length,
            itemBuilder: (context, index) {
              final suggestion = suggestions[index];
              return _buildHotelItem(suggestion);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHotelItem(HotelSuggestion hotel) {
    final hotelController = Provider.of<HotelSearchController>(context, listen: false);

    return InkWell(
      onTap: () {
        widget.controller.text = hotel.name;
        hotelController.selectHotel(hotel.placeId, hotel.name);
        FocusScope.of(context).unfocus();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hotel icon instead of image
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(6.0),
              ),
              child: const Icon(Icons.hotel, color: Colors.blue),
            ),
            const SizedBox(width: 12),

            // Hotel details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hotel.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hotel.address,
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  _buildRatingAndPrice(hotel),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingAndPrice(HotelSuggestion hotel) {
    return Row(
      children: [
        if (hotel.rating != 'N/A') ...[
          const Icon(Icons.star, color: Colors.amber, size: 16),
          const SizedBox(width: 4),
          Text(
            hotel.rating,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 12),
        ],
        if (hotel.priceLevel != null) ...[
          Text(
            '\$' * int.parse(hotel.priceLevel!),
            style: TextStyle(
              color: Colors.green.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        decoration: InputDecoration(
          labelText: widget.labelText,
          hintText: widget.hintText,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          suffixIcon: Consumer<HotelSearchController>(
            builder: (context, controller, _) {
              return controller.isLoading
                  ? Container(
                      margin: const EdgeInsets.all(12),
                      width: 16,
                      height: 16,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.hotel);
            },
          ),
        ),
        onChanged: (query) {
          // Debounce to avoid too many API calls
          if (_debounce?.isActive ?? false) _debounce!.cancel();
          _debounce = Timer(const Duration(milliseconds: 500), () {
            final hotelController = Provider.of<HotelSearchController>(
              context, 
              listen: false,
            );
            
            if (query.trim().isEmpty) {
              // If query is empty, show top hotels
              hotelController.loadTopHotelsForCity(widget.cityName);
            } else {
              // Otherwise, search for hotels matching the query
              hotelController.searchHotels(query, widget.cityName);
            }
          });
        },
        onTap: () {
          // Load top hotels when tapped
          _loadTopHotels();
        },
      ),
    );
  }

  @override
  void dispose() {
    _hideOverlay();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }
}