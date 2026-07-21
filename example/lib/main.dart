import 'dart:typed_data';

import 'package:avatar_flutter/avatar_flutter.dart';
import 'package:bds_core_foundations/core_foundations.dart';
import 'package:bds_mobile/atoms/atoms.dart';
import 'package:bds_mobile/foundations/foundations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() => runApp(const AvatarFlutterExampleApp());

/// App de ejemplo: muestra cómo un canal embebe `avatar_flutter`.
///
/// `bds_mobile` espera que su app anfitriona provea sus foundations
/// (BcThemeNotifier, BcBrandNotifier, CoreFoundations.themeProvider) en la
/// raíz — cualquier canal real que use `avatar_flutter` ya tendrá esto
/// configurado en su propio app shell.
class AvatarFlutterExampleApp extends StatelessWidget {
  const AvatarFlutterExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BcThemeNotifier()),
        ChangeNotifierProvider(create: (_) => BcBrandNotifier()),
        ...CoreFoundations.themeProvider,
      ],
      child: const MaterialApp(
        title: 'Avatar Flutter — Ejemplo',
        home: ProfileScreen(),
      ),
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
        child: BcAvatar(
          image: _avatarImageBytes != null
              ? MemoryImage(_avatarImageBytes!)
              : null,
          size: BcAvatarSize.XLarge,
          semanticLabel: 'Foto de perfil',
          actionableIcon: Icons.camera_alt,
          onTap: _openEditImageSheet,
        ),
      ),
    );
  }
}
