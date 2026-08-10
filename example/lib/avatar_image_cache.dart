import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

/// Guarda el PNG compuesto del avatar (`AvatarCreatorResult.imageBytes`) en
/// el directorio de **caché de la app**, en el celular de quien la está
/// usando — no en esta computadora ni en ningún servidor. Es justamente el
/// mismo tipo de carpeta que usan la mayoría de apps para cachear imágenes:
/// persiste entre sesiones (a diferencia de guardarlo solo en memoria, como
/// hacía antes `_avatarImageProvider` en `main.dart`), pero el sistema
/// operativo puede borrarla bajo presión de espacio — por eso [read] puede
/// devolver `null`, y quien lo use debe tener un respaldo (ver
/// `CachedAvatarImage`, que cae de vuelta a `AvatarStaticPreview` con la
/// selección persistida en `SharedPreferences` si el caché ya no está).
///
/// Vive en `example/`, no en `avatar_flutter`: igual que con
/// `AvatarHomeWidgetSync` o `_downloadAvatarAsJpg`, decidir *dónde y cómo*
/// cachear la imagen es responsabilidad del canal, no de la librería.
class AvatarImageCache {
  AvatarImageCache._();

  static const String _fileName = 'avatar_cache.png';

  static Future<File> _cacheFile() async {
    final directory = await getApplicationCacheDirectory();
    return File('${directory.path}/$_fileName');
  }

  /// Escribe [imageBytes] en el caché, sobrescribiendo lo que hubiera antes.
  static Future<void> save(Uint8List imageBytes) async {
    final file = await _cacheFile();
    await file.writeAsBytes(imageBytes, flush: true);
  }

  /// Lee el avatar cacheado, si existe. `null` si nunca se guardó uno o si
  /// el sistema operativo ya liberó ese espacio de caché.
  static Future<Uint8List?> read() async {
    final file = await _cacheFile();
    if (!await file.exists()) return null;
    return file.readAsBytes();
  }
}
