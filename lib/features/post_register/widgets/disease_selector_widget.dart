import 'package:flutter/material.dart';
import 'package:sacdia/core/constants.dart';
import 'package:sacdia/features/post_register/models/disease_model.dart';

class DiseaseSelectorWidget extends StatelessWidget {
  final List<Disease> selectedDiseases;
  final VoidCallback onTap;

  const DiseaseSelectorWidget({
    super.key,
    required this.selectedDiseases,
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
                  'ENFERMEDADES',
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
                    '${selectedDiseases.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            selectedDiseases.isEmpty
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.medical_services_outlined,
                        size: 40,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'No se han seleccionado enfermedades aún, presiona para seleccionar',
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  )
                : Wrap(
                    spacing: 8,
                    children: selectedDiseases
                        .map((disease) => Chip(
                              label: Text(disease.name,
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
