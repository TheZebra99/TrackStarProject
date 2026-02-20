import 'package:flutter/material.dart';

class Achievement {
  final String id;
  final IconData icon;
  final String title;
  final String description;
  // isUnlocked now also receives maxSingleDistance for single-activity checks
  final bool Function(int totalActivities, double totalDistance, double maxSingleDistance) isUnlocked;

  const Achievement({
    required this.id,
    required this.icon,
    required this.title,
    required this.description,
    required this.isUnlocked,
  });
}

final List<Achievement> allAchievements = [
  Achievement(
    id: 'first_walk',
    icon: Icons.directions_walk,
    title: 'Prva šetnja',
    description: 'Završite prvu aktivnost',
    isUnlocked: (activities, _, __) => activities >= 1,
  ),
  Achievement(
    id: 'five_activities',
    icon: Icons.local_fire_department,
    title: '5 aktivnosti',
    description: 'Završite 5 aktivnosti',
    isUnlocked: (activities, _, __) => activities >= 5,
  ),
  Achievement(
    id: 'ten_activities',
    icon: Icons.military_tech,
    title: '10 aktivnosti',
    description: 'Završite 10 aktivnosti',
    isUnlocked: (activities, _, __) => activities >= 10,
  ),
  Achievement(
    id: 'ten_km',
    icon: Icons.terrain,
    title: '10 km',
    description: 'Ukupno pređite 10 km',
    isUnlocked: (_, distance, __) => distance >= 10.0,
  ),
  Achievement(
    id: 'run_marathon',
    icon: Icons.directions_run,
    title: 'Maraton',
    description: 'Istrčite maraton u jednoj aktivnosti (42,195 km)',
    // Single-activity marathon: maxSingleDistance must be >= 42.195
    isUnlocked: (_, __, maxSingle) => maxSingle >= 42.195,
  ),
  Achievement(
    id: 'hundred_km',
    icon: Icons.public,
    title: '100 km',
    description: 'Ukupno pređite 100 km',
    isUnlocked: (_, distance, __) => distance >= 100.0,
  ),
];