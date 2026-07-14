import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/avatar_option.dart';

/// Miniatura seleccionable usada tanto por [AvatarOptionRow] (colores) como
/// por [AvatarOptionGrid] (capas ilustradas). No es un `BcIconButton` porque
/// su contenido no es un `IconData` (es un SVG o un color sólido); replica el
/// tratamiento de selección (borde) del "app-icon-button outline" de la
/// especificación usando tokens del SDB.
class AvatarSelectableThumbnail extends StatelessWidget {
  const AvatarSelectableThumbnail({
    required this.option,
    required this.isSelected,
    required this.onTap,
    this.size = 56,
    super.key,
  });

  final AvatarOption option;
  final bool isSelected;
  final VoidCallback onTap;
  final double size;

  static const Color _selectedBorderColor = Color(0xFF1B1B1B);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: option.semanticLabel,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: size,
          height: size,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? _selectedBorderColor : Colors.transparent,
              width: 2,
            ),
          ),
          child: ClipOval(
            child: option.color != null
                ? ColoredBox(color: option.color!)
                : ColoredBox(
                    color: const Color(0xFFF2F2F3),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: SvgPicture.asset(
                        option.assetPath!,
                        package: 'avatar_flutter',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
