import 'dart:typed_data';

import 'package:avatar_flutter/avatar_flutter.dart';
import 'package:flutter/material.dart';

import 'avatar_image_cache.dart';

/// Muestra el avatar cacheado en el celular (ver [AvatarImageCache]), sin
/// depender de ningún estado en memoria — por eso se puede usar en
/// **cualquier pantalla** de la app, no solo en la que hizo el guardado
/// (`ProfileScreen`): cada instancia lee el mismo archivo del caché por su
/// cuenta.
///
/// Si todavía no hay nada cacheado (primer uso, o el sistema operativo
/// liberó el caché), cae de vuelta a [selectionFallback] —la selección
/// persistida en `SharedPreferences`— recomponiendo el avatar con
/// `AvatarStaticPreview`; si tampoco hay selección, muestra un ícono de
/// placeholder.
class CachedAvatarImage extends StatelessWidget {
  const CachedAvatarImage({
    required this.radius,
    this.selectionFallback,
    super.key,
  });

  final double radius;
  final Map<String, String>? selectionFallback;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: AvatarImageCache.read(),
      builder: (context, snapshot) {
        final cachedBytes = snapshot.data;
        if (cachedBytes != null) {
          return CircleAvatar(
            radius: radius,
            backgroundImage: MemoryImage(cachedBytes),
          );
        }
        if (selectionFallback != null) {
          return AvatarStaticPreview(
            selection: selectionFallback!,
            size: radius * 2,
          );
        }
        return CircleAvatar(
          radius: radius,
          child: Icon(Icons.person, size: radius * 0.86),
        );
      },
    );
  }
}
