import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

/// Una opción seleccionable dentro de una [AvatarLayerCategory].
///
/// Una opción representa, según el tipo de categoría, un asset SVG de capa
/// (Face/Hair/Body/Extra) o un color sólido (Color de fondo).
class AvatarOption extends Equatable {
  const AvatarOption.layer({
    required this.id,
    required this.assetPath,
    this.semanticLabel,
  }) : color = null;

  const AvatarOption.color({
    required this.id,
    required this.color,
    this.semanticLabel,
  }) : assetPath = null;

  /// Identificador único de la opción dentro de su categoría.
  final String id;

  /// Ruta del asset SVG de la capa. Solo aplica para categorías tipo [AvatarCategoryKind.layer].
  final String? assetPath;

  /// Color sólido de la opción. Solo aplica para categorías tipo [AvatarCategoryKind.colorRow].
  final Color? color;

  /// Label de accesibilidad para lectores de pantalla.
  final String? semanticLabel;

  @override
  List<Object?> get props => [id, assetPath, color];
}
