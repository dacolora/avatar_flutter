import 'package:flutter/material.dart';

import '../models/avatar_layer_category.dart';
import '../models/avatar_option.dart';

/// Catálogo por defecto del widget: define **qué** categorías existen, en
/// **qué orden**, y **qué opciones** tiene cada una.
///
/// Esta función es, junto con [AvatarCreatorConfig], la otra mitad de la
/// frontera librería/canal: aquí es donde vive el contenido que el equipo de
/// diseño de Bancolombia definió como "el" catálogo oficial (Vestuario,
/// Cabello, Rostro, Accesorios y Color de fondo). El canal normalmente **no**
/// llama a esta función directamente ni la sobreescribe: [AvatarCreatorScreen]
/// la usa automáticamente cuando el canal no provee
/// [AvatarCreatorConfig.categories].
///
/// El **orden** de la lista que devuelve importa por dos motivos a la vez:
/// es el orden de los tabs de navegación que ve el usuario, y es también el
/// orden de apilado (z-index) en el preview — cada capa se dibuja encima de
/// la anterior, de más al fondo (Vestuario) a más al frente (Accesorios). La
/// categoría de fondo ("background") no cuenta para el apilado: no es una
/// capa SVG, es el color detrás de todas ellas (ver
/// [AvatarLayerCategory.isBackground]).
///
/// ### Cómo están armados los assets reales
/// * **Vestuario** y **Accesorios**: cada opción es un SVG completo e
///   independiente, entregado por diseño con nombres de archivo exportados
///   directamente desde Figma (por ejemplo, `Property 1=3.svg`,
///   `Style=Style4.svg`). No tienen fila de color: el color, si lo hay, ya
///   viene dentro de cada diseño.
/// * **Cabello** y **Rostro**: son categorías de tipo
///   [AvatarCategoryKind.layerWithColor]. A diferencia de Vestuario/Accesorios,
///   aquí diseño entregó un archivo distinto **por cada combinación** de
///   forma y color (30 SVGs por categoría: 6 formas × 5 colores, con nombres
///   como `Color=3, Expression=5.svg`) — el color viene incluido en el
///   propio SVG, no se aplica con ningún filtro en tiempo de ejecución. Por
///   eso, el `assetPath` de cada opción de forma en estas dos categorías es
///   una **plantilla** con el marcador `{color}` (ver
///   [AvatarLayerCategory.resolveAssetPath], que sustituye ese marcador por
///   el id del color elegido).
List<AvatarLayerCategory> defaultAvatarCatalog() {
  return [
    _wardrobeLikeCategory(
      id: 'body',
      label: 'Vestuario',
      icon: Icons.checkroom_outlined,
      semanticPrefix: 'Vestuario',
      assetPaths: [
        for (var i = 1; i <= 6; i++) 'assets/avatar/body/Property 1=$i.svg',
      ],
    ),
    _hairOrFaceCategory(
      id: 'hair',
      label: 'Cabello',
      icon: Icons.content_cut,
      colorSectionLabel: 'Color del pelo',
      shapeSectionLabel: 'Forma del pelo',
      shapeSemanticPrefix: 'Forma de pelo',
      colorOptions: const [
        AvatarOption.color(id: '1', color: Color(0xFFFF7F41), semanticLabel: 'Naranja'),
        AvatarOption.color(id: '2', color: Color(0xFF9063CD), semanticLabel: 'Morado'),
        AvatarOption.color(id: '3', color: Color(0xFFFDDA24), semanticLabel: 'Amarillo'),
        AvatarOption.color(id: '4', color: Color(0xFF2C2A29), semanticLabel: 'Negro'),
        AvatarOption.color(id: '5', color: Color(0xFFB3B5B8), semanticLabel: 'Gris'),
      ],
    ),
    _hairOrFaceCategory(
      id: 'face',
      label: 'Rostro',
      icon: Icons.face_outlined,
      colorSectionLabel: 'Tono de piel',
      shapeSectionLabel: 'Expresión',
      shapeSemanticPrefix: 'Expresión',
      colorOptions: const [
        AvatarOption.color(id: '1', color: Color(0xFFE4AC7B), semanticLabel: 'Tono de piel 1'),
        AvatarOption.color(id: '2', color: Color(0xFFF3D8C1), semanticLabel: 'Tono de piel 2'),
        AvatarOption.color(id: '3', color: Color(0xFFFFE5D1), semanticLabel: 'Tono de piel 3'),
        AvatarOption.color(id: '4', color: Color(0xFF8C4D18), semanticLabel: 'Tono de piel 4'),
        AvatarOption.color(id: '5', color: Color(0xFFCCA07C), semanticLabel: 'Tono de piel 5'),
      ],
    ),
    _wardrobeLikeCategory(
      id: 'extra',
      label: 'Accesorios',
      icon: Icons.auto_awesome_outlined,
      semanticPrefix: 'Accesorio',
      assetPaths: const [
        'assets/avatar/extra/Style=1.svg',
        'assets/avatar/extra/Style=Style2.svg',
        'assets/avatar/extra/Style=Style3.svg',
        'assets/avatar/extra/Style=Style4.svg',
        'assets/avatar/extra/Style=Style5.svg',
        'assets/avatar/extra/Style=Style6.svg',
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
        AvatarOption.color(id: 'green', color: Color(0xFF5FB894), semanticLabel: 'Fondo verde'),
        AvatarOption.color(id: 'orange', color: Color(0xFFE8946B), semanticLabel: 'Fondo naranja'),
        AvatarOption.color(id: 'blue', color: Color(0xFF8FC5D6), semanticLabel: 'Fondo azul'),
        AvatarOption.color(id: 'yellow', color: Color(0xFFF3D53C), semanticLabel: 'Fondo amarillo'),
        AvatarOption.color(id: 'purple', color: Color(0xFFA48AD4), semanticLabel: 'Fondo morado'),
      ],
    ),
  ];
}

/// Construye una categoría simple ([AvatarCategoryKind.layer], sin fila de
/// color) a partir de una lista de SVGs ya distintos entre sí — un archivo
/// completo por opción, como los de Vestuario y Accesorios.
AvatarLayerCategory _wardrobeLikeCategory({
  required String id,
  required String label,
  required IconData icon,
  required String semanticPrefix,
  required List<String> assetPaths,
}) {
  return AvatarLayerCategory(
    id: id,
    label: label,
    icon: icon,
    kind: AvatarCategoryKind.layer,
    options: [
      for (var i = 0; i < assetPaths.length; i++)
        AvatarOption.layer(
          id: '${i + 1}',
          assetPath: assetPaths[i],
          semanticLabel: '$semanticPrefix ${i + 1}',
        ),
    ],
  );
}

/// Construye una categoría de tipo [AvatarCategoryKind.layerWithColor] cuyos
/// assets siguen la convención de Cabello/Rostro: 6 formas × 5 colores,
/// nombradas `Color=$colorId, Expression=$shapeNumber.svg` dentro de
/// `assets/avatar/$id/`.
///
/// El `assetPath` de cada forma generada aquí es una plantilla con el
/// marcador `{color}` — ver [AvatarLayerCategory.resolveAssetPath].
AvatarLayerCategory _hairOrFaceCategory({
  required String id,
  required String label,
  required IconData icon,
  required String colorSectionLabel,
  required String shapeSectionLabel,
  required String shapeSemanticPrefix,
  required List<AvatarOption> colorOptions,
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
      for (var shape = 1; shape <= 6; shape++)
        AvatarOption.layer(
          id: '$shape',
          assetPath: 'assets/avatar/$id/Color={color}, Expression=$shape.svg',
          semanticLabel: '$shapeSemanticPrefix $shape',
        ),
    ],
  );
}
