import 'package:flutter/widgets.dart';

import 'avatar_option.dart';

/// Determina cómo se renderiza y se selecciona una categoría de
/// personalización.
///
/// Un `enum` en Dart es simplemente una lista cerrada de valores posibles.
/// Se usa en vez de, por ejemplo, un `bool`, para que el código sea
/// auto-descriptivo (`category.kind == AvatarCategoryKind.layer` se entiende
/// sin adivinar qué significa un `true`/`false`) y para que el compilador
/// avise en cada `switch` si en el futuro se agrega un tercer valor.
enum AvatarCategoryKind {
  /// La categoría se presenta con una única cuadrícula
  /// ([AvatarOptionGrid], máximo 10 opciones). Sirve tanto para categorías
  /// de capas ilustradas (Vestuario, Accesorios) como para una categoría de
  /// colores sólidos sin selector de forma (Color de fondo) — a la
  /// cuadrícula no le importa si sus opciones son SVGs o colores, solo las
  /// dibuja (ver [AvatarSelectableThumbnail]).
  layer,

  /// La categoría combina **dos** selectores en la misma pantalla: primero
  /// una fila de colores ([AvatarOptionRow], máximo 5, ver [colorOptions])
  /// y debajo una cuadrícula de formas ilustradas ([AvatarOptionGrid],
  /// máximo 10, ver [AvatarLayerCategory.options]). El color elegido en la
  /// fila tiñe **todas** las formas de la cuadrícula (las seleccionadas y
  /// las que no), para que, por ejemplo, si el usuario elige "morado" en
  /// "Color del pelo", los 10 cortes de "Forma del pelo" se vean morados
  /// (ver [AvatarCreatorController.previewLayers] para cómo se aplica ese
  /// tinte). Hoy la usan Cabello y Rostro (tono de piel + expresión).
  layerWithColor,
}

/// Una categoría de personalización del avatar: uno de los tabs que el
/// usuario ve en la fila de categorías (por ejemplo "Cabello" o "Color de
/// fondo"), junto con las opciones que ofrece.
///
/// El **orden** en que se listan las categorías dentro del catálogo (ver
/// [defaultAvatarCatalog]) determina dos cosas a la vez:
///
/// 1. El orden de los tabs de navegación que ve el usuario.
/// 2. El orden en que se apilan (z-index) las capas ilustradas en el
///    preview: cada categoría que no sea la de fondo (ver [isBackground])
///    se dibuja encima de la anterior (ver
///    [AvatarCreatorController.previewLayers]).
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
    this.colorOptions,
    this.colorSectionLabel,
    this.shapeSectionLabel,
    this.isBackground = false,
  })  : assert(options.length > 0, 'Una categoría debe tener al menos una opción'),
        assert(
          kind == AvatarCategoryKind.layerWithColor ||
              (colorOptions == null && colorSectionLabel == null),
          'colorOptions/colorSectionLabel solo aplican a kind: layerWithColor',
        ),
        assert(
          kind != AvatarCategoryKind.layerWithColor ||
              (colorOptions != null && colorOptions.length > 0 && colorSectionLabel != null),
          'kind: layerWithColor requiere colorOptions (1 a 5 elementos) y colorSectionLabel',
        ),
        assert(
          !isBackground || kind == AvatarCategoryKind.layer,
          'La categoría de fondo no soporta kind: layerWithColor',
        );

  /// Identificador único y estable de la categoría (por ejemplo, `'face'`,
  /// `'hair'`). Se usa como llave en los mapas de selección (ver
  /// [AvatarSelection]) y no debería cambiar una vez publicado, porque
  /// selecciones guardadas por canales que ya usan la librería quedarían
  /// "huérfanas" (referenciando un id que ya no existe).
  final String id;

  /// Nombre de la categoría, usado como etiqueta accesible del tab de
  /// navegación (ver [AvatarCategoryTabs]) y, en categorías de tipo
  /// [AvatarCategoryKind.layer], también como título visible de la sección
  /// de opciones (ver [AvatarSectionLabel]). En categorías de tipo
  /// [AvatarCategoryKind.layerWithColor] el título visible lo dan en cambio
  /// [colorSectionLabel] y [shapeSectionLabel] — [label] ahí solo se usa
  /// para accesibilidad del tab.
  final String label;

  /// Icono que se dibuja en el tab de navegación de esta categoría (ver
  /// [AvatarCategoryTabs]). Usa el tipo [IconData] de Flutter, el mismo que
  /// recibe cualquier widget `Icon(...)`.
  final IconData icon;

  /// Define si esta categoría se presenta como una única cuadrícula o como
  /// fila de color + cuadrícula de forma combinadas. Ver
  /// [AvatarCategoryKind].
  final AvatarCategoryKind kind;

  /// Opciones de forma/ilustración (o de color, si es la categoría de
  /// fondo), en el orden en que deben mostrarse en la cuadrícula.
  /// `options.first` es la opción preseleccionada por defecto cuando se crea
  /// un avatar nuevo, según las reglas de uso de la especificación.
  final List<AvatarOption> options;

  /// Opciones de color mostradas en la fila superior, **solo** para
  /// categorías de tipo [AvatarCategoryKind.layerWithColor] (`null` en
  /// cualquier otro caso). El color elegido aquí no reemplaza ninguna de las
  /// [options]: se guarda como una selección independiente (ver
  /// [AvatarCreatorController.selectColorOption]) y se usa para teñir cada
  /// forma de la cuadrícula, sin necesidad de tener un SVG por combinación
  /// de forma+color.
  final List<AvatarOption>? colorOptions;

  /// Título visible de la fila de [colorOptions] (por ejemplo, "Color del
  /// pelo" o "Tono de piel"). Requerido cuando [kind] es
  /// [AvatarCategoryKind.layerWithColor].
  final String? colorSectionLabel;

  /// Título visible de la cuadrícula de [options] cuando [kind] es
  /// [AvatarCategoryKind.layerWithColor] (por ejemplo, "Forma del pelo" o
  /// "Expresión"). En categorías de tipo [AvatarCategoryKind.layer] no se
  /// usa: el título visible de la única sección es directamente [label].
  final String? shapeSectionLabel;

  /// `true` únicamente en la categoría que representa el color de fondo del
  /// avatar (hoy, "Color de fondo"). Esta bandera es lo que le dice al
  /// controlador que esta categoría **no** debe apilarse como una capa SVG
  /// más en el preview (ver [AvatarCreatorController.previewLayers]),
  /// sino que su opción elegida es el color de fondo del lienzo completo
  /// (ver [AvatarCreatorController.backgroundColor]).
  final bool isBackground;

  /// Busca la opción con id [optionId] dentro de [options].
  ///
  /// Si no existe ninguna opción con ese id (por ejemplo, porque venía de
  /// una selección guardada previamente y esa opción fue eliminada del
  /// catálogo), en vez de lanzar una excepción se devuelve `options.first`
  /// como valor de respaldo seguro, para que la pantalla nunca se rompa por
  /// datos desactualizados.
  AvatarOption optionById(String optionId) =>
      options.firstWhere((option) => option.id == optionId, orElse: () => options.first);

  /// Igual que [optionById], pero busca dentro de [colorOptions] en vez de
  /// [options]. Devuelve `null` si esta categoría no tiene [colorOptions]
  /// (es decir, si no es de tipo [AvatarCategoryKind.layerWithColor]).
  AvatarOption? colorOptionById(String optionId) {
    final options = colorOptions;
    if (options == null) return null;
    return options.firstWhere((option) => option.id == optionId, orElse: () => options.first);
  }
}
