import 'dart:convert';
import 'dart:io';

import 'package:avatar_flutter/avatar_flutter.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'avatar_home_widget_sync.dart';
import 'avatar_image_cache.dart';
import 'cached_avatar_image.dart';
import 'customization_gallery.dart';

void main() => runApp(const AvatarFlutterExampleApp());

class AvatarFlutterExampleApp extends StatelessWidget {
  const AvatarFlutterExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Avatar Flutter — Ejemplo',
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFFF3D53C),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const ProfileScreen(),
    );
  }
}

/// Esta pantalla existe para que un canal pueda **comparar en vivo** las dos
/// formas de orquestar la imagen del avatar después de guardarlo, cada una
/// en su propia tarjeta, con su propio botón "Editar" y su propio estado —
/// deliberadamente sin compartir nada entre sí, para que la diferencia
/// quede notoria:
///
/// * [MapOnlyAvatarCard] — Opción A: solo se persiste el `Map<String,
///   String>` de la selección; la imagen se recompone en vivo cada vez con
///   `AvatarStaticPreview`.
/// * [CachedImageAvatarCard] — Opción B: se persiste el PNG ya renderizado
///   en el caché del celular (`AvatarImageCache`) y se muestra con
///   `CachedAvatarImage`, sin recomponer nada.
///
/// Ver el README, sección "Dos formas de orquestar la imagen del avatar",
/// para el detalle de qué gana y qué pierde cada una.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Ejemplos de personalizacion',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const CustomizationGalleryScreen()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Text(
            'Dos formas de que el canal orqueste la imagen del avatar '
            'después de guardarla:',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 12),
          MapOnlyAvatarCard(),
          SizedBox(height: 16),
          CachedImageAvatarCard(),
        ],
      ),
    );
  }
}

/// Opción A: el canal solo persiste `result.selection` — el mismo
/// `Map<String, String>` que ya usaba este ejemplo antes de tener caché de
/// imagen. Nunca toca `AvatarImageCache`, el widget nativo ni el JPG
/// descargable: es la orquestación más liviana posible (unas pocas decenas
/// de bytes en `SharedPreferences`), a costa de tener que **recomponer**
/// el avatar con `AvatarStaticPreview` cada vez que hay que mostrarlo, en
/// vez de mostrar una imagen ya lista.
///
/// Como la selección sí queda guardada, reabrir el editor (`_edit`) arranca
/// mostrando la misma elección de la última vez.
class MapOnlyAvatarCard extends StatefulWidget {
  const MapOnlyAvatarCard({super.key});

  @override
  State<MapOnlyAvatarCard> createState() => _MapOnlyAvatarCardState();
}

class _MapOnlyAvatarCardState extends State<MapOnlyAvatarCard> {
  /// Llave propia (distinta de cualquier otra) para que esta demo no
  /// comparta almacenamiento con [CachedImageAvatarCard] — cada tarjeta
  /// tiene que poder guardarse y perderse de forma completamente
  /// independiente.
  static const _prefsKey = 'avatar_selection_map_only';

  Map<String, String>? _selection;

  @override
  void initState() {
    super.initState();
    _load().then((selection) {
      if (mounted && selection.isNotEmpty) {
        setState(() => _selection = selection);
      }
    });
  }

  Future<Map<String, String>> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_prefsKey);
    if (json == null) return {};
    return Map<String, String>.from(jsonDecode(json) as Map);
  }

  Future<void> _save(Map<String, String> selection) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(selection));
  }

  Future<void> _edit() async {
    final result = await AvatarCreatorScreen.push(
      context,
      config: AvatarCreatorConfig(initialSelection: _load()),
    );
    if (result is AvatarCreatorResult) {
      // Deliberadamente lo único que se persiste: result.imageBytes se
      // descarta acá mismo, ni siquiera se mira.
      await _save(result.selection);
      if (mounted) setState(() => _selection = result.selection);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _OrchestrationCard(
      title: 'Opción A · Solo la selección (Map)',
      description:
          'Se guarda únicamente result.selection en SharedPreferences. Cada '
          'vez que hay que mostrar el avatar se recompone en vivo con '
          'AvatarStaticPreview a partir de esa selección — no existe ninguna '
          'imagen ya renderizada guardada en ningún lado.',
      avatar: _selection != null
          ? AvatarStaticPreview(selection: _selection!, size: 96)
          : const CircleAvatar(
              radius: 48, child: Icon(Icons.person, size: 40)),
      onEdit: _edit,
    );
  }
}

/// Opción B: el canal persiste el PNG ya compuesto en el caché de la app
/// (`AvatarImageCache`, en el celular de quien la usa) y lo muestra con
/// `CachedAvatarImage`, que lo relee directo del archivo — más rápido de
/// mostrar, sin recomponer nada. De paso, dispara los otros dos usos que ya
/// necesitan esos mismos bytes: la sincronización con el widget nativo de
/// pantalla de inicio y la descarga como JPG.
///
/// A propósito, esta tarjeta **no** guarda `result.selection` en ningún
/// lado: así queda notorio el otro lado del tradeoff frente a la Opción
/// A — reabrir el editor (`_edit`) siempre arranca en blanco, no con la
/// última elección, porque no hay ningún mapa guardado con el que
/// prellenarlo.
class CachedImageAvatarCard extends StatefulWidget {
  const CachedImageAvatarCard({super.key});

  @override
  State<CachedImageAvatarCard> createState() => _CachedImageAvatarCardState();
}

class _CachedImageAvatarCardState extends State<CachedImageAvatarCard> {
  /// Se incrementa en cada guardado y se usa como `key` de
  /// [CachedAvatarImage] para forzarlo a releer el archivo del caché (ver
  /// el mismo patrón, con más detalle, en el README).
  int _cacheVersion = 0;

  Future<void> _edit() async {
    final result = await AvatarCreatorScreen.push(
      context,
      // Sin initialSelection: esta orquestación no guarda el mapa en
      // ningún lado (ver el docComment de la clase), así que no hay nada
      // con qué prellenar el editor la próxima vez.
      config: const AvatarCreatorConfig(),
    );
    if (result is AvatarCreatorResult) {
      await AvatarImageCache.save(result.imageBytes);
      if (mounted) setState(() => _cacheVersion++);
      // Los mismos bytes ya cacheados alimentan, de paso, el widget nativo
      // de pantalla de inicio (ver README, "Widget de pantalla de inicio
      // (iOS y Android)") y la descarga en JPG (ver README, "Descargar el
      // avatar como JPG").
      await AvatarHomeWidgetSync.sync(result.imageBytes);
      final jpgPath = await _downloadAvatarAsJpg(result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Avatar descargado como JPG: $jpgPath')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _OrchestrationCard(
      title: 'Opción B · Imagen cacheada completa',
      description:
          'Se guarda el PNG ya compuesto en el caché de la app '
          '(AvatarImageCache) y se muestra con CachedAvatarImage, sin '
          'recomponer nada. Ojo: esta demo no guarda la selección, así que '
          'reabrir el editor siempre arranca en blanco, no con lo último '
          'elegido — ver el tradeoff completo en el README.',
      avatar: CachedAvatarImage(key: ValueKey(_cacheVersion), radius: 48),
      onEdit: _edit,
    );
  }
}

/// Escribe `result.toJpg()` a un archivo en el almacenamiento propio de la
/// app y devuelve la ruta — el paso que falta después de generar los bytes
/// del JPG (`AvatarCreatorResult.toJpg`, en la librería) para que la imagen
/// sea *descargable* de verdad y no solo bytes en memoria.
Future<String> _downloadAvatarAsJpg(AvatarCreatorResult result) async {
  final jpgBytes = await result.toJpg();
  final directory = await getApplicationDocumentsDirectory();
  final file = File(
    '${directory.path}/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg',
  );
  await file.writeAsBytes(jpgBytes);
  return file.path;
}

/// Layout compartido por las dos tarjetas de comparación: un avatar a la
/// izquierda (tocarlo también abre el editor, igual que el botón), un
/// título, una explicación corta del tradeoff, y el botón "Editar".
class _OrchestrationCard extends StatelessWidget {
  const _OrchestrationCard({
    required this.title,
    required this.description,
    required this.avatar,
    required this.onEdit,
  });

  final String title;
  final String description;
  final Widget avatar;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: onEdit,
              child: Semantics(label: title, button: true, child: avatar),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(description, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 8),
                  OutlinedButton(onPressed: onEdit, child: const Text('Editar')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
