// lib/screens/home/widgets/ongoing_activities_section.dart

import 'package:flutter/material.dart';
import '../../../../utils/constants/colors.dart';

class OngoingActivitiesSection extends StatelessWidget {
  const OngoingActivitiesSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(

      height: 150,
      alignment: Alignment.center,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Text(
        'Coming soon',
        style: TextStyle(fontSize: 20, 

        fontStyle: FontStyle.italic),
      ),
      // This would be replaced with actual content
      
    );
  }
}
