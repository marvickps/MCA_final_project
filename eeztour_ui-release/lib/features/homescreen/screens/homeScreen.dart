// lib/screens/home/home_screen.dart

import 'package:eeztour/features/itinerary/itineraryDay/screens/itinerary_day_screen.dart';
import 'package:eeztour/features/itinerary/itineraryDay/widgets/ItineraryStopsWidget.dart';
import 'package:eeztour/features/itinerary/itinerary_Menu/screens/itineraryMenu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../utils/constants/colors.dart';
import '../../../common/config.dart';
import '../../../common/user_session.dart';
import '../../authentication/screens/debug_screen.dart';
import '../../itinerary/itineraryDay/screens/AddLocations.dart';
import '../../itinerary/itinerary_Creation/screens/ShowAllItienery.dart';
import './widgets/registration_banner.dart';
import './widgets/onGoing.dart';
import './widgets/dashboard_grid.dart';
import '../models/dashboard_item.dart';
import '../../chatbot/screens/chatbot_screen.dart';
import '../../authentication/screens/profile_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Create dashboard items
    final List<DashboardItem> dashboardItems = [
      DashboardItem(
        title: 'Itineary \n Creation',
        icon: Icons.map,
        backgroundColor: AppColors.itineraryBlue,
        onTap: () {
          Navigator.pushNamed(context, '/itinerary');
        },
      ),
      DashboardItem(
        title: 'Itinearies',
        icon: Icons.event,
        backgroundColor: AppColors.eventsPink,
        onTap: () {
           Navigator.push(
             context,
             MaterialPageRoute(builder: (context) => const ItineraryListPage()),
           );
        },
      ),
      DashboardItem(
        title: 'AI Chatbot',
        icon: Icons.smart_toy, // Updated to a more relevant icon
        backgroundColor: AppColors.commissionGreen,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ChatbotScreen()),
          );
        },
      ),
      DashboardItem(
        title: 'Resources',
        icon: Icons.business,
        backgroundColor: AppColors.resourcesOrange,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProfileScreen()),
          );
        },
      ),
      DashboardItem(
        title: 'Packages',
        icon: Icons.layers,
        backgroundColor: AppColors.packagesYellow,
        onTap: () {},
      ),

      DashboardItem(
        title: 'Orders',
        icon: Icons.list_alt,
        backgroundColor: AppColors.ordersLimeGreen,
        notificationCount: 5,
        onTap: () {},
      ),
      DashboardItem(
        title: 'My Clients',
        icon: Icons.people,
        backgroundColor: AppColors.clientsTeal,
        onTap: () {},
      ),
      DashboardItem(
        title: 'Collaborate',
        icon: Icons.handshake,
        backgroundColor: AppColors.collaborateSalmon,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  AddLocationsScreen(
                    dayId: 279,
                    location: "Tacloban City, Philippines",
                    ezType: "hotel",
                    googlePlaceType: "lodging",
                  ),
            ),
          );;
        },
      ),
      DashboardItem(
        title: 'Analytics',
        icon: Icons.analytics,
        backgroundColor: AppColors.analyticsPurple,
        onTap: () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder:
                  (context) => DebugScreen()
                  ), // this is for debug dont remove it
            );
        },
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Bar with logo and settings - full width
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // App Logo (the red "Z")
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primaryRed,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        'Z',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  // Settings Icon
                  // IconButton(icon: Icon(Icons.settings), onPressed: () {}),
                  // IconButton(
                  //   icon: Icon(Icons.logout),
                  //   onPressed: () async {
                  //     await UserSession.getInstance().then((session) => session.clearSession());
                  //     context.read<UserProvider>().clearUser();
                  //
                  //     Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                  //   },
                  // ),
                  IconButton(
                    icon: Icon(Icons.person_pin),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ProfileScreen()),
                      );
                    },
                  )
                ],
              ),
            ),

            // Registration Banner - full width
            const RegistrationBanner(),

            // Ongoing Activities Header - full width
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: const Text(
                'Ongoing Activities',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),

            // Ongoing Activities Section - full width
            const OngoingActivitiesSection(),

            // Dashboard Header - full width
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: const Text(
                'Dashboard',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),

            // Dashboard Grid - expand to fill remaining space
            Expanded(
              child: DashboardGrid(
                items: dashboardItems,
                screenWidth: screenWidth,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
