import 'package:flutter/material.dart';

class PlanData {
  static List<Map<String, dynamic>> plans = [
    {
      'name': '1 Month Basic',
      'price': '1,000',
      'duration': '1 Month',
      'features': ['General Training', 'Gym Access', 'Locker Room'],
      'color': const Color(0xFF2D6A4F),
    },
    {
      'name': '3 Months Silver',
      'price': '2,500',
      'duration': '3 Months',
      'features': ['General Training', 'Gym Access', 'Locker Room', 'Diet Plan'],
      'color': Colors.blueGrey,
    },
    {
      'name': '6 Months Gold',
      'price': '4,500',
      'duration': '6 Months',
      'features': ['Personal Trainer', 'Gym Access', 'Locker Room', 'Diet Plan', 'Steam Bath'],
      'color': const Color(0xFFB8860B),
    },
    {
      'name': '1 Year Platinum',
      'price': '8,000',
      'duration': '1 Year',
      'features': ['Personal Trainer', 'Gym Access', 'Locker Room', 'Full Diet Plan', 'Steam Bath', 'Massage'],
      'color': const Color(0xFF556B2F),
    },
  ];
}
