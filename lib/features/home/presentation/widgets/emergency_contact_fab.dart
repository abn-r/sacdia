import 'package:flutter/material.dart';

class EmergencyContactFab extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isExpanded;

  const EmergencyContactFab({
    super.key,
    required this.onPressed,
    this.isExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isExpanded ? 120 : 56,
      height: 56,
      child: FloatingActionButton.extended(
        onPressed: onPressed,
        backgroundColor: Colors.red,
        icon: const Icon(Icons.emergency, color: Colors.white),
        label: isExpanded
            ? const Text(
                'SOS',
                style: TextStyle(color: Colors.white),
              )
            : const SizedBox.shrink(),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isExpanded ? 30 : 16),
        ),
      ),
    );
  }
} 