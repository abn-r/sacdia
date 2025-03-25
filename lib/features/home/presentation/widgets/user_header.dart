import 'package:flutter/material.dart';
import 'package:sacdia/core/constants.dart';
import 'package:sacdia/features/auth/models/user_model.dart';

class UserHeader extends StatelessWidget {
  final UserModel user;
  final String? photoUrl;
  final VoidCallback? onProfileTap;

  const UserHeader({
    super.key,
    required this.user,
    this.photoUrl,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: sacRed,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hola',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: sacBlack,
                  ),
                ),
                Text(
                  '${user.id} ${user.email}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onProfileTap,
            child: Hero(
              tag: 'profile_photo',
              child: CircleAvatar(
                radius: 30,
                backgroundColor: Colors.grey[200],
                backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
                child: photoUrl == null
                    ? const Icon(Icons.person, size: 32, color: Colors.grey)
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 