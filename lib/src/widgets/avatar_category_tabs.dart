import 'package:bds_mobile/atoms/atoms.dart';
import 'package:bds_mobile/bds_tokens/bds_tokens.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/avatar_creator_controller.dart';

/// #4 (Categorías) + #5 (Card container): tira horizontal de
/// `BcIconButton.ghost`, uno por categoría, solo uno activo a la vez.
/// Full width, borde inferior de 1px y gradiente en los bordes para
/// pantallas pequeñas donde el contenido desborda.
class AvatarCategoryTabs extends StatelessWidget {
  const AvatarCategoryTabs({super.key});

  static const Color _dividerColor = Color(0xFFD9DADD); // token border/default

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AvatarCreatorController>();

    return BcCardContainer(
      strokeStyle: BcStrokeCardContainerStyle.None,
      padding: EdgeInsets.zero,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: _dividerColor, width: 1)),
        ),
        child: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Colors.transparent,
              Colors.white,
              Colors.white,
              Colors.transparent,
            ],
            stops: [0, 0.03, 0.97, 1],
          ).createShader(bounds),
          blendMode: BlendMode.dstIn,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: BdsSpacing.SPACE_S_1,
              vertical: BdsSpacing.SPACE_XS_3,
            ),
            child: Row(
              children: [
                for (final category in controller.categories) ...[
                  _CategoryTabButton(
                    isSelected: category.id == controller.activeCategoryId,
                    icon: category.icon,
                    label: category.label,
                    onPressed: () => controller.selectCategory(category.id),
                  ),
                  const SizedBox(width: BdsSpacing.SPACE_S_2),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryTabButton extends StatelessWidget {
  const _CategoryTabButton({
    required this.isSelected,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final bool isSelected;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return BcIconButton.ghost(
      // `BcIconButton.ghost` only syncs `isSelected` from its parent on the
      // very first build (it manages the pressed state internally after
      // that), so the key is forced to change whenever the externally-driven
      // selection changes to guarantee the active tab always re-renders.
      key: ValueKey('avatar-category-tab-$label-$isSelected'),
      icon: icon,
      isSelected: isSelected,
      ghostSize: BcGhostIconButtonSize.XLarge,
      selectedAccessibility: '$label seleccionado',
      notSelectedAccessibility: label,
      onPressed: onPressed,
    );
  }
}
