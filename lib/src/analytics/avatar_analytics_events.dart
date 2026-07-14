/// Nombres de evento sugeridos por la especificación del widget ("Etiquetado
/// (Tagueo)"). Son una guía, no una implementación obligatoria: el widget
/// nunca los dispara por sí mismo, solo expone los callbacks correspondientes
/// en [AvatarCreatorConfig] para que el canal decida si los usa.
abstract final class AvatarAnalyticsEvents {
  /// Al abrir la pantalla de creación o edición de avatar.
  static const String avatarCreatorView = 'avatar_creator_view';

  /// Al tocar el botón "Guardar" en el footer.
  static const String avatarSave = 'avatar_save';

  /// Avatar guardado y asociado al perfil correctamente.
  static const String avatarSaveSuccess = 'avatar_save_success';

  /// Error al persistir la configuración del avatar.
  static const String avatarSaveError = 'avatar_save_error';
}
