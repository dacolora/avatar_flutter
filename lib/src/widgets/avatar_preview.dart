import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../controllers/avatar_creator_scope.dart';

/// El "lienzo" del avatar: combina el color de fondo (#2 Background) con las
/// capas ilustradas seleccionadas (#3 Preview), apiladas una encima de otra,
/// y se actualiza en tiempo real cada vez que el usuario cambia una
/// selección.
///
/// Según la especificación de diseño, el avatar en sí (el color de fondo +
/// las capas) vive dentro de un **círculo** ([_circleDiameter] de diámetro,
/// como un [CircleAvatar]) centrado en el área de preview. Fuera de ese
/// círculo, pero dentro del rectángulo de [_height] de alto, el fondo no es
/// blanco ni transparente: es el mismo color de fondo elegido, pero con baja
/// opacidad — un lavado pálido que separa visualmente "el avatar" del resto
/// de la pantalla sin usar un color distinto ni un borde.
class AvatarPreview extends StatelessWidget {
  const AvatarPreview({super.key});

  static const double _height = 249;
  static const double _circleDiameter = 200;

  @override
  Widget build(BuildContext context) {
    // `AvatarCreatorScope.of(context)` suscribe a este widget al
    // `AvatarCreatorController` expuesto más arriba en el árbol por
    // `AvatarCreatorScreen`. Cada vez que el controlador llama a
    // `notifyListeners()` — por ejemplo, al seleccionar una opción nueva —
    // este widget completo se reconstruye con los valores más recientes.
    final controller = AvatarCreatorScope.of(context);
    final backgroundColor = controller.backgroundColor;

    return AnimatedContainer(
      // `AnimatedContainer` funciona como un `Container` normal, pero cuando
      // alguna de sus propiedades (aquí, `color`) cambia entre una
      // reconstrucción y otra, anima la transición en vez de saltar
      // bruscamente al nuevo valor. Así, cambiar el color de fondo se ve como
      // un fundido suave en vez de un cambio instantáneo.
      duration: const Duration(milliseconds: 150),
      width: double.infinity,
      height: _height,
      // El lavado pálido "fuera" del círculo: el mismo color, pero con solo
      // un 25% de opacidad — por eso se ve como un tono suave/difuminado del
      // color de fondo en vez del color sólido que sí lleva el círculo.
      color: backgroundColor.withOpacity(0.25),
      child: Center(
        // `RepaintBoundary` aísla esta parte del árbol para que Flutter
        // pueda redibujarla de forma independiente del resto de la
        // pantalla — pero aquí cumple, además, un segundo propósito clave:
        // le da a este subárbol una identidad concreta en el árbol de
        // render que se puede "fotografiar" más adelante. Es exactamente lo
        // que hace [AvatarCreatorController.save] a través de
        // `previewBoundaryKey`: le pide a este `RepaintBoundary` específico
        // que convierta lo que tiene pintado en una imagen PNG. Al envolver
        // solo el círculo (no el lavado pálido de alrededor), la imagen
        // guardada es exactamente "el avatar", sin el fondo decorativo de
        // la pantalla.
        child: RepaintBoundary(
          key: controller.previewBoundaryKey,
          child: SizedBox(
            width: _circleDiameter,
            height: _circleDiameter,
            // `Stack` dibuja a todos sus hijos unos encima de otros, en el
            // mismo espacio. `clipBehavior: Clip.none` deja que una capa más
            // ancha que el círculo (por ejemplo, un accesorio grande) pueda
            // sobresalir un poco de él en pantalla en vez de recortarse en
            // seco — tal como lo muestra la especificación de diseño. Eso
            // no afecta lo que se guarda: `toImage()` solo captura el
            // tamaño de este `SizedBox` (ver comentario de arriba).
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // El círculo de fondo, con el color sólido elegido por el
                // usuario — el equivalente visual a un `CircleAvatar` sin
                // imagen, solo con color.
                CircleAvatar(
                  radius: _circleDiameter / 2,
                  backgroundColor: backgroundColor,
                ),
                // Las capas ilustradas seleccionadas, encima del círculo, en
                // el orden dado por `controller.layerAssetPaths` (que a su
                // vez respeta el orden del catálogo — ver
                // [AvatarLayerCategory] y
                // [AvatarCreatorController.layerAssetPaths]).
                SizedBox(
                  width: _circleDiameter,
                  height: _circleDiameter,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      for (final assetPath in controller.layerAssetPaths)
                        SvgPicture.asset(
                          assetPath,
                          // `package: 'avatar_flutter'` le dice a
                          // `flutter_svg` que el asset vive dentro de este
                          // paquete (en su propia carpeta `assets/`), no en
                          // la app que lo consume. Es necesario porque los
                          // assets declarados en el `pubspec.yaml` de un
                          // paquete no son automáticamente visibles para la
                          // app anfitriona salvo que se indique
                          // explícitamente de qué paquete vienen.
                          package: 'avatar_flutter',
                          fit: BoxFit.contain,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
