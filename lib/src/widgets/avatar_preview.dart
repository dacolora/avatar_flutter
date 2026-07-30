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
/// rectángulo del preview, el fondo no es blanco: es un tono **pálido** del
/// mismo color de fondo elegido (una mezcla con blanco, no transparencia
/// real — ver la nota en [build] sobre por qué) que separa visualmente "el
/// avatar" del resto de la pantalla sin usar un color distinto ni un borde.
///
/// Este widget no controla su propio tamaño: lo recibe desde afuera con
/// [expandedHeight], [collapsedHeight] y [expansion] (ver
/// [AvatarCreatorScreen], que lo envuelve en un `SliverPersistentHeader` que
/// encoge el preview a medida que el usuario hace scroll hacia abajo, sin
/// llegar nunca a ocultarlo del todo, y lo vuelve a expandir al volver
/// arriba). Los dos altos vienen, en última instancia, de
/// [AvatarCreatorConfig.previewExpandedHeight] y
/// [AvatarCreatorConfig.previewCollapsedHeight] — el canal puede
/// personalizarlos; esta clase solo sabe interpolar entre los valores que le
/// dan, no tiene una opinión propia sobre cuáles deberían ser.
class AvatarPreview extends StatelessWidget {
  const AvatarPreview({
    required this.expandedHeight,
    required this.collapsedHeight,
    this.expansion = 1,
    super.key,
  });

  /// Alto del preview totalmente expandido (al tope de la pantalla). Ver
  /// [AvatarCreatorConfig.previewExpandedHeight].
  final double expandedHeight;

  /// Alto mínimo del preview una vez encogido del todo por el scroll: nunca
  /// desaparece, solo se reduce hasta este tamaño. Ver
  /// [AvatarCreatorConfig.previewCollapsedHeight].
  final double collapsedHeight;

  /// Qué tan "expandido" está el preview: `1` es [expandedHeight], `0` es
  /// [collapsedHeight], y cualquier valor intermedio interpola linealmente
  /// entre ambos — así el preview puede seguir el scroll fielmente, sin
  /// saltos, en vez de animar hacia un tamaño fijo.
  final double expansion;

  /// Proporción entre el diámetro del círculo y el alto total del preview
  /// (en cualquiera de los dos extremos, expandido o encogido): con el
  /// valor por defecto de altos (249 expandido, 160 encogido) da un círculo
  /// de 200 y 128 respectivamente. Se expresa como proporción, no como un
  /// tamaño fijo, para que el círculo se vea bien proporcionado sin importar
  /// qué altos configure el canal.
  static const double _circleToHeightRatio = 0.8;

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
    final height =
        lerpDouble(collapsedHeight, expandedHeight, clampedExpansion);
    final circleDiameter = height * _circleToHeightRatio;

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
        // El lavado pálido "fuera" del círculo: en vez de aplicar
        // opacidad real (`backgroundColor.withOpacity(...)`, que dejaría
        // ver — literalmente — lo que hay detrás), se mezcla el color de
        // fondo con blanco en un 25%. El resultado se ve igual de "pálido"
        // que la opacidad (matemáticamente es el mismo color, ya que este
        // preview siempre estuvo sobre un fondo blanco), pero es un color
        // sólido y opaco. Eso importa porque este preview vive en un
        // `SliverPersistentHeader` fijo, con contenido scrolleable
        // pasando por detrás: con opacidad real, ese contenido se vería
        // "a través" del preview en vez de quedar tapado por él.
        color: Color.lerp(Colors.white, backgroundColor, 0.25),
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
              // `ClipOval` recorta todo lo que se dibuje dentro de este
              // `SizedBox` al círculo del avatar: sin esto, una capa cuyo
              // dibujo llegue hasta las esquinas de su lienzo cuadrado
              // (por ejemplo, los hombros de Vestuario) sobresaldría
              // visualmente del círculo en vez de quedar contenida en él.
              // Como envuelve al mismo `SizedBox` que captura `toImage()`
              // (ver comentario de arriba), lo guardado queda recortado
              // igual que lo que se ve en pantalla.
              child: ClipOval(
                child: Stack(
                  alignment: Alignment.center,
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
                          for (final layer in controller.layerAssetPaths)
                            SvgPicture.asset(
                              layer.path,
                              // `package` le dice a `flutter_svg` en qué
                              // paquete buscar el asset — necesario porque
                              // los assets declarados en el `pubspec.yaml`
                              // de un paquete no son automáticamente
                              // visibles para la app anfitriona salvo que se
                              // indique explícitamente de qué paquete
                              // vienen. Viene de
                              // `AvatarOption.assetPackage`: `'avatar_flutter'`
                              // para las categorías del catálogo oficial,
                              // `null` para una categoría que el propio
                              // canal haya agregado (su SVG vive en el
                              // bundle de su propia app).
                              package: layer.package,
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
      ),
    );
  }
}

/// Interpola linealmente entre [a] y [b], igual que `lerpDouble` de
/// `dart:ui`, pero sin necesitar ese import solo para esta cuenta simple.
double lerpDouble(double a, double b, double t) => a + (b - a) * t;
