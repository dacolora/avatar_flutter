import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../controllers/avatar_creator_controller.dart';

/// El "lienzo" del avatar: combina el color de fondo (#2 Background) con las
/// capas ilustradas seleccionadas (#3 Preview), apiladas una encima de otra,
/// y se actualiza en tiempo real cada vez que el usuario cambia una
/// selección.
///
/// El preview es siempre cuadrado (relación de aspecto 1:1) y su contenido
/// se escala de forma proporcional y centrada, sin recortarse, tal como pide
/// la especificación de diseño.
class AvatarPreview extends StatelessWidget {
  const AvatarPreview({super.key});

  @override
  Widget build(BuildContext context) {
    // `context.watch<T>()` es la forma corta de suscribirse a un
    // `ChangeNotifier` provisto más arriba en el árbol (aquí, el
    // `AvatarCreatorController` que `AvatarCreatorScreen` registró con
    // `ChangeNotifierProvider`). Cada vez que el controlador llama a
    // `notifyListeners()` — por ejemplo, al seleccionar una opción nueva —
    // este widget completo se reconstruye con los valores más recientes.
    final controller = context.watch<AvatarCreatorController>();

    return AnimatedContainer(
      // `AnimatedContainer` funciona como un `Container` normal, pero cuando
      // alguna de sus propiedades (aquí, `color`) cambia entre una
      // reconstrucción y otra, anima la transición en vez de saltar
      // bruscamente al nuevo valor. Así, cambiar el color de fondo se ve como
      // un fundido suave en vez de un cambio instantáneo.
      duration: const Duration(milliseconds: 150),
      width: double.infinity,
      height: 240,
      color: controller.backgroundColor,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 24,
      ),
      // `RepaintBoundary` aísla esta parte del árbol para que Flutter pueda
      // redibujarla de forma independiente del resto de la pantalla — pero
      // aquí cumple, además, un segundo propósito clave: le da a este
      // subárbol una identidad concreta en el árbol de render que se puede
      // "fotografiar" más adelante. Es exactamente lo que hace
      // [AvatarCreatorController.save] a través de `previewBoundaryKey`: le
      // pide a este `RepaintBoundary` específico que convierta lo que tiene
      // pintado en una imagen PNG.
      child: RepaintBoundary(
        key: controller.previewBoundaryKey,
        child: AspectRatio(
          aspectRatio: 1,
          // `Stack` dibuja a todos sus hijos unos encima de otros, en el
          // mismo espacio, en el orden en que aparecen en la lista `children`
          // (el primero queda más al fondo, el último más arriba). Aquí cada
          // hijo es una capa SVG seleccionada, y el orden viene dado por
          // `controller.layerAssetPaths`, que a su vez respeta el orden del
          // catálogo (ver [AvatarLayerCategory] y
          // [AvatarCreatorController.layerAssetPaths]).
          child: Stack(
            fit: StackFit.expand,
            children: [
              for (final assetPath in controller.layerAssetPaths)
                SvgPicture.asset(
                  assetPath,
                  // `package: 'avatar_flutter'` le dice a `flutter_svg` que
                  // el asset vive dentro de este paquete (en su propia
                  // carpeta `assets/`), no en la app que lo consume. Es
                  // necesario porque los assets declarados en el
                  // `pubspec.yaml` de un paquete no son automáticamente
                  // visibles para la app anfitriona salvo que se indique
                  // explícitamente de qué paquete vienen.
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
