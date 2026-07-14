import 'package:flutter/material.dart';

import '../models/avatar_layer_category.dart';
import '../models/avatar_option.dart';

/// Catálogo por defecto del widget: 4 categorías de capa (Face, Hair, Body,
/// Extra) más "Color de fondo". El orden de esta lista es el orden de
/// navegación de los tabs y no es libre (ver "Reglas de uso").
///
/// NOTA: por ahora solo existe un asset de muestra por categoría
/// (`{categoria}_1.svg`). Mientras el equipo de diseño entrega el resto de
/// variantes, cada categoría repite ese mismo asset en varios slots
/// seleccionables para dejar completo el flujo de selección / preview en
/// tiempo real / guardado. Agregar una variante real más adelante es un
/// cambio de datos (sumar un `AvatarOption.layer(...)` apuntando al nuevo
/// SVG), no de código.
///
/// El orden de esta lista define tanto el orden de los tabs de navegación
/// como el orden de apilado (z-index) del preview: cada capa se dibuja
/// encima de la anterior, de atrás (Vestuario) hacia adelante (Accesorios).
List<AvatarLayerCategory> defaultAvatarCatalog() {
  return [
    _placeholderLayerCategory(
      id: 'body',
      label: 'Vestuario',
      icon: Icons.checkroom_outlined,
      assetPath: 'assets/avatar/body/body_1.svg',
    ),
    _placeholderLayerCategory(
      id: 'hair',
      label: 'Cabello',
      icon: Icons.content_cut,
      assetPath: 'assets/avatar/hair/hair_1.svg',
    ),
    _placeholderLayerCategory(
      id: 'face',
      label: 'Rostro',
      icon: Icons.face_outlined,
      assetPath: 'assets/avatar/face/face_1.svg',
    ),
    _placeholderLayerCategory(
      id: 'extra',
      label: 'Accesorios',
      icon: Icons.auto_awesome_outlined,
      assetPath: 'assets/avatar/extra/extra_1.svg',
    ),
    AvatarLayerCategory(
      id: 'background',
      label: 'Color de fondo',
      icon: Icons.palette_outlined,
      kind: AvatarCategoryKind.colorRow,
      options: const [
        AvatarOption.color(id: 'green', color: Color(0xFF5FB894)),
        AvatarOption.color(id: 'orange', color: Color(0xFFE8946B)),
        AvatarOption.color(id: 'blue', color: Color(0xFF8FC5D6)),
        AvatarOption.color(id: 'yellow', color: Color(0xFFF3D53C)),
        AvatarOption.color(id: 'purple', color: Color(0xFFA48AD4)),
      ],
    ),
  ];
}

/// Genera [optionCount] opciones para una categoría de capa, todas apuntando
/// al mismo asset de muestra (ver nota de [defaultAvatarCatalog]).
AvatarLayerCategory _placeholderLayerCategory({
  required String id,
  required String label,
  required IconData icon,
  required String assetPath,
  int optionCount = 5,
}) {
  return AvatarLayerCategory(
    id: id,
    label: label,
    icon: icon,
    kind: AvatarCategoryKind.layer,
    options: List.generate(
      optionCount,
      (index) => AvatarOption.layer(
        id: '$id-${index + 1}',
        assetPath: assetPath,
        semanticLabel: '$label ${index + 1}',
      ),
    ),
  );
}
