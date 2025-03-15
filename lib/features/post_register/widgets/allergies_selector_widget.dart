import 'package:flutter/material.dart';
import 'package:sacdia/core/constants.dart';
import 'package:sacdia/features/post_register/models/allergy_model.dart';
class AllergiesSelectorWidget extends StatelessWidget {
  final List<Allergy> selectedAllergies;
  final VoidCallback onTap;

  const AllergiesSelectorWidget({
    super.key,
    required this.selectedAllergies,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'ALERGIAS',
                  style: TextStyle(
                    fontSize: 16,
                    color: sacBlack,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: sacRed,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${selectedAllergies.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            selectedAllergies.isEmpty
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 40,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'No se han seleccionado alergias aún, presiona para seleccionar',
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  )
                : Wrap(
                    spacing: 8,
                    children: selectedAllergies
                        .map((allergy) => Chip(
                              label: Text(allergy.name,
                                  style: const TextStyle(fontSize: 14)),
                              backgroundColor: Colors.grey[150],
                              visualDensity: VisualDensity.compact,
                            ))
                        .toList(),
                  ),
          ],
        ),
      ),
    );
  }
}
