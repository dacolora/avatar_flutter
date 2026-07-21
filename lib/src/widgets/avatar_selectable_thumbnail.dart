import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/avatar_option.dart';

/// Miniatura seleccionable individual: el widget visual de "un cuadro que se
/// puede tocar", reutilizado tanto por [AvatarOptionRow] (opciones de color)
/// como por [AvatarOptionGrid] (opciones ilustradas).
///
/// Es **cuadrada** (no circular) y con esquinas redondeadas, según la
/// especificación de diseño final: cuando el usuario tocó una opción
/// circular, pequeña, con muchas columnas, el equipo de diseño pidió
/// explícitamente cuadrados más grandes con máximo 3 por fila (ver
/// [AvatarOptionGrid]) — este widget es el que materializa esa forma.
///
/// Al recibir un [AvatarOption], no necesita saber si es una opción
/// ilustrada o de color: simplemente revisa `option.color` — si no es
/// `null`, pinta un cuadro de ese color; si es `null`, asume que hay un
/// `option.assetPath` (ver la garantía documentada en [AvatarOption]) y
/// dibuja el SVG correspondiente.
class AvatarSelectableThumbnail extends StatelessWidget {
  const AvatarSelectableThumbnail({
    required this.option,
    required this.isSelected,
    required this.onTap,
    this.size,
    super.key,
  });

  /// La opción que esta miniatura representa (ilustrada o de color).
  final AvatarOption option;

  /// Si `true`, se dibuja el borde de selección alrededor de la miniatura.
  final bool isSelected;

  /// Se invoca cuando el usuario toca esta miniatura.
  final VoidCallback onTap;

  /// Lado del cuadrado, en píxeles lógicos. Si se deja en `null` (el caso de
  /// [AvatarOptionGrid], donde cada celda de la cuadrícula ya define su
  /// propio tamaño), la miniatura simplemente ocupa todo el ancho que le dé
  /// su widget padre, manteniendo siempre una relación de aspecto 1:1 (ver
  /// el uso de [AspectRatio] más abajo).
  final double? size;

  static const Color _selectedBorderColor = Color(0xFF1B1B1B);
  static const BorderRadius _radius = BorderRadius.all(Radius.circular(24));
  static const BorderRadius _innerRadius =
      BorderRadius.all(Radius.circular(16));

  @override
  Widget build(BuildContext context) {
    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: _radius,
        // El borde solo se pinta (con el color oscuro de selección) cuando
        // `isSelected` es verdadero; en caso contrario se usa
        // `Colors.transparent`, así el espacio reservado para el borde no
        // cambia el tamaño total del widget al seleccionar/deseleccionar
        // (evita un "salto" visual).
        border: Border.all(
          color: isSelected ? _selectedBorderColor : Colors.transparent,
          width: 2,
        ),
      ),
      // `ClipRRect` recorta a su hijo con esquinas redondeadas — sin esto,
      // el `ColoredBox`/`SvgPicture` de adentro se dibujaría como un
      // rectángulo de esquinas rectas, ignorando `_innerRadius`.
      child: ClipRRect(
        borderRadius: _innerRadius,
        child: option.color != null
            ? ColoredBox(color: option.color!)
            : ColoredBox(
                color: const Color(0xFFF2F2F3),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: SvgPicture.asset(
                    option.assetPath!,
                    package: 'avatar_flutter',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
      ),
    );

    return Semantics(
      button: true,
      selected: isSelected,
      label: option.semanticLabel,
      child: GestureDetector(
        onTap: onTap,
        // Si `size` fue especificado, se envuelve el contenido en un
        // `SizedBox` de ese tamaño exacto; si no, se usa `AspectRatio(1)`
        // para que el widget mida "todo el ancho disponible x esa misma
        // medida de alto", manteniéndose siempre cuadrado sin necesidad de
        // conocer un tamaño fijo de antemano.
        child: size != null
            ? SizedBox(width: size, height: size, child: content)
            : AspectRatio(aspectRatio: 1, child: content),
      ),
    );
  }
}
