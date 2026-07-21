/// Nombres de evento sugeridos por la especificación de diseño ("Etiquetado
/// / Tagueo") para medir el uso del creador de avatar.
///
/// Es una clase `abstract final` que solo contiene constantes `static`, un
/// patrón de Dart equivalente a un "namespace" de constantes: nunca se
/// instancia (`abstract` lo impide) y nadie puede heredar de ella (`final`
/// lo impide), simplemente se usa como `AvatarAnalyticsEvents.avatarSave`
/// para tener el nombre del evento sin arriesgarse a un typo si se escribiera
/// el string a mano en varios lugares.
///
/// **Importante**: estos nombres son solo una **guía**, no una
/// implementación de analítica. El widget nunca llama a ningún SDK de
/// analítica ni dispara estos eventos por sí mismo — lo único que hace es
/// invocar los callbacks correspondientes de [AvatarCreatorConfig] (
/// `onView`, `onSave`, `onSaveSuccess`, `onSaveError`) en los momentos
/// adecuados. Es responsabilidad exclusiva del canal, dentro de esos
/// callbacks, decidir si quiere registrar un evento, con qué nombre y con
/// qué herramienta (Firebase, Amplitude, lo que use cada canal). Estas
/// constantes existen únicamente para que, si el canal decide usarlas,
/// todos los equipos midan con el mismo nombre exacto de evento.
abstract final class AvatarAnalyticsEvents {
  /// Sugerido para cuando se abre la pantalla de creación o edición de
  /// avatar. Corresponde al callback [AvatarCreatorConfig.onView].
  static const String avatarCreatorView = 'avatar_creator_view';

  /// Sugerido para cuando el usuario toca el botón "Guardar" del pie de
  /// pantalla. Corresponde al callback [AvatarCreatorConfig.onSave].
  static const String avatarSave = 'avatar_save';

  /// Sugerido para cuando el avatar se generó y se entregó exitosamente al
  /// canal. Corresponde al callback [AvatarCreatorConfig.onSaveSuccess].
  static const String avatarSaveSuccess = 'avatar_save_success';

  /// Sugerido para cuando ocurrió un error al generar/guardar el avatar.
  /// Corresponde al callback [AvatarCreatorConfig.onSaveError].
  static const String avatarSaveError = 'avatar_save_error';
}
