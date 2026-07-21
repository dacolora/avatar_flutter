import 'dart:typed_data';

/// Resultado que la librería entrega al canal cuando el usuario guarda el
/// avatar (ver [AvatarCreatorController.save] y
/// [AvatarCreatorConfig.onSaveSuccess]).
///
/// Contiene únicamente los datos que la librería sabe generar por sí misma:
/// la selección final y la imagen compuesta. **No** contiene, por ejemplo,
/// un id de usuario o una URL donde subir la imagen, porque eso depende de
/// cómo funciona cada canal y no es responsabilidad de este widget.
///
/// Este es uno de los puntos más importantes para entender la frontera de
/// responsabilidades del paquete: la librería compone la imagen y se la
/// entrega al canal; **el canal decide qué hacer con ella** (subirla a un
/// servidor, guardarla localmente, asociarla al perfil del usuario, etc.).
/// La librería nunca hace persistencia ni llamadas de red por su cuenta.
class AvatarCreatorResult {
  const AvatarCreatorResult({
    required this.selection,
    required this.imageBytes,
  });

  /// La selección final con la que el usuario guardó el avatar, como un
  /// mapa `categoryId -> optionId` (por ejemplo,
  /// `{'face': 'face-3', 'hair': 'hair-1', 'background': 'green'}`).
  ///
  /// Se expone como un `Map<String, String>` en lugar de un tipo propio de
  /// esta librería a propósito: un mapa de `String` a `String` es
  /// directamente serializable con `jsonEncode(...)` de `dart:convert`, así
  /// que el canal puede guardarlo tal cual en `SharedPreferences` (u otro
  /// almacenamiento) sin ninguna conversión intermedia:
  /// ```dart
  /// final prefs = await SharedPreferences.getInstance();
  /// await prefs.setString('avatar_selection', jsonEncode(result.selection));
  /// ```
  /// Ese mismo mapa, ya decodificado con `jsonDecode(...)`, es exactamente
  /// lo que espera [AvatarCreatorConfig.initialSelection] la próxima vez que
  /// se abra el creador para seguir editando ese avatar.
  final Map<String, String> selection;

  /// Los bytes de una imagen PNG con el preview compuesto (todas las capas
  /// ilustradas apiladas sobre el color de fondo elegido), capturados desde
  /// el `RepaintBoundary` que envuelve al preview en pantalla (ver
  /// [AvatarPreview] y [AvatarCreatorController.save]).
  ///
  /// [Uint8List] es el tipo estándar de Dart para representar una secuencia
  /// de bytes (números enteros de 0 a 255) en memoria; es el mismo tipo que
  /// usan, por ejemplo, `Image.memory(bytes)` o las respuestas binarias de
  /// paquetes HTTP, por lo que el canal puede tomar estos bytes y subirlos
  /// o mostrarlos sin conversiones adicionales.
  final Uint8List imageBytes;
}
