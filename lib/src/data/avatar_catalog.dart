import 'package:flutter/material.dart';

import '../models/avatar_layer_category.dart';
import '../models/avatar_option.dart';

/// Ícono compartido de "ninguna opción" (círculo con una línea diagonal),
/// usado como miniatura tanto de "Sin pelo" (Cabello) como de "Sin
/// accesorios" (Accesorios) — un solo archivo para las dos categorías, no
/// uno por categoría.
const String _noneThumbnailAssetPath = 'assets/avatar/none.svg';

/// Catálogo por defecto del widget: define **qué** categorías existen, en
/// **qué orden**, y **qué opciones** tiene cada una.
///
/// Esta función es, junto con [AvatarCreatorConfig], la otra mitad de la
/// frontera librería/canal: aquí es donde vive el contenido que el equipo de
/// diseño de Bancolombia definió como "el" catálogo oficial (Rostro,
/// Cabello, Vestuario, Accesorios y Color de fondo). El canal normalmente
/// **no** llama a esta función directamente ni la sobreescribe:
/// [AvatarCreatorScreen] la usa automáticamente cuando el canal no provee
/// [AvatarCreatorConfig.categories].
///
/// El **orden** de la lista que devuelve importa por dos motivos a la vez:
/// es el orden de los tabs de navegación que ve el usuario, y es también el
/// orden de apilado (z-index) en el preview — cada capa se dibuja encima de
/// la anterior, de más al fondo (Rostro) a más al frente (Accesorios). La
/// categoría de fondo ("background") no cuenta para el apilado: no es una
/// capa SVG, es el color detrás de todas ellas (ver
/// [AvatarLayerCategory.isBackground]).
///
/// ### Cómo están armados los assets reales
/// Vestuario, Cabello y Rostro son las tres categorías de tipo
/// [AvatarCategoryKind.layerWithColor]: diseño entregó un archivo distinto
/// **por cada combinación** de color y forma (por ejemplo, 6 colores × 8
/// estilos = 48 SVGs para Vestuario) — el color viene incluido en el propio
/// SVG, no se aplica con ningún filtro en tiempo de ejecución. Por eso, el
/// `assetPath` de cada opción de forma en estas categorías es una
/// **plantilla** con el marcador `{color}` (ver
/// [AvatarLayerCategory.resolveAssetPath], que sustituye ese marcador por el
/// id del color elegido).
///
/// Cada combinación, además, tiene **dos** archivos: uno para el preview
/// (`assets/avatar/$id/${id}_{color}_$forma.svg`, pensado para apilarse con
/// las demás capas dentro del círculo) y uno para su miniatura seleccionable
/// (`assets/avatar/ct_$id/ct_${id}_{color}_$forma.svg`, recortado para verse
/// bien solo dentro de un cuadro chico de la cuadrícula) — ver
/// [AvatarOption.thumbnailAssetPath] para la razón de esta duplicación.
///
/// Todas las opciones de este catálogo fijan
/// `assetPackage: 'avatar_flutter'` porque sus SVGs viven empaquetados
/// dentro de este paquete. Un canal que agregue su propia categoría (ver
/// [AvatarCreatorConfig.categories]) debe dejar ese campo en `null` — así
/// [AvatarOption.assetPackage] resuelve el asset desde el bundle de su
/// propia app, no desde este paquete.
List<AvatarLayerCategory> defaultAvatarCatalog() {
  return [
    _coloredCategory(
      id: 'face',
      label: 'Rostro',
      icon: Icons.face_outlined,
      colorSectionLabel: 'Tono de piel',
      shapeSectionLabel: 'Expresión',
      shapeSemanticPrefix: 'Expresión',
      shapeCount: 6,
      colorOptions: const [
        AvatarOption.color(
            id: '1', color: Color(0xFFE4AC7B), semanticLabel: 'Tono de piel 1'),
        AvatarOption.color(
            id: '2', color: Color(0xFFF3D8C1), semanticLabel: 'Tono de piel 2'),
        AvatarOption.color(
            id: '3', color: Color(0xFFFFE5D1), semanticLabel: 'Tono de piel 3'),
        AvatarOption.color(
            id: '4', color: Color(0xFF8C4D18), semanticLabel: 'Tono de piel 4'),
        AvatarOption.color(
            id: '5', color: Color(0xFFCCA07C), semanticLabel: 'Tono de piel 5'),
      ],
    ),

    _coloredCategory(
      id: 'hair',
      label: 'Cabello',
      icon: Icons.content_cut,
      colorSectionLabel: 'Color del pelo',
      shapeSectionLabel: 'Forma del pelo',
      shapeSemanticPrefix: 'Forma de pelo',
      shapeCount: 11,
      noneOptionSemanticLabel: 'Sin pelo',
      colorOptions: const [
        AvatarOption.color(
            id: '1', color: Color(0xFFFF7F41), semanticLabel: 'Naranja'),
        AvatarOption.color(
            id: '2', color: Color(0xFF9063CD), semanticLabel: 'Morado'),
        // Antes "Amarillo" (#FDDA24): el arte de esta combinación cambió a
        // un tono café/oliva real (#867313), así que el nombre se actualizó
        // para que coincida con lo que el usuario en verdad ve.
        AvatarOption.color(
            id: '3', color: Color(0xFF867313), semanticLabel: 'Café'),
        AvatarOption.color(
            id: '4', color: Color(0xFF2C2A29), semanticLabel: 'Negro'),
        AvatarOption.color(
            id: '5', color: Color(0xFFB3B5B8), semanticLabel: 'Gris'),
      ],
    ),

    _coloredCategory(
      id: 'body',
      label: 'Vestuario',
      icon: Icons.checkroom_outlined,
      colorSectionLabel: 'Color de vestuario',
      shapeSectionLabel: 'Estilo de vestuario',
      shapeSemanticPrefix: 'Vestuario',
      shapeCount: 8,
      colorOptions: const [
        AvatarOption.color(
            id: '1', color: Color(0xFFFDDA24), semanticLabel: 'Amarillo'),
        AvatarOption.color(
            id: '2', color: Color(0xFFF5B6CD), semanticLabel: 'Rosado'),
        AvatarOption.color(
            id: '3', color: Color(0xFFFF7F41), semanticLabel: 'Naranja'),
        AvatarOption.color(
            id: '4', color: Color(0xFF59CBE8), semanticLabel: 'Celeste'),
        AvatarOption.color(
            id: '5', color: Color(0xFF9063CD), semanticLabel: 'Morado'),
        AvatarOption.color(
            id: '6', color: Color(0xFF00C389), semanticLabel: 'Verde'),
      ],
    ),

    // A diferencia de las categorías de arriba, esta es `kind: layer` (una
    // sola cuadrícula, sin fila de color): a diferencia de Vestuario,
    // Cabello y Rostro, un accesorio es opcional por naturaleza, así que
    // "Sin accesorios" va primero en `options` — eso lo deja preseleccionado
    // por defecto en un avatar nuevo (ver
    // [AvatarCreatorController._defaultSelection], que siempre usa
    // `options.first`).
    AvatarLayerCategory(
      id: 'extra',
      label: 'Accesorios',
      icon: Icons.auto_awesome_outlined,
      kind: AvatarCategoryKind.layer,
      options: const [
        AvatarOption.none(
          id: 'none',
          semanticLabel: 'Sin accesorios',
          thumbnailAssetPath: _noneThumbnailAssetPath,
          assetPackage: 'avatar_flutter',
        ),
        AvatarOption.layer(
          id: '1',
          assetPath: 'assets/avatar/extra/extra_1.svg',
          thumbnailAssetPath: 'assets/avatar/ct_extra/ct_extra_1.svg',
          assetPackage: 'avatar_flutter',
          semanticLabel: 'Accesorio 1',
        ),
      ],
    ),
    // A diferencia de las categorías de arriba, esta se construye
    // directamente con el constructor normal de [AvatarLayerCategory] (no
    // con un helper), porque sus opciones no son ilustraciones sino colores
    // reales y definitivos. `isBackground: true` es lo que le indica al
    // controlador que estas opciones son el color de fondo del lienzo, no
    // una capa más a apilar en el preview.
    AvatarLayerCategory(
      id: 'background',
      label: 'Color de fondo',
      icon: Icons.palette_outlined,
      kind: AvatarCategoryKind.layer,
      isBackground: true,
      options: const [
        AvatarOption.color(
            id: 'green',
            color: Color(0xFF5FB894),
            semanticLabel: 'Fondo verde'),
        AvatarOption.color(
            id: 'orange',
            color: Color(0xFFE8946B),
            semanticLabel: 'Fondo naranja'),
        AvatarOption.color(
            id: 'blue', color: Color(0xFF8FC5D6), semanticLabel: 'Fondo azul'),
        AvatarOption.color(
            id: 'yellow',
            color: Color(0xFFF3D53C),
            semanticLabel: 'Fondo amarillo'),
        AvatarOption.color(
            id: 'purple',
            color: Color(0xFFA48AD4),
            semanticLabel: 'Fondo morado'),
      ],
    ),
  ];
}

/// Construye una categoría de tipo [AvatarCategoryKind.layerWithColor] cuyos
/// assets siguen la convención `${id}_{color}_{forma}.svg` (preview) /
/// `ct_${id}_{color}_{forma}.svg` (miniatura), con [shapeCount] formas y
/// tantos colores como traiga [colorOptions].
///
/// El `assetPath`/`thumbnailAssetPath` de cada forma generada aquí es una
/// plantilla con el marcador `{color}` — ver
/// [AvatarLayerCategory.resolveAssetPath] y
/// [AvatarLayerCategory.resolveThumbnailAssetPath].
///
/// Si se da [noneOptionSemanticLabel], se agrega al final una opción
/// [AvatarOption.none] adicional (por ejemplo, "Sin pelo" en Cabello, para
/// un usuario calvo) — sin `assetPath`, así que al elegirla esa categoría
/// no aporta ninguna capa al preview.
AvatarLayerCategory _coloredCategory({
  required String id,
  required String label,
  required IconData icon,
  required String colorSectionLabel,
  required String shapeSectionLabel,
  required String shapeSemanticPrefix,
  required int shapeCount,
  required List<AvatarOption> colorOptions,
  String? noneOptionSemanticLabel,
}) {
  return AvatarLayerCategory(
    id: id,
    label: label,
    icon: icon,
    kind: AvatarCategoryKind.layerWithColor,
    colorSectionLabel: colorSectionLabel,
    shapeSectionLabel: shapeSectionLabel,
    colorOptions: colorOptions,
    options: [
      for (var shape = 1; shape <= shapeCount; shape++)
        AvatarOption.layer(
          id: '$shape',
          assetPath: 'assets/avatar/$id/${id}_{color}_$shape.svg',
          thumbnailAssetPath:
              'assets/avatar/ct_$id/ct_${id}_{color}_$shape.svg',
          assetPackage: 'avatar_flutter',
          semanticLabel: '$shapeSemanticPrefix $shape',
        ),
      if (noneOptionSemanticLabel != null)
        AvatarOption.none(
          id: 'none',
          semanticLabel: noneOptionSemanticLabel,
          thumbnailAssetPath: _noneThumbnailAssetPath,
          assetPackage: 'avatar_flutter',
        ),
    ],
  );
}
