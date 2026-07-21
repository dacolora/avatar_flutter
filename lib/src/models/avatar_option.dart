import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

/// Una opción seleccionable dentro de una categoría ([AvatarLayerCategory]).
///
/// Piensa en un [AvatarOption] como uno de los cuadros que el usuario puede
/// tocar en la fila o cuadrícula de opciones (por ejemplo, un peinado
/// concreto o un color de fondo concreto). Puede representar dos cosas muy
/// distintas según qué constructor con nombre se haya usado para crearlo:
///
/// * [AvatarOption.layer] — una capa ilustrada (un peinado, un rostro, un
///   vestuario...). Apunta a un archivo SVG mediante [assetPath].
/// * [AvatarOption.color] — una muestra de color sólido, sin ilustración
///   (se usa hoy para la categoría "Color de fondo"). En vez de un asset,
///   trae un [color].
///
/// ### ¿Por qué dos constructores en lugar de dos clases?
/// Ambos tipos de opción necesitan convivir en la misma lista
/// (`List<AvatarOption>`, ver [AvatarLayerCategory.options]) y ser dibujados
/// por el mismo widget ([AvatarSelectableThumbnail]). En Dart existen dos
/// formas típicas de modelar "dos variantes de una misma cosa": crear una
/// clase abstracta con dos subclases, o usar **constructores con nombre**
/// (`ClaseX.nombreA(...)`, `ClaseX.nombreB(...)`) que construyen la *misma*
/// clase pero llenan campos distintos. Aquí se eligió la segunda opción
/// porque es más simple: no hace falta un `switch` sobre el tipo de objeto
/// (`is AvatarOptionLayer`), solo revisar si [assetPath] o [color] es
/// distinto de `null`.
///
/// Cada constructor deja el campo que no le corresponde en `null`
/// explícitamente (por ejemplo, [AvatarOption.layer] fija `color = null`).
/// Esa es la garantía que usa el resto del código: **siempre** habrá
/// exactamente uno de los dos (`assetPath` o `color`) distinto de `null`,
/// nunca ambos, nunca ninguno. Por eso en otros archivos vas a ver código
/// como `option.assetPath!` (con `!`, el operador "confío en que no es
/// null" de Dart) sin una comprobación previa: la comprobación real ya se
/// hizo antes, mirando `option.color != null` para decidir qué rama pintar
/// (ver [AvatarSelectableThumbnail]).
///
/// ### ¿Por qué extiende [Equatable]?
/// En Dart, por defecto, `==` compara **identidad** (¿son literalmente el
/// mismo objeto en memoria?), no contenido. Eso significa que dos
/// `AvatarOption` construidos por separado pero con los mismos datos
/// (`AvatarOption.layer(id: 'face-1', ...)` creado dos veces) serían
/// tratados como "diferentes" al compararlos con `==`, aunque representen
/// exactamente lo mismo.
///
/// [Equatable] cambia ese comportamiento: sobreescribe `==` (y `hashCode`)
/// para que dos instancias se consideren iguales si todos los valores
/// listados en [props] son iguales. Esto es útil, por ejemplo, en los tests
/// (`expect(opcionA, opcionB)` funciona por contenido) y evita bugs sutiles
/// en widgets que decidan si deben reconstruirse comparando objetos.
class AvatarOption extends Equatable {
  /// Crea una opción ilustrada: al seleccionarla, se dibuja el SVG de
  /// [assetPath] tanto en el preview del avatar como en su propia miniatura
  /// dentro de la cuadrícula/fila de opciones.
  const AvatarOption.layer({
    required this.id,
    required this.assetPath,
    this.semanticLabel,
  }) : color = null;

  /// Crea una opción de color sólido, sin ilustración. La usan las
  /// categorías de tipo [AvatarCategoryKind.colorRow], como "Color de
  /// fondo".
  const AvatarOption.color({
    required this.id,
    required this.color,
    this.semanticLabel,
  }) : assetPath = null;

  /// Identificador único de esta opción **dentro de su categoría** (por
  /// ejemplo, `'face-3'`). No necesita ser único entre categorías distintas,
  /// porque siempre se consulta junto con el id de la categoría (ver
  /// [AvatarSelection], que guarda un mapa `categoryId -> optionId`).
  final String id;

  /// Ruta del asset SVG a dibujar para esta opción. Solo tiene valor cuando
  /// la opción se creó con [AvatarOption.layer]; es `null` en las opciones
  /// de color.
  final String? assetPath;

  /// Color de relleno sólido de esta opción. Solo tiene valor cuando la
  /// opción se creó con [AvatarOption.color]; es `null` en las opciones
  /// ilustradas.
  final Color? color;

  /// Texto que un lector de pantalla anuncia cuando esta opción recibe el
  /// foco (accesibilidad), por ejemplo "Vestuario 3". Es opcional: si no se
  /// provee, el lector de pantalla simplemente no anunciará una descripción
  /// específica para esa opción.
  final String? semanticLabel;

  /// Campos que [Equatable] usa para decidir si dos opciones son "la misma".
  /// Ver el comentario de la clase para entender por qué esto importa.
  @override
  List<Object?> get props => [id, assetPath, color];
}
