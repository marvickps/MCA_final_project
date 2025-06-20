import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_place/google_place.dart';
import '../controllers/location_search.dart';

class LocationSearchField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String hintText;

  const LocationSearchField({
    Key? key,
    required this.controller,
    this.labelText = 'Location',
    this.hintText = 'Search locations...',
  }) : super(key: key);

  @override
  State<LocationSearchField> createState() => _LocationSearchFieldState();
}

class _LocationSearchFieldState extends State<LocationSearchField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  
  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);

    // Update the controller if a location was previously selected
    final controller = Provider.of<LocationSearchController>(context, listen: false);
    if (controller.selectedLocationName != null) {
      widget.controller.text = controller.selectedLocationName!;
    }
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });

    if (_focusNode.hasFocus) {
      _showOverlay();
    } else {
      _hideOverlay();
      
      // Clear suggestions after a delay
      Future.delayed(const Duration(milliseconds: 200), () {
        if (!mounted) return;
        Provider.of<LocationSearchController>(context, listen: false).clearSuggestions();
      });
    }
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

    return Consumer<LocationSearchController>(
      builder: (context, locationController, _) {
        final suggestions = locationController.suggestions;
        final isLoading = locationController.isLoading;
        final error = locationController.error;

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
    List<AutocompletePrediction> suggestions,
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
      if (widget.controller.text.trim().isEmpty) {
        return const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Start typing to search for locations'),
        );
      } else {
        return const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No locations found. Try different search terms.'),
        );
      }
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final suggestion = suggestions[index];
        return _buildLocationItem(suggestion);
      },
    );
  }

  Widget _buildLocationItem(AutocompletePrediction location) {
    final locationController = Provider.of<LocationSearchController>(context, listen: false);
    
    // Extract main text and secondary text from structured formatting
    String mainText = location.structuredFormatting?.mainText ?? location.description ?? '';
    String secondaryText = location.structuredFormatting?.secondaryText ?? '';

    return InkWell(
      onTap: () {
        widget.controller.text = location.description ?? '';
        locationController.selectLocation(location);
        FocusScope.of(context).unfocus();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Location icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(6.0),
              ),
              child: const Icon(Icons.location_on, color: Colors.green),
            ),
            const SizedBox(width: 12),

            // Location details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mainText,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    secondaryText,
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
          suffixIcon: Consumer<LocationSearchController>(
            builder: (context, controller, _) {
              return controller.isLoading
                  ? Container(
                      margin: const EdgeInsets.all(12),
                      width: 16,
                      height: 16,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.location_on);
            },
          ),
        ),
        onChanged: (query) {
          final locationController = Provider.of<LocationSearchController>(
            context, 
            listen: false,
          );
          
          locationController.updateQuery(query);
        },
      ),
    );
  }

  @override
  void dispose() {
    _hideOverlay();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }
}