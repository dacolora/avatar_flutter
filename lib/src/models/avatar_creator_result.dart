import 'dart:typed_data';

import 'avatar_selection.dart';

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

  /// La selección final (`categoryId -> optionId`) con la que el usuario
  /// guardó el avatar. Útil si el canal quiere, por ejemplo, reabrir el
  /// creador más adelante con esta misma selección como punto de partida
  /// (ver [AvatarCreatorConfig.initialSelection]).
  final AvatarSelection selection;

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
