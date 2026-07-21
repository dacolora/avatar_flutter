import 'dart:convert';
import 'dart:typed_data';

import 'package:avatar_flutter/avatar_flutter.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Punto de entrada de la app de ejemplo. `runApp` es la función de Flutter
/// que toma un widget raíz y lo pinta en pantalla; todo lo demás en este
/// archivo describe cómo se ve y se comporta esa app.
void main() => runApp(const AvatarFlutterExampleApp());

/// App de ejemplo completa: **esto es código del canal, no de la librería**.
/// Nada de este archivo se publica dentro del paquete `avatar_flutter` (vive
/// en `example/`, una convención de los paquetes de Flutter para tener una
/// app real de demostración); su único propósito es mostrar, con un caso
/// concreto, cómo una app anfitriona integraría el widget: dónde se guarda la
/// selección entre sesiones (aquí, con `shared_preferences`, el paquete
/// estándar de Flutter para persistir datos simples clave-valor en el
/// dispositivo), cómo se usa la imagen resultante, y cómo se ofrece la
/// entrada al creador de avatar desde una pantalla de perfil.
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

/// Pantalla de perfil de la app de ejemplo. Representa "la pantalla del
/// canal" desde la cual normalmente se entra al creador de avatar (según la
/// especificación, típicamente desde un botón de edición sobre la foto de
/// perfil).
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  /// La imagen del avatar guardada más recientemente. Nótese que esto vive
  /// **aquí**, en el estado del canal, no dentro de la librería: es
  /// precisamente la responsabilidad de persistencia que le corresponde al
  /// canal (en una app real, en vez de guardarla solo en memoria como aquí,
  /// se subiría a un servidor o se guardaría en disco).
  Uint8List? _avatarImageBytes;

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
        // Hooks de tagueo sugeridos: el canal decide si/cómo los envía.
        onView: () =>
            debugPrint('tag: ${AvatarAnalyticsEvents.avatarCreatorView}'),
        onSave: () => debugPrint('tag: ${AvatarAnalyticsEvents.avatarSave}'),
        onSaveSuccess: (_) =>
            debugPrint('tag: ${AvatarAnalyticsEvents.avatarSaveSuccess}'),
        onSaveError: (_) =>
            debugPrint('tag: ${AvatarAnalyticsEvents.avatarSaveError}'),
      ),
    );

    // El widget solo genera la imagen y la selección; sincronizarlas es
    // responsabilidad del canal (ver "Reglas de uso").
    if (result is AvatarCreatorResult) {
      if (mounted) setState(() => _avatarImageBytes = result.imageBytes);
      await _saveSelection(result.selection);
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
      appBar: AppBar(title: const Text('Mi perfil')),
      body: Center(
        child: Semantics(
          label: 'Foto de perfil',
          button: true,
          child: GestureDetector(
            onTap: _openEditImageSheet,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 56,
                  backgroundImage:
                      _avatarImageBytes != null ? MemoryImage(_avatarImageBytes!) : null,
                  child: _avatarImageBytes == null ? const Icon(Icons.person, size: 48) : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: CircleAvatar(
                    radius: 16,
                    child: Icon(
                      Icons.camera_alt,
                      size: 16,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
