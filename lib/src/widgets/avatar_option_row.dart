import 'package:flutter/material.dart';

import '../models/avatar_option.dart';
import 'avatar_selectable_thumbnail.dart';

/// Fila horizontal de opciones (#7 "Elementos seleccionables — Row" de la
/// especificación). Se usa para las filas de color de las categorías de
/// tipo [AvatarCategoryKind.layerWithColor] (Cabello, Rostro).
///
/// Igual que [AvatarOptionGrid], recibe directamente la lista de [options] a
/// mostrar en vez de una [AvatarLayerCategory] completa — en este caso, casi
/// siempre `category.colorOptions` — para no acoplarse a ningún concepto de
/// categoría, fondo o cuadrícula.
///
/// Según la especificación de diseño, admite como máximo 5 opciones.
class AvatarOptionRow extends StatelessWidget {
  AvatarOptionRow({
    required this.options,
    required this.selectedOptionId,
    required this.onSelected,
    super.key,
  }) : assert(
          options.length <= 5,
          'AvatarOptionRow admite máximo 5 opciones por especificación',
        );

  /// Opciones a mostrar, en el orden en que deben aparecer en la fila.
  final List<AvatarOption> options;

  /// Id de la opción actualmente seleccionada, o `null` si ninguna coincide.
  final String? selectedOptionId;

  /// Se invoca con el id de la opción que el usuario acaba de tocar.
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          for (int index = 0; index < options.length; index++) ...[
            // Cada miniatura se envuelve en `Expanded` para que las opciones
            // repartan el ancho disponible en partes iguales entre ellas
            // (a diferencia de la cuadrícula, aquí el número de columnas no
            // es fijo: puede haber de 1 a 5 opciones y todas deben repartirse
            // el mismo ancho total).
            Expanded(
              child: AvatarSelectableThumbnail(
                option: options[index],
                isSelected: options[index].id == selectedOptionId,
                onTap: () => onSelected(options[index].id),
              ),
            ),
            // Se agrega separación entre miniaturas, pero no después de la
            // última (de ahí el `if`), para no dejar un espacio extra pegado
            // al borde derecho.
            if (index != options.length - 1) const SizedBox(width: 16),
          ],
        ],
      ),
    );
  }
}
