import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../auth/microsoft_profile_photo_service.dart';
import '../design/app_theme.dart';
import '../di/locator.dart';

/// Circular Microsoft profile photo with a deterministic initials fallback.
class MicrosoftAvatar extends StatelessWidget {
  const MicrosoftAvatar({
    super.key,
    required this.displayName,
    this.userPrincipalName,
    this.currentUser = false,
    this.radius = 20,
    this.photoService,
  });

  final String displayName;
  final String? userPrincipalName;
  final bool currentUser;
  final double radius;
  final MicrosoftProfilePhotoService? photoService;

  String get _initial {
    final name = displayName.trim();
    if (name.isNotEmpty) return name.characters.first.toUpperCase();
    final identity = userPrincipalName?.trim() ?? '';
    return identity.isNotEmpty ? identity.characters.first.toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final service = photoService ??
        (locator.isRegistered<MicrosoftProfilePhotoService>()
            ? locator<MicrosoftProfilePhotoService>()
            : null);
    final photo = service == null
        ? null
        : (currentUser
            ? service.currentUserPhoto(size: radius >= 32 ? 96 : 48)
            : service.userPhoto(userPrincipalName ?? '', size: 48));

    return FutureBuilder<Uint8List?>(
      future: photo,
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        return Semantics(
          label: '$displayName profile photo',
          image: bytes != null,
          child: CircleAvatar(
            radius: radius,
            backgroundColor: context.palette.brand.withValues(alpha: 0.14),
            backgroundImage: bytes == null ? null : MemoryImage(bytes),
            child: bytes == null
                ? Text(
                    _initial,
                    style: TextStyle(
                      color: context.palette.brand,
                      fontWeight: FontWeight.bold,
                      fontSize: radius * 0.72,
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }
}
