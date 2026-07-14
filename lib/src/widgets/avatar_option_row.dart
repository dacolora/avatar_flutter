import 'package:bds_mobile/bds_tokens/bds_tokens.dart';
import 'package:flutter/material.dart';

import '../models/avatar_layer_category.dart';
import 'avatar_selectable_thumbnail.dart';

/// #7 (Elementos seleccionables — Row): fila horizontal de opciones.
/// Máximo 5 items según la especificación (ej. "Color de fondo").
class AvatarOptionRow extends StatelessWidget {
  const AvatarOptionRow({
    required this.category,
    required this.selectedOptionId,
    required this.onSelected,
    super.key,
  }) : assert(
          category.options.length <= 5,
          'AvatarOptionRow admite máximo 5 opciones por especificación',
        );

  final AvatarLayerCategory category;
  final String? selectedOptionId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: BdsSpacing.SPACE_S_1),
      child: Row(
        children: [
          for (int index = 0; index < category.options.length; index++) ...[
            AvatarSelectableThumbnail(
              option: category.options[index],
              isSelected: category.options[index].id == selectedOptionId,
              onTap: () => onSelected(category.options[index].id),
            ),
            if (index != category.options.length - 1)
              const SizedBox(width: BdsSpacing.SPACE_S_1),
          ],
        ],
      ),
    );
  }
}
