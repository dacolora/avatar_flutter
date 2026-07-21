import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../controllers/avatar_creator_controller.dart';

/// #2 (Background) + #3 (Preview): apila las capas seleccionadas sobre el
/// color de fondo elegido y actualiza en tiempo real ante cada selección.
///
/// El componente es siempre cuadrado (el alto se iguala al ancho disponible)
/// y su contenido se escala centrado y de forma proporcional, sin recortarse,
/// según la especificación de "Especificaciones".
class AvatarPreview extends StatelessWidget {
  const AvatarPreview({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AvatarCreatorController>();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: double.infinity,
      height: 240,
      color: controller.backgroundColor,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 24,
      ),
      child: RepaintBoundary(
        key: controller.previewBoundaryKey,
        child: AspectRatio(
          aspectRatio: 1,
          child: Stack(
            fit: StackFit.expand,
            children: [
              for (final assetPath in controller.layerAssetPaths)
                SvgPicture.asset(
                  assetPath,
                  package: 'avatar_flutter',
                  fit: BoxFit.contain,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
