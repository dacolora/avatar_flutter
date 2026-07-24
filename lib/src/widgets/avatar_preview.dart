import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../controllers/avatar_creator_scope.dart';

/// El "lienzo" del avatar: combina el color de fondo (#2 Background) con las
/// capas ilustradas seleccionadas (#3 Preview), apiladas una encima de otra,
/// y se actualiza en tiempo real cada vez que el usuario cambia una
/// selección.
///
/// Según la especificación de diseño, el avatar en sí (el color de fondo +
/// las capas) vive dentro de un **círculo** (como un [CircleAvatar])
/// centrado en el área de preview. Fuera de ese círculo, pero dentro del
/// rectángulo del preview, el fondo no es blanco ni transparente: es el
/// mismo color de fondo elegido, pero con baja opacidad — un lavado pálido
/// que separa visualmente "el avatar" del resto de la pantalla sin usar un
/// color distinto ni un borde.
///
/// Este widget no controla su propio tamaño: lo recibe desde afuera con
/// [expansion] (ver [AvatarCreatorScreen], que lo envuelve en un
/// `SliverPersistentHeader` que encoge el preview a medida que el usuario
/// hace scroll hacia abajo, sin llegar nunca a ocultarlo del todo, y lo
/// vuelve a expandir al volver arriba).
class AvatarPreview extends StatelessWidget {
  const AvatarPreview({this.expansion = 1, super.key});

  /// Qué tan "expandido" está el preview: `1` es el tamaño completo
  /// ([expandedHeight]/[expandedCircleDiameter]), `0` es el tamaño mínimo
  /// ([collapsedHeight]/[collapsedCircleDiameter]), y cualquier valor
  /// intermedio interpola linealmente entre ambos — así el preview puede
  /// seguir el scroll fielmente, sin saltos, en vez de animar hacia un
  /// tamaño fijo.
  final double expansion;

  /// Alto del preview totalmente expandido (al tope de la pantalla).
  static const double expandedHeight = 249;

  /// Alto mínimo del preview una vez encogido del todo: nunca desaparece
  /// por completo, solo se reduce hasta este tamaño (ver la clase 1 del
  /// comportamiento de scroll pedido: "el preview no desaparece del todo").
  static const double collapsedHeight = 96;

  static const double _expandedCircleDiameter = 200;
  static const double _collapsedCircleDiameter = 64;

  @override
  Widget build(BuildContext context) {
    // `AvatarCreatorScope.of(context)` suscribe a este widget al
    // `AvatarCreatorController` expuesto más arriba en el árbol por
    // `AvatarCreatorScreen`. Cada vez que el controlador llama a
    // `notifyListeners()` — por ejemplo, al seleccionar una opción nueva —
    // este widget completo se reconstruye con los valores más recientes.
    final controller = AvatarCreatorScope.of(context);
    final backgroundColor = controller.backgroundColor;

    final clampedExpansion = expansion.clamp(0.0, 1.0);
    final height = lerpDouble(collapsedHeight, expandedHeight, clampedExpansion);
    final circleDiameter = lerpDouble(
      _collapsedCircleDiameter,
      _expandedCircleDiameter,
      clampedExpansion,
    );

    // El alto y el diámetro del círculo se fijan directamente a partir de
    // `expansion` (sin `AnimatedContainer`/`AnimatedSize`): como
    // `expansion` cambia en cada frame mientras el usuario hace scroll,
    // animar esa transición produciría un desfase entre el dedo y el
    // preview (el tamaño "persiguiendo" al scroll en vez de seguirlo al
    // instante). El color sí se anima aparte, más abajo, porque ese cambio
    // es discreto (el usuario elige un color nuevo), no continuo.
    return SizedBox(
      width: double.infinity,
      height: height,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        // El lavado pálido "fuera" del círculo: el mismo color, pero con
        // solo un 25% de opacidad — por eso se ve como un tono
        // suave/difuminado del color de fondo en vez del color sólido que
        // sí lleva el círculo.
        color: backgroundColor.withOpacity(0.25),
        child: Center(
          // `RepaintBoundary` aísla esta parte del árbol para que Flutter
          // pueda redibujarla de forma independiente del resto de la
          // pantalla — pero aquí cumple, además, un segundo propósito
          // clave: le da a este subárbol una identidad concreta en el
          // árbol de render que se puede "fotografiar" más adelante. Es
          // exactamente lo que hace [AvatarCreatorController.save] a
          // través de `previewBoundaryKey`: le pide a este
          // `RepaintBoundary` específico que convierta lo que tiene
          // pintado en una imagen PNG. Al envolver solo el círculo (no el
          // lavado pálido de alrededor), la imagen guardada es exactamente
          // "el avatar", sin el fondo decorativo de la pantalla — y, como
          // el `SliverPersistentHeader` que envuelve a este widget lo
          // mantiene siempre montado (por ser `pinned: true`), da igual en
          // qué punto del scroll (ni siquiera qué tan encogido) esté el
          // preview al momento de guardar.
          child: RepaintBoundary(
            key: controller.previewBoundaryKey,
            child: SizedBox(
              width: circleDiameter,
              height: circleDiameter,
              // `Stack` dibuja a todos sus hijos unos encima de otros, en
              // el mismo espacio. `clipBehavior: Clip.none` deja que una
              // capa más ancha que el círculo (por ejemplo, un accesorio
              // grande) pueda sobresalir un poco de él en pantalla en vez
              // de recortarse en seco — tal como lo muestra la
              // especificación de diseño. Eso no afecta lo que se guarda:
              // `toImage()` solo captura el tamaño de este `SizedBox` (ver
              // comentario de arriba).
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // El círculo de fondo, con el color sólido elegido por
                  // el usuario — el equivalente visual a un `CircleAvatar`
                  // sin imagen, solo con color.
                  CircleAvatar(
                    radius: circleDiameter / 2,
                    backgroundColor: backgroundColor,
                  ),
                  // Las capas ilustradas seleccionadas, encima del
                  // círculo, en el orden dado por
                  // `controller.layerAssetPaths` (que a su vez respeta el
                  // orden del catálogo — ver [AvatarLayerCategory] y
                  // [AvatarCreatorController.layerAssetPaths]).
                  SizedBox(
                    width: circleDiameter,
                    height: circleDiameter,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        for (final assetPath in controller.layerAssetPaths)
                          SvgPicture.asset(
                            assetPath,
                            // `package: 'avatar_flutter'` le dice a
                            // `flutter_svg` que el asset vive dentro de
                            // este paquete (en su propia carpeta
                            // `assets/`), no en la app que lo consume. Es
                            // necesario porque los assets declarados en el
                            // `pubspec.yaml` de un paquete no son
                            // automáticamente visibles para la app
                            // anfitriona salvo que se indique
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
      ),
    );
  }
}

/// Interpola linealmente entre [a] y [b], igual que `lerpDouble` de
/// `dart:ui`, pero sin necesitar ese import solo para esta cuenta simple.
double lerpDouble(double a, double b, double t) => a + (b - a) * t;
