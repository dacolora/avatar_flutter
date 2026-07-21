import 'package:flutter/material.dart';

import '../models/avatar_layer_category.dart';
import 'avatar_selectable_thumbnail.dart';

/// Cuadrícula de opciones ilustradas (#8 "Elementos seleccionables — Grid"
/// de la especificación). Se usa para las categorías de tipo
/// [AvatarCategoryKind.layer] (Rostro, Cabello, Vestuario, Accesorios), que
/// según la especificación de diseño admiten como máximo 10 opciones cada
/// una.
class AvatarOptionGrid extends StatelessWidget {
  AvatarOptionGrid({
    required this.category,
    required this.selectedOptionId,
    required this.onSelected,
    super.key,
  }) : assert(
          category.options.length <= 10,
          'AvatarOptionGrid admite máximo 10 opciones por especificación',
        );

  /// Categoría cuyas opciones se están mostrando (por ejemplo, "Cabello").
  final AvatarLayerCategory category;

  /// Id de la opción actualmente seleccionada dentro de [category], o `null`
  /// si ninguna coincide (esto solo se usa para resaltar visualmente la
  /// opción elegida; no afecta qué opciones se muestran).
  final String? selectedOptionId;

  /// Se invoca con el id de la opción que el usuario acaba de tocar. Quien
  /// use este widget ([AvatarCreatorScreen]) conecta esto con
  /// [AvatarCreatorController.selectOption].
  final ValueChanged<String> onSelected;

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
        itemCount: category.options.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          // 3 columnas, tal como pidió el equipo de diseño (no 5, que era el
          // valor con el que se empezó a construir el widget): con miniaturas
          // cuadradas y más grandes se ven mejor 3 por fila que 5.
          crossAxisCount: 3,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
        ),
        itemBuilder: (context, index) {
          final option = category.options[index];
          return AvatarSelectableThumbnail(
            option: option,
            isSelected: option.id == selectedOptionId,
            onTap: () => onSelected(option.id),
          );
        },
      ),
    );
  }
}
