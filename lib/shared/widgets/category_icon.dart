import 'package:flutter/material.dart';
import '../../core/theme/category_palette.dart';

class CategoryIcon extends StatelessWidget {
  final String iconKey;
  final int colorValue;
  final double size;

  const CategoryIcon({
    super.key,
    required this.iconKey,
    required this.colorValue,
    this.size = 40,
  });

  static IconData getIconData(String key) {
    switch (key) {
      case 'restaurant':
        return Icons.restaurant;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'directions_car':
        return Icons.directions_car;
      case 'movie':
        return Icons.movie;
      case 'receipt_long':
        return Icons.receipt_long;
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'medical_services':
        return Icons.medical_services;
      case 'school':
        return Icons.school;
      case 'payments':
        return Icons.payments;
      case 'laptop_mac':
        return Icons.laptop_mac;
      case 'trending_up':
        return Icons.trending_up;
      case 'card_giftcard':
        return Icons.card_giftcard;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'flight':
        return Icons.flight;
      case 'home':
        return Icons.home;
      case 'pets':
        return Icons.pets;
      case 'phone_android':
        return Icons.phone_android;
      case 'local_gas_station':
        return Icons.local_gas_station;
      default:
        return Icons.category;
    }
  }

  static const List<MapEntry<String, IconData>> availableIcons = [
    MapEntry('restaurant', Icons.restaurant),
    MapEntry('shopping_cart', Icons.shopping_cart),
    MapEntry('directions_car', Icons.directions_car),
    MapEntry('movie', Icons.movie),
    MapEntry('receipt_long', Icons.receipt_long),
    MapEntry('shopping_bag', Icons.shopping_bag),
    MapEntry('medical_services', Icons.medical_services),
    MapEntry('school', Icons.school),
    MapEntry('payments', Icons.payments),
    MapEntry('laptop_mac', Icons.laptop_mac),
    MapEntry('trending_up', Icons.trending_up),
    MapEntry('card_giftcard', Icons.card_giftcard),
    MapEntry('fitness_center', Icons.fitness_center),
    MapEntry('flight', Icons.flight),
    MapEntry('home', Icons.home),
    MapEntry('pets', Icons.pets),
    MapEntry('phone_android', Icons.phone_android),
    MapEntry('local_gas_station', Icons.local_gas_station),
  ];

  static const List<int> availableColors = CategoryPalette.colors;

  @override
  Widget build(BuildContext context) {
    final color = Color(colorValue);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(getIconData(iconKey), color: color, size: size * 0.55),
      ),
    );
  }
}
