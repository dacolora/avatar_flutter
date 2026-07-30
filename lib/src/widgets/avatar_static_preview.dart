import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../controllers/avatar_creator_controller.dart';
import '../data/avatar_catalog.dart';
import '../models/avatar_layer_category.dart';

/// Dibuja el avatar compuesto (color de fondo + capas apiladas) a partir de
/// una selección ya conocida, **sin** abrir [AvatarCreatorScreen].
///
/// Este es el widget para cuando el canal necesita *mostrar* un avatar en
/// algún lugar de su app — una lista de usuarios, un encabezado de perfil,
/// una tarjeta — a partir de la `Map<String, String>` que ya tiene guardada
/// (la misma forma que [AvatarCreatorResult.selection] y que
/// [AvatarCreatorConfig.initialSelection]), sin necesidad de navegar a la
/// pantalla completa de edición solo para ver cómo se superponen los SVGs.
///
/// ```dart
/// AvatarStaticPreview(
///   selection: seleccionGuardada, // el mismo Map<String, String> de siempre
///   size: 40,
/// )
/// ```
///
/// Por dentro arma un [AvatarCreatorController] desechable (nunca se
/// inserta en el árbol de widgets ni se escucha) solo para reutilizar
/// exactamente la misma lógica de resolución que ya usa
/// [AvatarCreatorScreen] — [AvatarCreatorController.backgroundColor] y
/// [AvatarCreatorController.layerAssetPaths] — así una selección
/// incompleta o con ids desconocidos se resuelve con los mismos valores de
/// respaldo en los dos lugares, en vez de duplicar esa lógica.
///
/// A diferencia de [AvatarPreview] (el preview en vivo dentro del creador),
/// este widget no tiene el lavado pálido alrededor ni un `RepaintBoundary`
/// para guardarlo como PNG — es solo el círculo del avatar, pensado para
/// insertarse en cualquier parte de la UI del canal como una imagen más.
class AvatarStaticPreview extends StatelessWidget {
  const AvatarStaticPreview({
    required this.selection,
    this.categories,
    this.size = 96,
    super.key,
  });

  /// La selección a dibujar, como `categoryId -> optionId` — la misma forma
  /// que [AvatarCreatorResult.selection]. Un id de categoría u opción que no
  /// exista en [categories] no lanza ninguna excepción: se resuelve con el
  /// mismo respaldo que usa [AvatarCreatorController] (la primera opción de
  /// esa categoría, o transparente si no hay categoría de fondo).
  final Map<String, String> selection;

  /// El catálogo contra el cual se interpreta [selection]. Si se deja en
  /// `null`, usa [defaultAvatarCatalog] — debe ser el **mismo catálogo**
  /// (o uno compatible en los ids que use [selection]) que se usó para
  /// generar esa selección originalmente.
  final List<AvatarLayerCategory>? categories;

  /// Diámetro del círculo del avatar, en píxeles lógicos.
  final double size;

  @override
  Widget build(BuildContext context) {
    // Un `AvatarCreatorController` normal, pero que nunca se expone vía
    // `AvatarCreatorScope` ni se escucha con `addListener`: aquí solo sirve
    // para calcular `backgroundColor`/`layerAssetPaths` una vez, con la
    // misma lógica exacta que usa la pantalla de edición. Como no vive en
    // el árbol de widgets, se libera apenas se leen esos dos valores.
    final controller = AvatarCreatorController(
      categories: categories ?? defaultAvatarCatalog(),
      initialSelection: selection,
    );
    final backgroundColor = controller.backgroundColor;
    final layers = controller.layerAssetPaths;
    controller.dispose();

    return SizedBox(
      width: size,
      height: size,
      // `ClipOval` recorta las capas al círculo del avatar: sin esto, una
      // capa cuyo dibujo llegue hasta las esquinas de su lienzo cuadrado
      // (por ejemplo, los hombros de Vestuario) sobresaldría visualmente
      // del círculo en vez de quedar contenida en él.
      child: ClipOval(
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircleAvatar(radius: size / 2, backgroundColor: backgroundColor),
            SizedBox(
              width: size,
              height: size,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  for (final layer in layers)
                    SvgPicture.asset(
                      layer.path,
                      package: layer.package,
                      fit: BoxFit.contain,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
