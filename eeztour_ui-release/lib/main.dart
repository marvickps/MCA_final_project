import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'common/config.dart';
import 'common/user_session.dart';
import 'features/authentication/screens/login_screen.dart';
import 'features/authentication/screens/only_user_registration.dart';
import 'features/authentication/screens/regitration.dart';
import 'features/homescreen/screens/homeScreen.dart';

import 'features/homescreen/screens/user_homepage.dart';
import 'features/itinerary/itineraryDay/controllers/place_search_controller.dart';
import 'features/itinerary/itineraryDay/screens/add_location_showMap.dart';
import 'features/itinerary/itinerary_Creation/controllers/city_search_controller.dart';
import 'features/itinerary/itinerary_Creation/controllers/hotel_search_controller.dart';
import 'features/itinerary/itinerary_Creation/controllers/date_range_controller.dart';
import 'features/itinerary/itinerary_Creation/screens/itinerary_creation_screen.dart';
import 'features/itinerary/itinerary_Creation/screens/itinerary_details_screen.dart';
import 'features/itinerary/itinerary_Creation/controllers/location_search.dart';

import 'features/itinerary/itinerary_Menu/screens/itineraryMenu.dart';

import 'features/itinerary/itineraryMap/screens/itineraryMap_whole.dart';


import 'features/itinerary/itineraryMap/controllers/route_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env"); // Load environment variables

  // Get the Google Maps API key from environment variables
  final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  if (apiKey.isEmpty) {
    print('WARNING: Google Maps API key not found in .env file');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()..loadUser()),
        ChangeNotifierProvider(create: (_) => CitySearchController()),
        ChangeNotifierProvider(
          create: (_) => HotelSearchController(apiKey: apiKey),
        ),
        ChangeNotifierProvider(
          create: (_) => PlaceSearchController(apiKey: apiKey, ),
        ),
        ChangeNotifierProvider(create: (_) => DateRangeController()),
        ChangeNotifierProvider(create: (_) => LocationSearchController()),
        ChangeNotifierProvider(create: (_) => ItineraryRouteController()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eeztour',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        // AppBar Theme
        appBarTheme: AppBarTheme(
          color: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black54),
          titleTextStyle: TextStyle(
            color: Colors.black54,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),

        ),// Change to any color you like
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/home': (context) => const ShareCodeScreen(),
        '/register': (context) => const RegisterScreen(),
        '/homescreen': (context) => const HomeScreen(),
        '/itinerary': (context) => const ItineraryCreationScreen(),
        '/details': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<
                    String,
                    dynamic
                  >; // Changed to dynamic to accept doubles
          return ItineraryDetailsScreen(
            itineraryPlaceID: args['placeId'],
            itineraryCityName: args['cityName']!,
          );
        },
          '/itineraryMenu': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          return ItineraryMenu(id: args?['id'] ?? 0); // Provide a default value or handle null case
        },        
        '/itineraryMap_Whole': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return ItineraryMapScreen(id: args['id'], day: args['day'],);
        },
        '/add_location_showMap': (context) => const AddLocationShowMapPage(),
      },
    );
  }
}
