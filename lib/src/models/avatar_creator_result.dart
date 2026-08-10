import 'dart:typed_data';

import 'package:flutter/widgets.dart' show Color, ImageProvider, MemoryImage;
import 'package:image/image.dart' as img;

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

  /// [imageBytes] envuelto en un [ImageProvider] ([MemoryImage]), listo para
  /// usarse directamente en cualquier widget que reciba una imagen —
  /// `CircleAvatar(backgroundImage: result.imageProvider)`,
  /// `Image(image: result.imageProvider)`,
  /// `DecorationImage(image: result.imageProvider)`, etc. — sin que el canal
  /// tenga que construir el `MemoryImage` por su cuenta.
  ///
  /// No es [AssetImage]: ese `ImageProvider` es específicamente para assets
  /// declarados en el `pubspec.yaml` de una app o paquete (archivos que
  /// existen en disco antes de correr la app), y esta imagen se genera en
  /// memoria en tiempo de ejecución — [MemoryImage] es el `ImageProvider`
  /// equivalente para ese caso.
  ///
  /// Es un getter, no un campo: cada llamada crea una instancia nueva de
  /// `MemoryImage`, pero como todas envuelven el mismo [imageBytes] (la
  /// misma instancia de `Uint8List`, no una copia), Flutter las considera
  /// `==` entre sí y las cachea como la misma imagen — no genera trabajo de
  /// decodificación repetido por usar el getter varias veces.
  ImageProvider get imageProvider => MemoryImage(imageBytes);

  /// Convierte [imageBytes] (el PNG compuesto) a JPG, listo para que el
  /// canal lo escriba a un archivo o lo comparta como una imagen
  /// descargable (`File(ruta).writeAsBytes(await result.toJpg())`).
  ///
  /// [imageBytes] tiene transparencia real fuera del círculo del avatar
  /// (ver [AvatarPreview]: el `ClipOval` deja sin pintar las esquinas del
  /// lienzo cuadrado que capturó el `RepaintBoundary`), y JPG no soporta
  /// canal alfa — por eso, antes de codificar, esas zonas transparentes se
  /// "aplanan" sobre [backgroundColor] (blanco por defecto). Sin este paso,
  /// cada decodificador de JPG resolvería esas esquinas de una forma
  /// distinta (normalmente negro), en vez de quedar en blanco como se ve en
  /// el resto de la app.
  ///
  /// [quality] es la calidad de compresión JPG, de 0 (peor, más liviano) a
  /// 100 (mejor, más pesado); 92 es un valor alto que prácticamente no se
  /// nota a simple vista frente al PNG original.
  Future<Uint8List> toJpg({
    Color backgroundColor = const Color(0xFFFFFFFF),
    int quality = 92,
  }) async {
    final decoded = img.decodePng(imageBytes);
    if (decoded == null) {
      throw StateError('No fue posible decodificar el PNG del avatar.');
    }

    final flattened = img.Image(
      width: decoded.width,
      height: decoded.height,
      numChannels: 3,
    );
    img.fill(
      flattened,
      color: img.ColorRgb8(
        backgroundColor.red,
        backgroundColor.green,
        backgroundColor.blue,
      ),
    );
    img.compositeImage(flattened, decoded);

    return Uint8List.fromList(img.encodeJpg(flattened, quality: quality));
  }
}
