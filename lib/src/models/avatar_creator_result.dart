import 'dart:typed_data';

import 'avatar_selection.dart';

/// Resultado devuelto al canal cuando el usuario guarda el avatar.
///
/// El widget solo genera la imagen; el canal es responsable de sincronizarla
/// y asociarla al perfil (ver "Reglas de uso": "El canal es responsable de la
/// sincronización de la imagen generada después de la creación del avatar.
/// No asumir que el widget guarda automáticamente").
class AvatarCreatorResult {
  const AvatarCreatorResult({
    required this.selection,
    required this.imageBytes,
  });

  /// Selección final (categoryId -> optionId) que compone el avatar.
  final AvatarSelection selection;

  /// PNG del preview compuesto, capturado del `RepaintBoundary` del widget.
  final Uint8List imageBytes;
}
