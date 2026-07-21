import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/avatar_creator_controller.dart';

/// #4 (Categorías) + #5 (Card container): tira horizontal de icon-buttons,
/// uno por categoría, solo uno activo a la vez. Full width, borde inferior
/// de 1px y gradiente en los bordes para pantallas pequeñas donde el
/// contenido desborda.
class AvatarCategoryTabs extends StatelessWidget {
  const AvatarCategoryTabs({super.key});

  static const Color _dividerColor = Color(0xFFD9DADD); // token border/default

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AvatarCreatorController>();

    return Container(
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
            horizontal: 16,
            vertical: 8,
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
                const SizedBox(width: 24),
              ],
            ],
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
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected ? scheme.primaryContainer : Colors.transparent,
          ),
          child: Icon(icon, color: isSelected ? scheme.primary : scheme.onSurfaceVariant),
        ),
      ),
    );
  }
}
