import 'package:flutter/material.dart';

import '../models/avatar_option.dart';
import 'avatar_selectable_thumbnail.dart';

/// Cuadrícula de opciones ilustradas (#8 "Elementos seleccionables — Grid"
/// de la especificación). Se usa tanto para categorías simples de una sola
/// cuadrícula (Vestuario, Accesorios, Color de fondo) como para la mitad
/// "forma" de una categoría de tipo [AvatarCategoryKind.layerWithColor]
/// (Cabello, Rostro), que además muestra una fila de color encima (ver
/// [AvatarOptionRow]).
///
/// Recibe directamente la lista de [options] a mostrar (no una
/// [AvatarLayerCategory] completa): así este widget no necesita saber nada
/// sobre categorías, fondo, ni filas de color — solo sabe dibujar y
/// seleccionar opciones. Quien lo usa ([AvatarCreatorScreen]) decide si esas
/// opciones son `category.options` (la cuadrícula normal) o
/// `category.colorOptions` en algún otro contexto.
///
/// Según la especificación de diseño, admite como máximo 10 opciones.
class AvatarOptionGrid extends StatelessWidget {
  AvatarOptionGrid({
    required this.options,
    required this.selectedOptionId,
    required this.onSelected,
    this.resolveAssetPath,
    super.key,
  }) : assert(
          options.length <= 10,
          'AvatarOptionGrid admite máximo 10 opciones por especificación',
        );

  /// Opciones a mostrar, en el orden en que deben aparecer en la cuadrícula.
  final List<AvatarOption> options;

  /// Id de la opción actualmente seleccionada, o `null` si ninguna coincide.
  final String? selectedOptionId;

  /// Se invoca con el id de la opción que el usuario acaba de tocar.
  final ValueChanged<String> onSelected;

  /// Calcula la ruta real del SVG de cada opción, en vez de usar
  /// `option.assetPath` directamente. Se usa cuando la categoría activa
  /// tiene una fila de color asociada (ver
  /// [AvatarLayerCategory.colorOptions]): ahí, el archivo real de cada forma
  /// depende también del color elegido en esa fila (por ejemplo,
  /// `AvatarLayerCategory.resolveAssetPath(option, colorActual)`), así que
  /// **todas** las miniaturas de la cuadrícula —no solo la seleccionada—
  /// deben recalcular su ruta cada vez que el color cambia. Se deja en
  /// `null` para categorías sin fila de color (Vestuario, Accesorios, Color
  /// de fondo), donde `option.assetPath` ya es la ruta final.
  final String Function(AvatarOption option)? resolveAssetPath;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      // `GridView.builder` construye únicamente los elementos visibles (más
      // un pequeño margen), en vez de crear los widgets de las 10 opciones
      // de una sola vez sin importar si están en pantalla. Como aquí como
      // mucho hay 10 opciones, la diferencia de rendimiento es mínima, pero
      // es el patrón estándar de Flutter para listas/cuadrículas.
      //
      // `shrinkWrap: true` + `NeverScrollableScrollPhysics()` hacen que esta
      // cuadrícula ocupe solo el alto que necesitan sus propios elementos
      // (en vez de intentar expandirse) y que no tenga su propio scroll
      // independiente — el scroll de toda la pantalla lo maneja el
      // `SingleChildScrollView` de [AvatarCreatorScreen].
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: options.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          // 3 columnas, tal como pidió el equipo de diseño (no 5, que era el
          // valor con el que se empezó a construir el widget): con miniaturas
          // cuadradas y más grandes se ven mejor 3 por fila que 5.
          crossAxisCount: 3,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
        ),
        itemBuilder: (context, index) {
          final option = options[index];
          return AvatarSelectableThumbnail(
            option: option,
            isSelected: option.id == selectedOptionId,
            onTap: () => onSelected(option.id),
            assetPathOverride: resolveAssetPath?.call(option),
          );
        },
      ),
    );
  }
}
