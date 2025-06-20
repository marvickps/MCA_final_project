import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/day_itineraryMap_model.dart';

class CustomMarkerHelper {
  // Singleton pattern to ensure we maintain a single instance
  static final CustomMarkerHelper _instance = CustomMarkerHelper._internal();
  factory CustomMarkerHelper() => _instance;
  CustomMarkerHelper._internal();

  // Cache for marker icons to prevent redundant generation
  static final Map<String, BitmapDescriptor> _markerIconCache = {};

  // Default marker to use as fallback
  static BitmapDescriptor? _defaultMarker;

  // Get a cached icon or create a new one
  static Future<BitmapDescriptor> getMarkerIcon(
      String order,
      Color color,
      String placeType,
      String cacheKey,
      ) async {
    // Check if the icon is already in cache
    if (_markerIconCache.containsKey(cacheKey)) {
      debugPrint('CustomMarkerHelper: Using cached marker for $cacheKey');
      return _markerIconCache[cacheKey]!;
    }

    try {
      // Create the custom marker
      final customMarker = await createCustomMarkerBitmap(order, color, placeType);
      // Store in cache
      _markerIconCache[cacheKey] = customMarker;
      debugPrint('CustomMarkerHelper: Created new marker for $cacheKey');
      return customMarker;
    } catch (e) {
      debugPrint('CustomMarkerHelper: Error creating marker $cacheKey: $e');
      // Return default marker if custom creation fails
      if (_defaultMarker == null) {
        _defaultMarker = BitmapDescriptor.defaultMarker;
      }
      return _defaultMarker!;
    }
  }

  static Future<BitmapDescriptor> createCustomMarkerBitmap(
      String order,
      Color color,
      String placeType,
      ) async {
    // Increase size for better resolution
    const size = Size(160, 160);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Draw the circle background
    final Paint circlePaint = Paint()..color = color;
    final center = Offset(size.width / 2, size.height / 2);

    // Add drop shadow for better visibility
    final Paint shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawCircle(center, size.width / 2.4, shadowPaint);
    canvas.drawCircle(center, size.width / 2.5, circlePaint);

    // Add border
    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;

    canvas.drawCircle(center, size.width / 2.5, borderPaint);

    // Draw the order number
    TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: order,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 50, // Larger font
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        (size.height - textPainter.height) / 2,
      ),
    );

    try {
      // Convert to image with error handling
      final ui.Image image = await recorder.endRecording().toImage(
        size.width.toInt(),
        size.height.toInt(),
      );

      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData == null) {
        throw Exception('Failed to get byte data from marker image');
      }

      final Uint8List uint8List = byteData.buffer.asUint8List();
      return BitmapDescriptor.fromBytes(uint8List);
    } catch (e) {
      debugPrint('CustomMarkerHelper: Error in bitmap creation: $e');
      rethrow; // Re-throw to be caught by the calling function
    }
  }

  static Future<Map<String, BitmapDescriptor>> createMarkerIcons(
      List<DayItineraryModel> days,
      ) async {
    Map<String, BitmapDescriptor> markerIcons = {};
    List<Future<void>> markerFutures = [];

    for (var day in days) {
      for (var place in day.sortedPlaces) {
        final iconKey = '${day.dayId}_${place.placeId}';

        // Skip if coordinates are invalid
        if (place.latitude == 0.0 && place.longitude == 0.0) {
          debugPrint('CustomMarkerHelper: Skipping marker $iconKey due to invalid coordinates');
          continue;
        }

        // Create a Future for each marker creation
        final markerFuture = getMarkerIcon(
          place.order,
          day.routeColor,
          place.placeType,
          iconKey,
        ).then((icon) {
          markerIcons[iconKey] = icon;
        }).catchError((error) {
          debugPrint('CustomMarkerHelper: Error creating marker $iconKey: $error');
          // Use default marker as fallback
          markerIcons[iconKey] = BitmapDescriptor.defaultMarker;
        });

        markerFutures.add(markerFuture);
      }
    }

    // Wait for all marker creations to complete
    await Future.wait(markerFutures);
    debugPrint('CustomMarkerHelper: Created ${markerIcons.length} markers');

    return markerIcons;
  }

  // Method to clear the marker cache when needed
  static void clearCache() {
    _markerIconCache.clear();
    debugPrint('CustomMarkerHelper: Cache cleared');
  }
}