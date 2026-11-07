import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../features/auth/domain/app_user.dart';
import '../theme/app_palette.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.user, required this.size});

  final AppUser? user;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final url = user?.photoUrl;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: p.signal, shape: BoxShape.circle),
      child: url != null
          ? CachedNetworkImage(imageUrl: url, width: size, height: size, fit: BoxFit.cover)
          : Text(
              user?.initials ?? '',
              style: context.text.titleMedium?.copyWith(color: p.signalInk, fontSize: size * 0.34),
            ),
    );
  }
}
