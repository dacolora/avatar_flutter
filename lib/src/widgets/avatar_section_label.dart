import 'package:bds_mobile/bds_tokens/bds_tokens.dart';
import 'package:flutter/material.dart';

/// #6 (Label): título de la sección de opciones de la categoría activa.
/// Parametrizable vía [AvatarLayerCategory.label] (viene con nombre por
/// defecto para cada categoría, ver "Reglas de uso").
class AvatarSectionLabel extends StatelessWidget {
  const AvatarSectionLabel({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        BdsSpacing.SPACE_S_1,
        BdsSpacing.SPACE_S_1,
        BdsSpacing.SPACE_S_1,
        BdsSpacing.SPACE_XS_3,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleSmall,
      ),
    );
  }
}
