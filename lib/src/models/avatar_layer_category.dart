import 'package:flutter/widgets.dart';

import 'avatar_option.dart';

/// Determina cómo se renderiza y se selecciona una categoría de
/// personalización: como cuadrícula de capas ilustradas o como fila de
/// colores.
///
/// Un `enum` en Dart es simplemente una lista cerrada de valores posibles
/// (aquí solo hay dos: [layer] o [colorRow]). Se usa en vez de, por ejemplo,
/// un `String` o un `bool`, para que el compilador te obligue a manejar
/// todos los casos posibles (si más adelante se agrega un tercer valor, el
/// analizador de Dart avisará en cada `switch` que no lo contemple) y para
/// que el código sea auto-descriptivo: `category.kind == AvatarCategoryKind.layer`
/// se entiende sin tener que adivinar qué significa un `true`/`false` o un
/// string mágico como `'layer'`.
enum AvatarCategoryKind {
  /// Capa SVG que se apila sobre el preview del avatar (por ejemplo Rostro,
  /// Cabello, Vestuario, Accesorios). Sus opciones se presentan en un
  /// [AvatarOptionGrid] (máximo 10 opciones, según la especificación de
  /// diseño).
  layer,

  /// Categoría de color sólido (por ejemplo, "Color de fondo"). Sus
  /// opciones se presentan en un [AvatarOptionRow] (máximo 5 opciones,
  /// según la especificación de diseño).
  colorRow,
}

/// Una categoría de personalización del avatar: es decir, uno de los tabs
/// que el usuario ve en la fila de categorías (por ejemplo "Rostro" o
/// "Color de fondo"), junto con la lista de opciones que ofrece.
///
/// El **orden** en que se listan las categorías dentro del catálogo (ver
/// [defaultAvatarCatalog]) determina dos cosas a la vez:
///
/// 1. El orden de los tabs de navegación que ve el usuario.
/// 2. El orden en que se apilan (z-index) las capas ilustradas en el
///    preview: la primera categoría de tipo [AvatarCategoryKind.layer]
///    del catálogo se dibuja más al fondo, y cada una siguiente se dibuja
///    encima de la anterior (ver [AvatarCreatorController.layerAssetPaths]).
///
/// Este orden **no es libre para el canal que consume el widget**: viene
/// definido por la especificación de diseño de Bancolombia y por eso el
/// catálogo por defecto vive dentro de esta librería
/// ([defaultAvatarCatalog]), no en la app que la embebe.
class AvatarLayerCategory {
  const AvatarLayerCategory({
    required this.id,
    required this.label,
    required this.icon,
    required this.kind,
    required this.options,
  }) : assert(options.length > 0, 'Una categoría debe tener al menos una opción');

  /// Identificador único y estable de la categoría (por ejemplo, `'face'`,
  /// `'hair'`). Se usa como llave en los mapas de selección (ver
  /// [AvatarSelection]) y no debería cambiar una vez publicado, porque
  /// selecciones guardadas por canales que ya usan la librería quedarían
  /// "huérfanas" (referenciando un id que ya no existe).
  final String id;

  /// Título de la sección que se muestra encima de las opciones cuando esta
  /// categoría está activa (ver [AvatarSectionLabel]). Es un `String` fijo
  /// definido en el catálogo, pensado para que el equipo de diseño controle
  /// exactamente qué texto se ve; no es algo que normalmente cambiaría el
  /// canal.
  final String label;

  /// Icono que se dibuja en el tab de navegación de esta categoría (ver
  /// [AvatarCategoryTabs]). Usa el tipo [IconData] de Flutter, el mismo que
  /// recibe cualquier widget `Icon(...)`.
  final IconData icon;

  /// Define si esta categoría se presenta como cuadrícula de capas
  /// ilustradas o como fila de colores. Ver [AvatarCategoryKind].
  final AvatarCategoryKind kind;

  /// Opciones disponibles para esta categoría, en el orden en que deben
  /// mostrarse. `options.first` es la opción preseleccionada por defecto
  /// cuando se crea un avatar nuevo (es decir, cuando el canal no pasa una
  /// selección inicial explícita), según las reglas de uso de la
  /// especificación.
  final List<AvatarOption> options;

  /// Busca la opción con id [optionId] dentro de esta categoría.
  ///
  /// Si no existe ninguna opción con ese id (por ejemplo, porque venía de
  /// una selección guardada previamente y esa opción fue eliminada del
  /// catálogo), en vez de lanzar una excepción se devuelve `options.first`
  /// como valor de respaldo seguro, para que la pantalla nunca se rompa por
  /// datos desactualizados.
  AvatarOption optionById(String optionId) =>
      options.firstWhere((option) => option.id == optionId, orElse: () => options.first);
}
