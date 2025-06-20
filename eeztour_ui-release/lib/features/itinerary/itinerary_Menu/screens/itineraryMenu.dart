import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/ItineraryModel.dart';
import '../widgets/ItineraryMenuWidget.dart';
import 'package:http/http.dart' as http;
import 'package:eeztour/common/config.dart';


class ItineraryMenu extends StatefulWidget {
  final int id;

  const ItineraryMenu({super.key, required this.id});

  @override
  State<ItineraryMenu> createState() => _ItineraryMenuState();
}

class _ItineraryMenuState extends State<ItineraryMenu> {
  late Future<ItineraryModel> _itineraryMenuData;

  Future<ItineraryModel> fetchItineraryMenuData(int id) async {
    final url = Uri.parse('$baseUrl/itinerary/menu_details/$id');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return ItineraryModel.fromJson(data);
    } else {
      throw Exception('failed to load itinerary, check api call');
    }
  }

  @override
  void initState() {
    super.initState();
    _itineraryMenuData = fetchItineraryMenuData(widget.id);
  }

  Future<void> _refreshItinerary() async {
    setState(() {
      _itineraryMenuData = fetchItineraryMenuData(widget.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ItineraryModel>(
      future: _itineraryMenuData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Error'),
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
            ),
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        } else if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: Text('No data found.')));
        }

        final itinerary = snapshot.data!;
        final List<MenuItemModel> menuItems = [
          MenuItemModel(title: 'Map', iconPath: 'map', route: '/map'),
          MenuItemModel(title: 'Places', iconPath: 'places', route: '/places'),
          MenuItemModel(title: 'Hotels', iconPath: 'hotels', route: '/hotels'),
          MenuItemModel(title: 'Rental', iconPath: 'rental', route: '/rental'),
          MenuItemModel(
            title: 'Activities',
            iconPath: 'activities',
            route: '/activities',
          ),
          MenuItemModel(title: 'About', iconPath: 'about', route: '/about'),
          MenuItemModel(title: 'Cost', iconPath: 'cost', route: '/cost'),
        ];

        return Scaffold(
          appBar: AppBar(
            title: Text(itinerary.itineraryName),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: RefreshIndicator(
            onRefresh: _refreshItinerary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ItineraryHeader(itinerary: itinerary),
                    const SizedBox(height: 24),
                    Text(
                      itinerary.itineraryName,
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 1,
                      color: Colors.grey.shade300,
                      width: double.infinity,
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      crossAxisCount: 3,
                      childAspectRatio: 1.0,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      children:
                          menuItems
                              .map((item) => MenuItemWidget(menuItem: item))
                              .toList(),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
