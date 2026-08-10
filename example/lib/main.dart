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

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  /// Se incrementa cada vez que se guarda un avatar nuevo, y se usa como
  /// `key` de [CachedAvatarImage] en [build] para forzarlo a releer el
  /// archivo de [AvatarImageCache] (un `FutureBuilder` con la misma `key`
  /// no vuelve a ejecutar su `future`, así que sin esto seguiría mostrando
  /// la imagen vieja hasta el próximo rebuild "de casualidad"). El avatar
  /// en sí ya no se guarda en un campo en memoria: vive en el caché del
  /// celular (ver [AvatarImageCache]), no aquí.
  int _avatarCacheVersion = 0;

  /// La selección guardada la última vez (ver [_loadSavedSelection]),
  /// cargada en [initState]. Se le pasa a [CachedAvatarImage] como
  /// respaldo: si el caché de imagen (ver [AvatarImageCache]) todavía no
  /// existe o el sistema operativo ya lo liberó, se recompone el avatar con
  /// `AvatarStaticPreview` a partir de esta selección en vez de mostrar un
  /// placeholder vacío.
  Map<String, String>? _savedSelection;

  @override
  void initState() {
    super.initState();
    _loadSavedSelection().then((selection) {
      if (mounted && selection.isNotEmpty) {
        setState(() => _savedSelection = selection);
      }
    });
  }

  /// Llave bajo la que se guarda la selección del avatar en
  /// `SharedPreferences`. `SharedPreferences` solo almacena tipos simples
  /// (`String`, `int`, `bool`, `double`, `List<String>`), no mapas, así que
  /// la selección (`Map<String, String>`) se guarda codificada como una
  /// cadena JSON con `jsonEncode`/`jsonDecode` de `dart:convert`.
  static const _selectionPrefsKey = 'avatar_selection';

  /// Lee la selección guardada la última vez, si existe. Se le pasa
  /// directamente a [AvatarCreatorConfig.initialSelection], que acepta un
  /// `Future<Map<String, String>>` precisamente para casos como este: leer
  /// de `SharedPreferences` es una operación asíncrona
  /// (`SharedPreferences.getInstance()` devuelve un `Future`), así que la
  /// librería no puede pedir el mapa ya resuelto de forma síncrona.
  Future<Map<String, String>> _loadSavedSelection() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_selectionPrefsKey);
    if (json == null) return {};
    return Map<String, String>.from(jsonDecode(json) as Map);
  }

  /// Guarda la selección final (`result.selection`) para poder reabrir el
  /// creador la próxima vez con [_loadSavedSelection] mostrando lo mismo que
  /// el usuario había elegido.
  Future<void> _saveSelection(Map<String, String> selection) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectionPrefsKey, jsonEncode(selection));
  }

  /// Escribe `result.toJpg()` a un archivo en el almacenamiento propio de la
  /// app y devuelve la ruta. Es el paso que falta después de generar los
  /// bytes del JPG (`AvatarCreatorResult.toJpg`, en la librería) para que la
  /// imagen sea *descargable* de verdad y no solo bytes en memoria — acá es
  /// donde ese paso le toca al canal, igual que ya pasa con
  /// `_saveSelection`.
  Future<String> _downloadAvatarAsJpg(AvatarCreatorResult result) async {
    final jpgBytes = await result.toJpg();
    final directory = await getApplicationDocumentsDirectory();
    final file = File(
      '${directory.path}/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await file.writeAsBytes(jpgBytes);
    return file.path;
  }

  /// Abre la pantalla del creador de avatar y reacciona a su resultado.
  ///
  /// Este método concentra el ejemplo más claro de la frontera de
  /// responsabilidades: [AvatarCreatorScreen.push] (la librería) se encarga
  /// de toda la experiencia de selección y de generar la imagen; en cuanto
  /// esa función retorna, **todo lo que sigue es código del canal** —
  /// decidir qué hacer con `result.imageBytes` y `result.selection`, en este
  /// caso guardándolos con `shared_preferences`.
  Future<void> _openAvatarCreator() async {
    final result = await AvatarCreatorScreen.push(
      context,
      config: AvatarCreatorConfig(
        initialSelection: _loadSavedSelection(),
        // El canal puede personalizar los altos del preview (por ejemplo,
        // si su propio header ya ocupa espacio y necesita uno más chico).
        // Si se omiten estos dos, la librería usa 249/160 por defecto.
        previewExpandedHeight: 249,
        previewCollapsedHeight: 160,
        // Hooks de tagueo sugeridos: el canal decide si/cómo los envía.
        onView: () => debugPrint('tag: avatar_creator_view'),
        onSave: () => debugPrint('tag: avatar_save'),
        onSaveSuccess: (_) => debugPrint('tag: avatar_save_success'),
        onSaveError: (_) => debugPrint('tag: avatar_save_error'),
      ),
    );

    // El widget solo genera la imagen y la selección; sincronizarlas es
    // responsabilidad del canal (ver "Reglas de uso"). result.imageBytes
    // sigue disponible si el canal necesita los bytes crudos (por ejemplo,
    // para subirlos a un servidor); result.imageProvider es la versión ya
    // lista para mostrarse en un widget de imagen.
    if (result is AvatarCreatorResult) {
      await _saveSelection(result.selection);
      // El PNG compuesto se guarda en el caché de la app (en el celular de
      // quien la está usando, no en memoria ni en esta computadora) para
      // que cualquier pantalla lo pueda mostrar sin volver a componerlo —
      // ver [AvatarImageCache] y [CachedAvatarImage].
      await AvatarImageCache.save(result.imageBytes);
      if (mounted) {
        setState(() {
          _avatarCacheVersion++;
          _savedSelection = result.selection;
        });
      }
      // Además de cachear el PNG, se sincroniza con el widget nativo de
      // pantalla de inicio (ver README, "Widget de pantalla de inicio (iOS
      // y Android)").
      await AvatarHomeWidgetSync.sync(result.imageBytes);
      // Y se descarga una copia en JPG (ver README, "Descargar el avatar
      // como JPG").
      final jpgPath = await _downloadAvatarAsJpg(result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Avatar descargado como JPG: $jpgPath')),
        );
      }
    }
  }

  /// Patrón "Hazlo" de la especificación: ofrecer el widget como alternativa
  /// dentro del flujo de edición de imagen normal (Cámara / Galería / Avatar).
  Future<void> _openEditImageSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Cámara'),
              onTap: () => Navigator.of(context).pop(),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galería'),
              onTap: () => Navigator.of(context).pop(),
            ),
            ListTile(
              leading: const Icon(Icons.face_retouching_natural_outlined),
              title: const Text('Avatar'),
              onTap: () {
                Navigator.of(context).pop();
                _openAvatarCreator();
              },
            ),
            ListTile(
              title: const Text('Cerrar'),
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

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
      body: Center(
        child: Semantics(
          label: 'Foto de perfil',
          button: true,
          child: GestureDetector(
            onTap: _openEditImageSheet,
            // `key: ValueKey(_avatarCacheVersion)` es lo que fuerza a
            // releer el archivo del caché después de guardar un avatar
            // nuevo (ver el comentario de `_avatarCacheVersion`).
            child: CachedAvatarImage(
              key: ValueKey(_avatarCacheVersion),
              radius: 56,
              selectionFallback: _savedSelection,
            ),
          ),
        ),
      ),
    );
  }
}
