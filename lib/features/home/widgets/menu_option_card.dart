import 'package:flutter/material.dart';
import 'package:sacdia/core/constants.dart';
import 'package:sacdia/features/user/models/menu_option_model.dart';

class MenuOptionCard extends StatelessWidget {
  final MenuOptionModel option;
  final VoidCallback onTap;
  
  const MenuOptionCard({
    super.key,
    required this.option,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                option.iconPath,
                height: 40,
                width: 40,
              ),
              const SizedBox(height: 8),
              Text(
                option.title,
                style: const TextStyle(
                  color: sacBlack,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 