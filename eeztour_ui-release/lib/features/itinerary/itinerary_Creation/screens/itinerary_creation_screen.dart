import 'package:eeztour/common/widgets/continue_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/city_search_controller.dart';

class ItineraryCreationScreen extends StatefulWidget {
  const ItineraryCreationScreen({Key? key}) : super(key: key);

  @override
  _ItineraryCreationScreenState createState() =>
      _ItineraryCreationScreenState();
}

class _ItineraryCreationScreenState extends State<ItineraryCreationScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final citySearchController = Provider.of<CitySearchController>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Itinerary Creation')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search field
            TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                labelText: 'Search City',
                hintText: 'Type a city name...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                suffixIcon:
                    _searchController.text.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            citySearchController.updateQuery('');
                          },
                        )
                        : null,
              ),
              onChanged: (value) {
                citySearchController.updateQuery(value);
              },
            ),
            const SizedBox(height: 16),

            // Status indicators and predictions list
            if (citySearchController.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (!citySearchController.isInitialized)
              const Center(
                child: Text(
                  'Location services not initialized. Please check your API key.',
                  textAlign: TextAlign.center,
                ),
              )
            else
              Expanded(
                child:
                    citySearchController.predictions.isEmpty
                        ? Center(
                          child: Text(
                            _searchController.text.isEmpty
                                ? 'Start typing to search for a city'
                                : '',
                          ),
                        )
                        : ListView.builder(
                          itemCount: citySearchController.predictions.length,
                          itemBuilder: (context, index) {
                            final prediction =
                                citySearchController.predictions[index];
                            return ListTile(
                              leading: const Icon(Icons.location_on),
                              title: Text(prediction.description ?? ''),
                              onTap: () {
                                citySearchController.selectPrediction(
                                  prediction,
                                );
                                _searchController.text =
                                    citySearchController.selectedCityName ?? '';
                              },
                            );
                          },
                        ),
              ),

            // Continue button
            ContinueButton(
              isEnabled: citySearchController.selectedPlaceId != null,
              onPressed: () {
                final args = {
                  'placeId':
                      citySearchController
                          .selectedPlaceId!, // Note the case: placeId (lowercase p)
                  'cityName': citySearchController.selectedCityName ?? '',
                };

                // Debug print
                print('Navigating to details with arguments: $args');

                Navigator.pushNamed(context, '/details', arguments: args);
              },
            ),
          ],
        ),
      ),
    );
  }
}
