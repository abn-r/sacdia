import 'package:flutter/material.dart';
import 'package:sacdia/features/post_register/models/emergency_contact.dart';

class EmergencyContactsList extends StatelessWidget {
  final List<EmergencyContact> contacts;
  final Function(EmergencyContact) onContactSelected;

  const EmergencyContactsList({
    super.key,
    required this.contacts,
    required this.onContactSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: contacts.length,
      itemBuilder: (context, index) {
        final contact = contacts[index];
        return GestureDetector(
          onTap: () => onContactSelected(contact),
          child: Card(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: ListTile(
              leading: CircleAvatar(
                child: Text(contact.name[0].toUpperCase()),
              ),
              title: Text(contact.name),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(contact.phone)
                ],
              ),
            ),
          ),
        );
      },
    );
  }
} 