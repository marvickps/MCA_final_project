// map_widget.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../controllers/route_controller.dart'; // Ensure this path is correct
import '../models/route_model.dart'; // Import RouteModel
import 'custom_market.dart'; // Ensure this path is correct and the helper exists

class ItineraryMapWidget extends StatefulWidget {
  final int id;
  final String day;
  const ItineraryMapWidget({super.key, required this.id, required this.day});

  @override
  State<ItineraryMapWidget> createState() => _ItineraryMapWidgetState();
}

class _ItineraryMapWidgetState extends State<ItineraryMapWidget> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  Map<String, BitmapDescriptor> _markerIcons = {};

  int _lastProcessedVersion = -1;
  bool _isLoadingMarkers = false;
  // Enhanced map style (keep your preferred style)
  static const String _mapStyle = '''
    [
      {
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#f5f5f5"
          }
        ]
      },
      {
        "elementType": "labels.icon",
        "stylers": [
          {
            "visibility": "on"
          }
        ]
      },
      {
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#616161"
          }
        ]
      },
      {
        "elementType": "labels.text.stroke",
        "stylers": [
          {
            "color": "#f5f5f5"
          }
        ]
      },
      {
        "featureType": "administrative.land_parcel",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#bdbdbd"
          }
        ]
      },
      {
        "featureType": "poi",
        "stylers": [
          {
            "visibility": "on"
          }
        ]
      },
      {
        "featureType": "poi",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#e3f2fd"
          }
        ]
      },
      {
        "featureType": "poi.park",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#c8e6c9"
          }
        ]
      },
      {
        "featureType": "road",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#ffffff"
          }
        ]
      },
      {
        "featureType": "road.arterial",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#eeeeee"
          }
        ]
      },
      {
        "featureType": "road.highway",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#dadada"
          }
        ]
      },
      {
        "featureType": "water",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#bbdefb"
          }
        ]
      }
    ]
    ''';

  @override
  void initState() {
    super.initState();
    _markers = {};
    _polylines = {};
    _markerIcons = {};
    _lastProcessedVersion = -1;
    _isLoadingMarkers = false;
    debugPrint("ItineraryMapWidget initState: Initialized empty overlays.");

    // Optional: Trigger initial data load if this widget is responsible for it
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   if (mounted) {
    //     Provider.of<ItineraryRouteController>(context, listen: false)
    //         .loadSampleItineraryData(); // Or your actual load function
    //   }
    // });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    debugPrint("ItineraryMapWidget dispose: Disposed map controller.");
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ItineraryRouteController>(
      builder: (context, controller, child) {
        final currentVersion = controller.dataVersion;

        debugPrint(
          'Map Widget Build: Version=$currentVersion, LastVersion=$_lastProcessedVersion, Loading=${controller.isLoading}, Days=${controller.days.length}',
        );

        if (!controller.isLoading &&
            controller.days.isNotEmpty &&
            !_isLoadingMarkers &&
            (_lastProcessedVersion != currentVersion ||
                _markers.isEmpty || // Check both markers and polylines
                _polylines.isEmpty)) {
          debugPrint(
            'Build condition met: Data ready and changed/missing. Scheduling overlay update.',
          );
          _isLoadingMarkers = true;
          _lastProcessedVersion =
              currentVersion; // Update version tracking *before* async task

          Future.microtask(() {
            if (mounted) {
              debugPrint("Future.microtask: Calling _updateMapOverlays...");
              _updateMapOverlays(controller).then((_) {
                // Reset loading flag when complete
                if (mounted) {
                  setState(() {
                    _isLoadingMarkers = false;
                  });

                }

              });
            } else {
              debugPrint(
                "Future.microtask: Widget not mounted, skipping overlay update.",
              );
              _isLoadingMarkers = false;
            }
          });
        } else if (controller.isLoading) {
          debugPrint('Build: Controller is loading. Waiting...');
        } else if (controller.days.isEmpty && !controller.isLoading) {
          debugPrint('Build: Controller has no days and is not loading.');
          if (_markers.isNotEmpty || _polylines.isNotEmpty) {
            debugPrint(
              'Build: Clearing existing overlays as controller days are now empty.',
            );
            Future.microtask(() {
              if (mounted) {
                setState(() {
                  _markers = {};
                  _polylines = {};
                });
              }
            });
          }
        } else {
          debugPrint(
            'Build: Condition not met. Using existing overlays (Markers: ${_markers.length}, Polylines: ${_polylines.length}).',
          );
        }

        // Initial camera position (e.g., center of the region or first point)
        LatLng initialTarget = const LatLng(
          25.5788,
          91.8933,
        ); // Shillong default
        if (controller.days.isNotEmpty &&
            controller.days.first.sortedPlaces.isNotEmpty) {
          final firstPlace = controller.days.first.sortedPlaces.first;
          if (firstPlace.latitude != 0.0 && firstPlace.longitude != 0.0) {
            initialTarget = LatLng(firstPlace.latitude, firstPlace.longitude);
          }
        }
        CameraPosition initialPosition = CameraPosition(
          target: initialTarget,
          zoom: 11, // Adjust zoom as needed
        );

        debugPrint(
          'Rendering GoogleMap with Markers: ${_markers.length}, Polylines: ${_polylines.length}',
        );

        return Stack(
          children: [
            GoogleMap(
              initialCameraPosition: initialPosition,
              markers: _markers, // Use the widget's state variable
              polylines: _polylines, // Use the widget's state variable
              mapType: MapType.normal,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              zoomControlsEnabled: false, // Using custom controls
              compassEnabled: true,
              mapToolbarEnabled: true,
              buildingsEnabled: true,
              trafficEnabled: false, // Keep false unless needed
              tiltGesturesEnabled: true,
              onMapCreated: (GoogleMapController mapCtrl) {
                debugPrint("GoogleMap onMapCreated: Controller received.");
                _mapController = mapCtrl;
                _mapController!
                    .setMapStyle(_mapStyle)
                    .then((_) {
                      debugPrint("GoogleMap onMapCreated: Map style set.");
                    })
                    .catchError((error) {
                      debugPrint(
                        "GoogleMap onMapCreated: Error setting map style: $error",
                      );
                    });

                // Fit bounds once the map is created, *if* overlays are already present
                // The main fitting happens after _updateMapOverlays finishes.
                if (_markers.isNotEmpty) {
                  debugPrint(
                    "GoogleMap onMapCreated: Initial markers exist, attempting fit.",
                  );
                  // Add a small delay to ensure the map is fully initialized visually
                  Future.delayed(const Duration(milliseconds: 300), () {
                    if (mounted) _fitAllMarkers();
                  });
                }
              },
              onCameraMove: (position) {
                // Optional: Log camera movements for debugging zoom/panning
                // debugPrint("Camera Position: ${position.target}, Zoom: ${position.zoom}");
              },
            ),

            // Loading Indicator
            if (controller.isLoading || _isLoadingMarkers)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(
                    child: Card(
                      elevation: 8,
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ),
                ),
              ),


            // Zoom & Fit Controls
            Positioned(
              top: 20,
              right: 10,
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.add),
                      tooltip: "Zoom In",
                      onPressed:
                          () => _mapController?.animateCamera(
                            CameraUpdate.zoomIn(),
                          ),
                    ),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      indent: 8,
                      endIndent: 8,
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove),
                      tooltip: "Zoom Out",
                      onPressed:
                          () => _mapController?.animateCamera(
                            CameraUpdate.zoomOut(),
                          ),
                    ),
                    if (_markers.isNotEmpty) ...[
                      // Only show fit button if there are markers
                      const Divider(
                        height: 1,
                        thickness: 1,
                        indent: 8,
                        endIndent: 8,
                      ),
                      IconButton(
                        icon: const Icon(Icons.fit_screen),
                        tooltip: "Fit All Markers",
                        onPressed: _fitAllMarkers,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Refresh Button
            Positioned(
              top: 20,
              left: 10,
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: "Reload Itinerary Data",
                  onPressed:
                      controller.isLoading || _isLoadingMarkers
                          ? null
                          : () {
                            // Disable if already loading
                            debugPrint("Refresh button pressed.");
                            // Clear current overlays immediately for visual feedback
                            setState(() {
                              _markers = {};
                              _polylines = {};
                              _lastProcessedVersion =
                                  -1;
                              CustomMarkerHelper.clearCache();
                              _markerIcons
                                  .clear(); // Clear icons so they regenerate
                              debugPrint(
                                "Refresh: Cleared local markers, polylines, and icons.",
                              );
                            });
                            // Trigger data reload in controller
                            // Replace with your actual data loading method if not sample
                            Provider.of<ItineraryRouteController>(
                              context,
                              listen: false,
                            ).loadSampleItineraryData(widget.id, widget.day);
                          },
                ),
              ),
            ),

            // Positioned(
            //   bottom: 10,
            //   left: 10,
            //   child: Card(
            //     color: Colors.white.withOpacity(0.85),
            //     elevation: 4,
            //     shape: RoundedRectangleBorder(
            //       borderRadius: BorderRadius.circular(8),
            //     ),
            //     child: Padding(
            //       padding: const EdgeInsets.all(6.0),
            //       child: Column(
            //         crossAxisAlignment: CrossAxisAlignment.start,
            //         mainAxisSize: MainAxisSize.min,
            //         children: [
            //           Text(
            //             'Markers: ${_markers.length}',
            //             style: const TextStyle(fontSize: 10),
            //           ),
            //           Text(
            //             'Polylines: ${_polylines.length}',
            //             style: const TextStyle(fontSize: 10),
            //           ),
            //           Text(
            //             'Ctrl Version: ${controller.dataVersion}',
            //             style: const TextStyle(fontSize: 10),
            //           ),
            //           Text(
            //             'Widget Version: $_lastProcessedVersion',
            //             style: const TextStyle(fontSize: 10),
            //           ),
            //           Text(
            //             'Loading: ${controller.isLoading}',
            //             style: const TextStyle(fontSize: 10),
            //           ),
            //         ],
            //       ),
            //     ),
            //   ),
            // ),
          ],
        );
      },
    );
  }

  Future<void> _updateMapOverlays(ItineraryRouteController controller) async {
    if (controller.days.isEmpty) {
      debugPrint(
        '_updateMapOverlays: No days found in controller. Aborting update.',
      );
      // Ensure overlays are cleared if controller days become empty
      if (mounted && (_markers.isNotEmpty || _polylines.isNotEmpty)) {
        setState(() {
          _markers = {};
          _polylines = {};
        });
      }
      return;
    }

    debugPrint(
      '_updateMapOverlays: Starting overlay update for ${controller.days.length} days.',
    );

    // Prepare new sets to hold the generated overlays
    Set<Marker> newMarkers = {};
    Set<Polyline> newPolylines = {};

    // Generate marker icons if they haven't been created yet
    try {

      // Generate marker icons - with improved error handling

      debugPrint("_updateMapOverlays: Creating marker icons...");

      _markerIcons = await CustomMarkerHelper.createMarkerIcons(controller.days);

      debugPrint(

        '_updateMapOverlays: Created ${_markerIcons.length} custom marker icons.',

      );

    } catch (e) {

      debugPrint('_updateMapOverlays: Error creating marker icons: $e');

      // Continue with whatever markers we could create

    }

    int totalPolylinesCreated = 0;
    int totalMarkersCreated = 0;

    // Process each day to create markers and polylines
    for (final day in controller.days) {
      final Color routeColor =
          day.routeColor; // Color assigned in the controller
      debugPrint('_updateMapOverlays: Processing Day ${day.dayId}');

      // --- Create Markers for the Day ---
      for (final place in day.sortedPlaces) {
        // Basic validation for coordinates
        if (place.latitude != 0.0 && place.longitude != 0.0) {
          final markerIdVal = '${day.dayId}_${place.placeId}';
          final markerId = MarkerId(markerIdVal);
          final position = LatLng(place.latitude, place.longitude);

          // Get the custom icon or fallback to default
          BitmapDescriptor icon =
              _markerIcons[markerIdVal] ?? BitmapDescriptor.defaultMarker;

          newMarkers.add(
            Marker(
              markerId: markerId,
              position: position,
              infoWindow: InfoWindow(
                title:
                    place.name.isNotEmpty ? place.name : "Place ${place.order}",
                snippet:
                    'Day ${day.dayId} - Stop ${place.order} (${place.placeType})',
              ),
              icon: icon,
              zIndex: 1.0, // Ensure markers are generally above polylines
              onTap: () {
                debugPrint("Marker tapped: ${place.name}");
                _mapController?.animateCamera(CameraUpdate.newLatLng(position));
              },
            ),
          );
          totalMarkersCreated++;
        } else {
          debugPrint(
            '_updateMapOverlays: Skipping marker for Place ID ${place.placeId} (Day ${day.dayId}) due to invalid coordinates (0,0).',
          );
        }
      }

      // --- Create Polylines for the Day ---
      // Retrieve the calculated routes for this specific day from the controller
      final List<RouteModel> routesForDay =
          controller.dayRoutes[day.dayId] ?? [];
      debugPrint(
        '_updateMapOverlays: Day ${day.dayId} has ${routesForDay.length} routes in controller data.',
      );

      if (routesForDay.isNotEmpty) {
        for (final route in routesForDay) {
          if (route.points.isNotEmpty && route.points.length >= 2) {
            // Check if points list is not empty and has at least 2 points
            try {
              final polylineId = PolylineId(
                route.id,
              ); // Use the unique route ID
              final polyline = Polyline(
                polylineId: polylineId,
                color: routeColor.withOpacity(
                  0.75,
                ), // Use day's color with some transparency
                width: 5, // Adjust width as needed
                points:
                    route.points, // Use the LatLng points from the RouteModel
                visible: true,
                startCap: Cap.roundCap,
                endCap: Cap.roundCap,
                jointType: JointType.round,
                zIndex: 0, // Lower zIndex than markers
              );

              newPolylines.add(polyline);
              totalPolylinesCreated++;
              // debugPrint( '_updateMapOverlays: Added polyline ${polyline.polylineId.value} with ${route.points.length} points.');
            } catch (e) {
              debugPrint(
                "_updateMapOverlays: Error creating polyline ${route.id} for Day ${day.dayId}: $e",
              );
            }
          } else {
            debugPrint(
              '_updateMapOverlays: Skipping polyline ${route.id} for Day ${day.dayId} because points list has ${route.points.length} points (requires >= 2).',
            );
          }
        }
      } else {
        debugPrint(
          '_updateMapOverlays: No routes found in controller.dayRoutes for Day ${day.dayId}. Cannot draw polylines.',
        );
      }
    }

    debugPrint(
      '_updateMapOverlays: Finished processing. Total Markers: $totalMarkersCreated, Total Polylines: $totalPolylinesCreated',
    );

    // --- Update State ---
    // Check if the widget is still mounted before calling setState
    if (mounted) {
      setState(() {
        _markers = newMarkers;
        _polylines = newPolylines;
        debugPrint(
          '_updateMapOverlays: setState called. Widget markers=${_markers.length}, polylines=${_polylines.length}',
        );
      });

      // Fit map to bounds only if new markers were actually added
      if (newMarkers.isNotEmpty) {
        debugPrint(
          '_updateMapOverlays: New markers exist, calling _fitAllMarkers.',
        );
        // Add a small delay to allow the map to render the new overlays before fitting
        await Future.delayed(const Duration(milliseconds: 150));
        if (mounted) {
          // Check mounted again after delay
          _fitAllMarkers();
        }
      } else {
        debugPrint(
          '_updateMapOverlays: No new markers added, skipping map fitting.',
        );
      }
    } else {
      debugPrint(
        '_updateMapOverlays: Widget unmounted before setState could be called.',
      );
    }
  }

  // Zooms/pans the camera to fit all markers with padding
  void _fitAllMarkers() {
    if (_mapController == null) {
      debugPrint('_fitAllMarkers: Map controller is null. Cannot fit.');
      return;
    }
    if (_markers.isEmpty) {
      debugPrint('_fitAllMarkers: No markers available. Cannot fit.');
      return;
    }

    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;

    bool validMarkerFound = false;
    for (Marker marker in _markers) {
      // Additional check within fitting logic
      if (marker.position.latitude != 0.0 || marker.position.longitude != 0.0) {
        validMarkerFound = true;
        minLat =
            marker.position.latitude < minLat
                ? marker.position.latitude
                : minLat;
        maxLat =
            marker.position.latitude > maxLat
                ? marker.position.latitude
                : maxLat;
        minLng =
            marker.position.longitude < minLng
                ? marker.position.longitude
                : minLng;
        maxLng =
            marker.position.longitude > maxLng
                ? marker.position.longitude
                : maxLng;
      }
    }

    // If no valid markers found (e.g., all were 0,0), don't try to fit.
    if (!validMarkerFound) {
      debugPrint(
        '_fitAllMarkers: No valid marker positions found after checking. Cannot calculate bounds.',
      );
      return;
    }

    // Handle the case of a single marker
    if (_markers.length == 1) {
      debugPrint('_fitAllMarkers: Fitting to single marker.');
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(minLat, minLng),
          14.0, // Zoom level for a single marker
        ),
      );
    } else {
      // Calculate bounds for multiple markers
      debugPrint(
        '_fitAllMarkers: Fitting bounds to SW: ($minLat, $minLng), NE: ($maxLat, $maxLng)',
      );
      try {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(
            LatLngBounds(
              southwest: LatLng(minLat, minLng),
              northeast: LatLng(maxLat, maxLng),
            ),
            60.0, // Padding around the bounds
          ),
        );
      } catch (e) {
        // Catch potential LatLngBounds error if southwest == northeast after all checks
        debugPrint(
          "_fitAllMarkers: Error animating camera to bounds: $e. Possibly identical marker positions?",
        );
        _mapController!.animateCamera(
          // Fallback to zooming on the single point
          CameraUpdate.newLatLngZoom(LatLng(minLat, minLng), 14.0),
        );
      }
    }
  }
}
