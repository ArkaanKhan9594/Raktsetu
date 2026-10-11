import 'package:flutter/material.dart';
import '../models/donor.dart';

class BloodGroupChip extends StatelessWidget {
  final BloodGroup group;
  final double size;
  const BloodGroupChip({super.key, required this.group, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: group.isRare ? const Color(0xFFB3122E) : const Color(0xFF1B3A6B),
        shape: BoxShape.circle,
      ),
      child: Text(
        group.label,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: size * 0.32,
        ),
      ),
    );
  }
}
