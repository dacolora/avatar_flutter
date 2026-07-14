import 'package:bds_mobile/bds_tokens/bds_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/avatar_option.dart';

/// Miniatura seleccionable usada tanto por [AvatarOptionRow] (colores) como
/// por [AvatarOptionGrid] (capas ilustradas). No es un `BcIconButton` porque
/// su contenido no es un `IconData` (es un SVG o un color sólido); replica el
/// tratamiento de selección (borde) del "app-icon-button outline" de la
/// especificación usando tokens del SDB. Cuadrada (no circular), según la
/// especificación de diseño.
class AvatarSelectableThumbnail extends StatelessWidget {
  const AvatarSelectableThumbnail({
    required this.option,
    required this.isSelected,
    required this.onTap,
    this.size,
    super.key,
  });

  final AvatarOption option;
  final bool isSelected;
  final VoidCallback onTap;

  /// Lado del cuadrado. Si es `null`, la miniatura ocupa todo el ancho que
  /// le dé su contenedor (ej. una celda de [AvatarOptionGrid]) manteniendo
  /// proporción 1:1.
  final double? size;

  static const Color _selectedBorderColor = Color(0xFF1B1B1B);
  static const BorderRadius _radius = BorderRadius.all(BdsBorderRadius.BORDER_RADIUS_4);
  static const BorderRadius _innerRadius = BorderRadius.all(BdsBorderRadius.BORDER_RADIUS_3);

  @override
  Widget build(BuildContext context) {
    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: _radius,
        border: Border.all(
          color: isSelected ? _selectedBorderColor : Colors.transparent,
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: _innerRadius,
        child: option.color != null
            ? ColoredBox(color: option.color!)
            : ColoredBox(
                color: const Color(0xFFF2F2F3),
                child: Padding(
                  padding: const EdgeInsets.all(BdsSpacing.SPACE_XS_3),
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
        child: size != null
            ? SizedBox(width: size, height: size, child: content)
            : AspectRatio(aspectRatio: 1, child: content),
      ),
    );
  }
}
