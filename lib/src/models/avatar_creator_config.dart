import 'package:flutter/widgets.dart';

import 'avatar_creator_result.dart';
import 'avatar_layer_category.dart';
import 'avatar_selection.dart';

/// Configuración que el canal puede ajustar al embeber el widget.
///
/// Respeta las "Reglas de uso" de la especificación: el orden y la lista de
/// categorías vienen de la documentación del widget (no son libres), pero el
/// canal puede sobreescribir textos, la selección inicial (para editar un
/// avatar ya existente), habilitar/deshabilitar el botón secundario y
/// engancharse a los eventos sugeridos de tagueo sin que el widget los dispare
/// automáticamente.
@immutable
class AvatarCreatorConfig {
  const AvatarCreatorConfig({
    this.categories,
    this.initialSelection,
    this.title = 'Crear avatar',
    this.backButtonLabel = '',
    this.saveButtonText = 'Guardar',
    this.cancelButtonText = 'Cancelar',
    this.secondaryButtonEnabled = true,
    this.onView,
    this.onSave,
    this.onSaveSuccess,
    this.onSaveError,
    this.onCancel,
  });

  /// Catálogo de categorías a usar. Si es `null`, se usa
  /// [defaultAvatarCatalog]. El orden de la lista define el orden de los
  /// tabs y no debería reordenarse sin validarlo con el equipo de diseño.
  final List<AvatarLayerCategory>? categories;

  /// Selección con la que abre el widget (caso "editar avatar existente").
  /// Si es `null`, se preselecciona la primera opción de cada categoría.
  final AvatarSelection? initialSelection;

  final String title;
  final String backButtonLabel;
  final String saveButtonText;
  final String cancelButtonText;

  /// Habilita/deshabilita el botón secundario ("Cancelar") del footer.
  final bool secondaryButtonEnabled;

  /// Hooks de tagueo sugeridos (avatar_creator_view / avatar_save /
  /// avatar_save_success / avatar_save_error). El widget nunca los dispara
  /// solo; es responsabilidad del canal decidir si y cómo los usa.
  final VoidCallback? onView;
  final VoidCallback? onSave;
  final ValueChanged<AvatarCreatorResult>? onSaveSuccess;
  final ValueChanged<Object>? onSaveError;
  final VoidCallback? onCancel;
}
