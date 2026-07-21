import 'dart:typed_data';

import 'package:avatar_flutter/avatar_flutter.dart';
import 'package:flutter/material.dart';

void main() => runApp(const AvatarFlutterExampleApp());

/// App de ejemplo: muestra cómo un canal embebe `avatar_flutter`.
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
  Uint8List? _avatarImageBytes;
  AvatarSelection? _lastSelection;

  Future<void> _openAvatarCreator() async {
    final result = await AvatarCreatorScreen.push(
      context,
      config: AvatarCreatorConfig(
        initialSelection: _lastSelection,
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

    // El widget solo genera la imagen; sincronizarla con el perfil es
    // responsabilidad del canal (ver "Reglas de uso").
    if (result is AvatarCreatorResult && mounted) {
      setState(() {
        _avatarImageBytes = result.imageBytes;
        _lastSelection = result.selection;
      });
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
