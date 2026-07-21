import 'package:flutter/widgets.dart';

import 'avatar_creator_result.dart';
import 'avatar_layer_category.dart';

/// Conjunto de ajustes que el canal (la app que embebe este widget) puede
/// personalizar al mostrar el creador de avatar.
///
/// Esta clase es, en la práctica, **el contrato entre la librería y el
/// canal**: todo lo que el canal puede influir sin tener que tocar el
/// código interno del paquete pasa por aquí. Todo lo que *no* está en esta
/// clase (por ejemplo, el orden de las categorías, cómo se ve cada tab, o
/// el diseño del preview) está fijado por la librería a propósito, porque
/// forma parte de la especificación de diseño de Bancolombia y no debe
/// variar entre canales.
///
/// Se marca con `@immutable` (una anotación informativa de Flutter, no una
/// palabra clave del lenguaje) para documentar la intención de que, una vez
/// creada, una instancia de [AvatarCreatorConfig] nunca cambia: si el canal
/// necesita otro comportamiento, crea una instancia nueva en vez de mutar
/// esta.
///
/// ### Los dos casos de uso principales
/// * **Avatar nuevo**: el canal no pasa [initialSelection] (queda `null`).
///   El widget preselecciona la primera opción de cada categoría.
/// * **Editar avatar existente**: el canal ya sabe qué había elegido el
///   usuario la última vez (porque el propio canal lo guardó, ver
///   [AvatarCreatorResult]) y se lo entrega al widget en [initialSelection].
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

  /// Catálogo de categorías a usar. Si se deja en `null` (el caso normal),
  /// la pantalla usa [defaultAvatarCatalog], el catálogo oficial definido
  /// por esta librería.
  ///
  /// Existe principalmente para pruebas y para escenarios muy particulares;
  /// en un canal de producción normalmente **no** se debería sobreescribir,
  /// porque el orden y contenido del catálogo responden a una especificación
  /// de diseño ya validada, no a una preferencia libre de cada canal.
  final List<AvatarLayerCategory>? categories;

  /// Selección con la que debe abrir el widget, expresada como un
  /// `Future` que resuelve a un mapa `categoryId -> optionId` (por ejemplo,
  /// `{'face': 'face-3', 'hair': 'hair-1', 'background': 'green'}`).
  ///
  /// ### ¿Por qué un `Future` y no un mapa directo?
  /// Leer una selección guardada previamente casi siempre implica una
  /// operación asíncrona por parte del canal — típicamente, leer un valor de
  /// `SharedPreferences` (`SharedPreferences.getInstance()` ya es async por
  /// sí mismo) o de una base de datos local. En vez de forzar al canal a
  /// resolver esa lectura *antes* de poder construir la
  /// [AvatarCreatorConfig], el widget acepta directamente el `Future` en
  /// curso y se encarga de esperarlo (mostrando un estado de carga mientras
  /// tanto) antes de mostrar la pantalla completa.
  ///
  /// Ejemplo típico usando `shared_preferences`:
  /// ```dart
  /// Future<Map<String, String>> _leerSeleccionGuardada() async {
  ///   final prefs = await SharedPreferences.getInstance();
  ///   final json = prefs.getString('avatar_selection');
  ///   if (json == null) return {};
  ///   return Map<String, String>.from(jsonDecode(json) as Map);
  /// }
  ///
  /// AvatarCreatorConfig(initialSelection: _leerSeleccionGuardada());
  /// ```
  ///
  /// Si se deja en `null` (caso "avatar nuevo"), el widget preselecciona
  /// automáticamente la primera opción de cada categoría, sin esperar nada.
  ///
  /// El mapa que resuelve este `Future` tiene exactamente la misma forma que
  /// [AvatarCreatorResult.selection]: es "el mismo array" yendo en sentido
  /// contrario, listo para guardarse tal cual (por ejemplo, codificado a
  /// JSON con `jsonEncode(...)`) en `SharedPreferences` o cualquier otro
  /// almacenamiento que use el canal.
  final Future<Map<String, String>>? initialSelection;

  /// Título mostrado en la barra superior (`AppBar`) de la pantalla.
  final String title;

  /// Texto accesible (tooltip / lector de pantalla) del botón de volver de
  /// la barra superior.
  final String backButtonLabel;

  /// Texto del botón principal del pie de pantalla ("Guardar" por defecto).
  final String saveButtonText;

  /// Texto del botón secundario del pie de pantalla ("Cancelar" por
  /// defecto). Solo se usa si [secondaryButtonEnabled] es `true`.
  final String cancelButtonText;

  /// Si es `false`, el botón secundario ("Cancelar") del pie de pantalla no
  /// se muestra en absoluto — solo queda el botón principal ("Guardar").
  /// Útil, por ejemplo, en flujos donde el canal quiere forzar a que el
  /// usuario complete la creación del avatar y no pueda simplemente
  /// cancelar.
  final bool secondaryButtonEnabled;

  /// ### Callbacks: el punto de extensión principal de la librería
  ///
  /// Todos los campos siguientes son funciones opcionales (`VoidCallback`,
  /// `ValueChanged<T>`) que el canal puede proveer para enterarse de lo que
  /// pasa dentro del widget, **sin que la librería necesite saber nada**
  /// sobre analítica, persistencia, o cualquier otra lógica específica del
  /// canal. Esta es la técnica que le permite a `avatar_flutter` no
  /// depender de ningún paquete de analítica, red o base de datos: en vez de
  /// llamar directamente a, por ejemplo, `Analytics.track(...)`, el widget
  /// simplemente invoca el callback que el canal le haya dado (si dio uno;
  /// todos son opcionales y se llaman con `?.call()`, que no hace nada si el
  /// callback es `null`).
  ///
  /// Los nombres de evento sugeridos para tagueo/analítica viven en
  /// [AvatarAnalyticsEvents], pero son solo una **guía de nombres** — la
  /// librería nunca dispara ningún evento de analítica por sí misma. Es
  /// responsabilidad exclusiva del canal decidir si, cuándo y cómo registrar
  /// estos eventos.
  ///
  /// Se llama justo después de que la pantalla termina de construirse por
  /// primera vez (equivalente a "el usuario ya está viendo el creador de
  /// avatar").
  final VoidCallback? onView;

  /// Se llama en el instante en que el usuario toca el botón "Guardar",
  /// antes de saber si el guardado tendrá éxito o no.
  final VoidCallback? onSave;

  /// Se llama cuando el guardado terminó con éxito, con el
  /// [AvatarCreatorResult] resultante (selección final + imagen generada).
  /// Este es el momento en el que, típicamente, el canal tomaría
  /// `result.imageBytes` y `result.selection` y las persistiría según su
  /// propia lógica (ver la documentación de [AvatarCreatorResult.selection]).
  final ValueChanged<AvatarCreatorResult>? onSaveSuccess;

  /// Se llama cuando ocurre un error durante el guardado (por ejemplo, si no
  /// fue posible capturar la imagen del preview, o si el `Future` de
  /// [initialSelection] terminó en error). Recibe el error tal cual fue
  /// lanzado internamente.
  final ValueChanged<Object>? onSaveError;

  /// Se llama cuando el usuario cancela o cierra la pantalla sin guardar.
  /// En ese caso, cualquier cambio hecho durante la sesión de edición se
  /// descarta: el canal no recibe ningún resultado.
  final VoidCallback? onCancel;
}
