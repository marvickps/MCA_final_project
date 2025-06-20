// lib/models/dashboard_item.dart

import 'package:flutter/material.dart';

class DashboardItem {
  final String title;
  final IconData icon;
  final Color backgroundColor;
  final int notificationCount;
  final VoidCallback onTap;

  DashboardItem({
    required this.title,
    required this.icon,
    required this.backgroundColor,
    this.notificationCount = 0,
    required this.onTap,
  });
}