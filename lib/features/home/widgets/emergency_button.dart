import 'package:flutter/material.dart';
import 'package:sacdia/core/constants.dart';

class EmergencyButton extends StatelessWidget {
  final VoidCallback onTap;
  
  const EmergencyButton({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 16,
        right: 16,
      ),
      child: FloatingActionButton.extended(
        onPressed: onTap,
        backgroundColor: sacRed,
        elevation: 4,
        isExtended: true,
        label: const Text(
          'SOS',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        icon: const Icon(
          Icons.phone,
          color: Colors.white,
        ),
      ),
    );
  }
} 