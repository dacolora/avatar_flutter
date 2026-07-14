import 'package:bds_mobile/bds_tokens/bds_tokens.dart';
import 'package:flutter/material.dart';

import '../models/avatar_layer_category.dart';
import 'avatar_selectable_thumbnail.dart';

/// #8 (Elementos seleccionables — Grid): cuadrícula de opciones ilustradas.
/// Máximo 10 items según la especificación (Face/Hair/Body/Extra).
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

  final AvatarLayerCategory category;
  final String? selectedOptionId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: BdsSpacing.SPACE_S_1),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: category.options.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: BdsSpacing.SPACE_S_1,
          crossAxisSpacing: BdsSpacing.SPACE_S_1,
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
