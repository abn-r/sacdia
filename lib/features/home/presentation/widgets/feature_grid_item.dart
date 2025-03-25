import 'package:flutter/material.dart';
import '../../domain/models/app_feature.dart';

class FeatureGridItem extends StatelessWidget {
  final AppFeature feature;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool isEnabled;

  const FeatureGridItem({
    super.key,
    required this.feature,
    required this.onTap,
    this.onLongPress,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        onLongPress: isEnabled ? onLongPress : null,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: feature.backgroundColor ?? Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                feature.icon,
                size: 32,
                color: isEnabled ? null : Colors.grey,
              ),
              const SizedBox(height: 8),
              Text(
                feature.name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isEnabled ? null : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 