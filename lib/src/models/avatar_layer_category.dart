import 'package:flutter/widgets.dart';

import 'avatar_option.dart';

/// Determina cómo se renderiza y selecciona una categoría de personalización.
enum AvatarCategoryKind {
  /// Capa SVG que se apila sobre el preview (Face, Hair, Body, Extra).
  /// Se presenta en un [AvatarOptionGrid] (máx. 10 items, ver especificación).
  layer,

  /// Categoría de color sólido (ej. Color de fondo).
  /// Se presenta en un [AvatarOptionRow] (máx. 5 items, ver especificación).
  colorRow,
}

/// Una categoría de personalización del avatar (uno de los tabs de #4/#5 en
/// la especificación). El orden de las categorías dentro del catálogo define
/// el orden de navegación y NO es configurable por el canal (ver "Reglas de uso").
class AvatarLayerCategory {
  const AvatarLayerCategory({
    required this.id,
    required this.label,
    required this.icon,
    required this.kind,
    required this.options,
  }) : assert(options.length > 0, 'Una categoría debe tener al menos una opción');

  /// Identificador único, estable, de la categoría (ej. 'face', 'hair').
  final String id;

  /// Título de la sección mostrado sobre las opciones (#6). Parametrizable.
  final String label;

  /// Icono del tab de navegación (#4/#5). Configurable por el canal.
  final IconData icon;

  final AvatarCategoryKind kind;

  /// Opciones disponibles para esta categoría, en orden de presentación.
  /// La opción `options.first` es la preseleccionada por defecto al
  /// crear un avatar nuevo (ver "Reglas de uso").
  final List<AvatarOption> options;

  AvatarOption optionById(String optionId) =>
      options.firstWhere((option) => option.id == optionId, orElse: () => options.first);
}
