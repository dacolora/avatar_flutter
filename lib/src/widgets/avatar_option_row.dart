import 'package:flutter/material.dart';

import '../models/avatar_layer_category.dart';
import 'avatar_selectable_thumbnail.dart';

/// Fila horizontal de opciones (#7 "Elementos seleccionables — Row" de la
/// especificación). Se usa para categorías de tipo
/// [AvatarCategoryKind.colorRow] (hoy, únicamente "Color de fondo"), que
/// según la especificación de diseño admiten como máximo 5 opciones.
class AvatarOptionRow extends StatelessWidget {
  AvatarOptionRow({
    required this.category,
    required this.selectedOptionId,
    required this.onSelected,
    super.key,
  }) : assert(
          category.options.length <= 5,
          'AvatarOptionRow admite máximo 5 opciones por especificación',
        );

  /// Categoría cuyas opciones se están mostrando (por ejemplo, "Color de
  /// fondo").
  final AvatarLayerCategory category;

  /// Id de la opción actualmente seleccionada dentro de [category], o `null`
  /// si ninguna coincide.
  final String? selectedOptionId;

  /// Se invoca con el id de la opción que el usuario acaba de tocar.
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          for (int index = 0; index < category.options.length; index++) ...[
            // Cada miniatura se envuelve en `Expanded` para que las opciones
            // repartan el ancho disponible en partes iguales entre ellas
            // (a diferencia de la cuadrícula, aquí el número de columnas no
            // es fijo: puede haber de 1 a 5 opciones y todas deben repartirse
            // el mismo ancho total).
            Expanded(
              child: AvatarSelectableThumbnail(
                option: category.options[index],
                isSelected: category.options[index].id == selectedOptionId,
                onTap: () => onSelected(category.options[index].id),
              ),
            ),
            // Se agrega separación entre miniaturas, pero no después de la
            // última (de ahí el `if`), para no dejar un espacio extra pegado
            // al borde derecho.
            if (index != category.options.length - 1) const SizedBox(width: 16),
          ],
        ],
      ),
    );
  }
}
