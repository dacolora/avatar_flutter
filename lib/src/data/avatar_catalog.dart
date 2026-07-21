import 'package:flutter/material.dart';

import '../models/avatar_layer_category.dart';
import '../models/avatar_option.dart';

/// Catálogo por defecto del widget: define **qué** categorías existen, en
/// **qué orden**, y **qué opciones** tiene cada una.
///
/// Esta función es, junto con [AvatarCreatorConfig], la otra mitad de la
/// frontera librería/canal: aquí es donde vive el contenido que el equipo de
/// diseño de Bancolombia definió como "el" catálogo oficial (4 categorías de
/// capa — Vestuario, Cabello, Rostro, Accesorios — más "Color de fondo"). El
/// canal normalmente **no** llama a esta función directamente ni la
/// sobreescribe: [AvatarCreatorScreen] la usa automáticamente cuando el
/// canal no provee [AvatarCreatorConfig.categories].
///
/// El **orden** de la lista que devuelve importa por dos motivos a la vez:
/// es el orden de los tabs de navegación que ve el usuario, y es también el
/// orden de apilado (z-index) en el preview — cada capa se dibuja encima de
/// la anterior, de más al fondo (Vestuario) a más al frente (Accesorios).
///
/// ### Nota sobre el estado actual de los assets
/// Por ahora solo existe **un** asset de muestra por categoría
/// (`{categoria}_1.svg`, entregado por el equipo de diseño). Mientras el
/// resto de variantes reales no estén listas, cada categoría repite ese
/// mismo asset en varios slots seleccionables (ver
/// [_placeholderLayerCategory]) para que el flujo completo — elegir opción,
/// ver el preview actualizarse, guardar — ya funcione de punta a punta con
/// datos de verdad, aunque visualmente algunas opciones se vean idénticas
/// entre sí. Agregar una variante real más adelante (por ejemplo,
/// `hair_2.svg`) es **solo un cambio de datos**: se agrega un
/// `AvatarOption.layer(...)` nuevo apuntando al SVG correspondiente, sin
/// tocar ningún widget ni controlador.
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
    // A diferencia de las categorías de capa de arriba, esta se construye
    // directamente con el constructor normal de [AvatarLayerCategory] (no
    // con [_placeholderLayerCategory]), porque sus opciones no son SVGs de
    // muestra repetidos sino colores reales y definitivos.
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

/// Construye una categoría de tipo [AvatarCategoryKind.layer] con
/// [optionCount] opciones, todas apuntando al mismo [assetPath] de muestra
/// (ver la nota sobre el estado de los assets en [defaultAvatarCatalog]).
///
/// `List.generate(optionCount, (index) => ...)` es la forma idiomática en
/// Dart de crear una lista de tamaño fijo aplicando la misma lógica a cada
/// posición: aquí, para cada índice de `0` a `optionCount - 1`, se crea una
/// [AvatarOption.layer] con un id distinto (`'$id-${index + 1}'`, por
/// ejemplo `'hair-1'`, `'hair-2'`, ...) pero el mismo `assetPath`.
AvatarLayerCategory _placeholderLayerCategory({
  required String id,
  required String label,
  required IconData icon,
  required String assetPath,
  int optionCount = 10,
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
