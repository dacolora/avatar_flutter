import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'controllers/avatar_creator_controller.dart';
import 'controllers/avatar_creator_scope.dart';
import 'data/avatar_catalog.dart';
import 'models/avatar_creator_config.dart';
import 'models/avatar_layer_category.dart';
import 'widgets/avatar_category_tabs.dart';
import 'widgets/avatar_option_grid.dart';
import 'widgets/avatar_option_row.dart';
import 'widgets/avatar_preview.dart';
import 'widgets/avatar_section_label.dart';

/// Pantalla completa del creador de avatar y **punto de entrada único** de
/// esta librería.
///
/// Si vas a usar `avatar_flutter` desde un canal, esta es prácticamente la
/// única clase con la que necesitas interactuar directamente: le pasas una
/// [AvatarCreatorConfig] (opcional) y ella se encarga de todo lo demás
/// (esperar la selección inicial si viene de un `Future`, armar el
/// controlador, mostrar el header, el preview, los tabs de categorías, las
/// opciones y el pie con los botones de guardar/cancelar).
///
/// Internamente compone, de arriba a abajo, las piezas numeradas en la
/// especificación de diseño "WID - Avatar - APP": header (#1), fondo +
/// preview (#2/#3), tabs de categorías (#4/#5), etiqueta de sección y
/// opciones (#6/#7/#8), y pie de botones (#9). Cada una de esas piezas vive
/// en su propio widget (ver `widgets/`); esta clase solo las organiza.
class AvatarCreatorScreen extends StatefulWidget {
  const AvatarCreatorScreen({
    this.config = const AvatarCreatorConfig(),
    super.key,
  });

  /// Ajustes personalizables por el canal. Si no se especifica, se usan
  /// todos los valores por defecto de [AvatarCreatorConfig] (catálogo
  /// oficial, sin selección inicial, textos por defecto en español).
  final AvatarCreatorConfig config;

  /// Atajo para abrir esta pantalla como una ruta nueva (usa el sistema de
  /// navegación estándar de Flutter, `Navigator`), pensado para que el canal
  /// no tenga que escribir el `Navigator.push(MaterialPageRoute(...))` a
  /// mano cada vez.
  ///
  /// Devuelve un `Future` que se completa cuando el usuario sale de la
  /// pantalla:
  /// * Con un [AvatarCreatorResult] si guardó el avatar exitosamente.
  /// * Con `null` si canceló o cerró sin guardar.
  ///
  /// Ejemplo de uso típico desde un canal:
  /// ```dart
  /// final resultado = await AvatarCreatorScreen.push(context, config: miConfig);
  /// if (resultado is AvatarCreatorResult) {
  ///   // el canal decide qué hacer con resultado.imageBytes y resultado.selection
  /// }
  /// ```
  static Future<Object?> push(
    BuildContext context, {
    AvatarCreatorConfig config = const AvatarCreatorConfig(),
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AvatarCreatorScreen(config: config)),
    );
  }

  @override
  State<AvatarCreatorScreen> createState() => _AvatarCreatorScreenState();
}

class _AvatarCreatorScreenState extends State<AvatarCreatorScreen> {
  AvatarCreatorController? _controller;
  Object? _loadError;

  @override
  void initState() {
    super.initState();
    final future = widget.config.initialSelection;
    if (future == null) {
      // Caso "avatar nuevo": no hay nada que esperar. Aquí se asigna
      // `_controller` directamente como campo (**sin** llamar a
      // `setState`), porque estamos dentro de `initState`, antes de que
      // `build` se ejecute por primera vez — Flutter ya va a leer este
      // valor en el primer `build`, así que llamar a `setState` aquí sería
      // redundante y, peor, puede disparar el error "setState() called
      // during build" si el framework todavía está construyendo este mismo
      // widget en ese instante.
      _controller = _buildController(null);
      _scheduleOnView();
    } else {
      _awaitInitialSelection(future);
    }
  }

  AvatarCreatorController _buildController(
      Map<String, String>? initialSelection) {
    return AvatarCreatorController(
      categories: widget.config.categories ?? defaultAvatarCatalog(),
      initialSelection: initialSelection,
    );
  }

  /// Programa `config.onView` para ejecutarse justo después de que Flutter
  /// termine de pintar el primer frame con el controlador ya listo. Se hace
  /// así (en vez de llamar al callback directamente) para no invocarlo en
  /// mitad de la construcción del árbol de widgets, y para garantizar que,
  /// cuando se dispare, el usuario ya está viendo la pantalla completa.
  void _scheduleOnView() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      widget.config.onView?.call();
    });
  }

  /// Espera el `Future` de [AvatarCreatorConfig.initialSelection] y, con ese
  /// resultado, crea el [AvatarCreatorController] de la sesión.
  ///
  /// A diferencia del caso sin `Future` (manejado directamente en
  /// [initState]), aquí sí es seguro llamar a `setState`: un `await`, incluso
  /// sobre un `Future` que ya estaba resuelto, siempre reanuda su código en
  /// una tarea posterior (un "microtask"), nunca en la misma pila de
  /// llamadas síncrona que disparó `initState`/`build`. Por eso, para
  /// cuando este código se ejecuta, el framework ya terminó de construir el
  /// primer frame y `setState` es completamente seguro de llamar.
  Future<void> _awaitInitialSelection(
      Future<Map<String, String>> future) async {
    try {
      final initialSelection = await future;
      if (!mounted) return;
      setState(() => _controller = _buildController(initialSelection));
      _scheduleOnView();
    } catch (error) {
      widget.config.onSaveError?.call(error);
      if (mounted) setState(() => _loadError = error);
    }
  }

  @override
  void dispose() {
    // Todo `ChangeNotifier` que creas manualmente (con `AvatarCreatorController(...)`,
    // no a través de un widget que lo cree por ti) debe liberarse
    // explícitamente con `dispose()` cuando ya no se necesita, para que
    // Flutter pueda limpiar sus listeners internos y evitar fugas de
    // memoria.
    _controller?.dispose();
    super.dispose();
  }

  /// Maneja el toque del botón "Guardar" del pie de pantalla.
  Future<void> _handleSave(AvatarCreatorController controller) async {
    widget.config.onSave?.call();
    try {
      final result = await controller.save();
      widget.config.onSaveSuccess?.call(result);
      // `mounted` es `true` mientras este `State` sigue formando parte del
      // árbol de widgets. Como `save()` es asíncrono, es posible que el
      // usuario haya salido de la pantalla mientras se generaba la imagen;
      // sin esta comprobación, `Navigator.of(context)` podría fallar porque
      // `context` ya no correspondería a un widget visible.
      if (mounted) Navigator.of(context).pop(result);
    } catch (error) {
      widget.config.onSaveError?.call(error);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Algo salió mal al guardar')),
        );
      }
    }
  }

  /// Maneja el toque del botón de volver del header (única forma de
  /// cancelar; el footer solo tiene el botón "Guardar"). Según las reglas de
  /// uso de la especificación, cancelar descarta cualquier cambio hecho
  /// durante esta sesión: como el
  /// controlador (y su selección en memoria) se destruye junto con esta
  /// pantalla en [dispose], no hace falta "revertir" nada manualmente —
  /// simplemente nunca se llega a llamar a
  /// [AvatarCreatorConfig.onSaveSuccess], así que el canal nunca se entera
  /// de una selección que el usuario no confirmó.
  void _handleCancel() {
    widget.config.onCancel?.call();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    // Mientras se espera el `Future<Map<String, String>>?` de
    // `initialSelection` (por ejemplo, mientras el canal lee
    // `SharedPreferences`), todavía no hay controlador: se muestra un
    // indicador de carga (o el error, si la lectura falló) en vez de la
    // pantalla completa.
    if (controller == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.config.title)),
        body: Center(
          child: _loadError != null
              ? const Text('No fue posible cargar la selección guardada')
              : const CircularProgressIndicator(),
        ),
      );
    }

    // `AvatarCreatorScope` reemplaza a `ChangeNotifierProvider` (del paquete
    // `provider`): expone `controller` a los descendientes sin depender de
    // ningún paquete externo (ver el comentario de esa clase). El `Builder`
    // de adentro es necesario para obtener un `BuildContext` que esté
    // *debajo* del `AvatarCreatorScope` — si se usara directamente el
    // `context` de este método `build`, `AvatarCreatorScope.of(context)`
    // buscaría hacia arriba y no encontraría este mismo scope, ya que
    // todavía no ha terminado de insertarse en el árbol.
    return AvatarCreatorScope(
      controller: controller,
      child: Builder(
        builder: (context) {
          // Llamar aquí a `AvatarCreatorScope.of(context)` (en vez de usar
          // directamente la variable `controller` de más arriba) es lo que
          // hace que este `Builder` se reconstruya automáticamente cada vez
          // que el controlador notifique un cambio — exactamente el mismo
          // efecto que tenía antes `context.watch<AvatarCreatorController>()`
          // con `provider`.
          final controller = AvatarCreatorScope.of(context);
          final activeCategory = controller.activeCategory;
          final selectedOptionId =
              controller.selection.selectedOptionFor(activeCategory.id);
          final isLayerWithColor =
              activeCategory.kind == AvatarCategoryKind.layerWithColor;
          final selectedColorOptionId = isLayerWithColor
              ? controller.selectedColorOptionFor(activeCategory.id)?.id
              : null;

          return Scaffold(
            appBar: AppBar(
              title: Text(widget.config.title),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new),
                tooltip: widget.config.backButtonLabel,
                onPressed: _handleCancel,
              ),
            ),
            backgroundColor: Colors.white,
            // El `body` se arma con tres slivers dentro de un
            // `CustomScrollView`, para lograr el comportamiento de scroll
            // que pide la especificación:
            //
            // 1. El preview: un `SliverPersistentHeader` fijo (`pinned:
            //    true`) que se va encogiendo a medida que el usuario baja
            //    (sin llegar nunca a desaparecer del todo) y vuelve a
            //    expandirse al subir — ver [AvatarPreview.expansion].
            // 2. Los tabs de categoría: otro `SliverPersistentHeader` fijo,
            //    pero de alto constante (`minExtent == maxExtent`), así que
            //    no se encoge — solo queda pegado justo debajo del preview,
            //    sin importar cuánto se haya scrolleado.
            // 3. El resto (etiqueta de sección + opciones): un
            //    `SliverToBoxAdapter` normal, que es la única parte que en
            //    verdad se desplaza fuera de la pantalla al hacer scroll.
            //
            // Igual que con el `SingleChildScrollView` que se usaba antes,
            // esto sigue evitando cualquier `Expanded`: un `CustomScrollView`
            // como `body` de un `Scaffold` simplemente ocupa la altura que
            // le den (aunque esa altura fluctúe momentáneamente, como pasa
            // en Safari/iOS cuando la barra de direcciones aparece u
            // desaparece), sin que ninguno de sus slivers deba repartirse
            // una porción fija de esa altura y arriesgarse a colapsar a
            // 0px — el contenido siempre sigue siendo alcanzable con
            // scroll, sin importar la altura real disponible en cada
            // momento.
            body: CustomScrollView(
              slivers: [
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SliverHeaderDelegate(
                    minExtent: widget.config.previewCollapsedHeight,
                    maxExtent: widget.config.previewExpandedHeight,
                    builder: (context, shrinkOffset) {
                      final range = widget.config.previewExpandedHeight -
                          widget.config.previewCollapsedHeight;
                      // Si el canal configura el mismo alto para ambos
                      // extremos, `range` es 0 — se trata como "sin
                      // encogimiento" en vez de dividir por cero.
                      final expansion = range <= 0
                          ? 1.0
                          : 1 - (shrinkOffset / range).clamp(0.0, 1.0);
                      return AvatarPreview(
                        expandedHeight: widget.config.previewExpandedHeight,
                        collapsedHeight: widget.config.previewCollapsedHeight,
                        expansion: expansion,
                      );
                    },
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SliverHeaderDelegate(
                    minExtent: AvatarCategoryTabs.height,
                    maxExtent: AvatarCategoryTabs.height,
                    builder: (context, shrinkOffset) =>
                        const AvatarCategoryTabs(),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Las categorías de tipo `layerWithColor` (Cabello,
                      // Rostro) muestran una sección extra antes de la
                      // cuadrícula: la fila de color (`colorOptions`), tal
                      // como lo pide la especificación — ver el comentario
                      // de [AvatarCategoryKind.layerWithColor]. Las
                      // categorías simples (Vestuario, Accesorios, Color de
                      // fondo) van directo a la cuadrícula.
                      if (isLayerWithColor) ...[
                        AvatarSectionLabel(
                            label: activeCategory.colorSectionLabel!),
                        AvatarOptionRow(
                          options: activeCategory.colorOptions!,
                          selectedOptionId: selectedColorOptionId,
                          maxOptions: widget.config.maxRowOptions,
                          onSelected: (optionId) =>
                              controller.selectColorOption(
                            activeCategory.id,
                            optionId,
                          ),
                        ),
                        AvatarSectionLabel(
                          label: activeCategory.shapeSectionLabel ??
                              activeCategory.label,
                        ),
                      ] else
                        AvatarSectionLabel(label: activeCategory.label),
                      AvatarOptionGrid(
                        options: activeCategory.options,
                        selectedOptionId: selectedOptionId,
                        crossAxisCount: widget.config.gridCrossAxisCount,
                        maxOptions: widget.config.maxGridOptions,
                        // `resolveThumbnailAssetPath` combina la forma de
                        // cada opción con el color actualmente elegido en
                        // esta categoría (si tiene uno, ver
                        // [AvatarLayerCategory.colorOptions]). Para
                        // categorías sin fila de color,
                        // `selectedColorOptionFor` devuelve `null` y
                        // `resolveThumbnailAssetPath` simplemente deja la
                        // ruta de la miniatura intacta — por eso este mismo
                        // callback sirve para ambos casos.
                        resolveThumbnailAssetPath: (option) =>
                            activeCategory.resolveThumbnailAssetPath(
                          option,
                          controller.selectedColorOptionFor(activeCategory.id),
                        ),
                        onSelected: (optionId) => controller.selectOption(
                          activeCategory.id,
                          optionId,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
            // El pie de botones se ubica en `bottomNavigationBar` (en vez de
            // como último elemento dentro del `body`) precisamente para que
            // quede siempre fijo en la parte inferior de la pantalla, fuera
            // del área que hace scroll, tal como lo pide la especificación
            // (#9 Footer siempre visible). Solo tiene el botón "Guardar" —
            // cancelar se hace desde el botón de volver del header (ver
            // [_handleCancel]).
            bottomNavigationBar: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: controller.isSaving
                        ? null
                        : () => _handleSave(controller),
                    child: Text(widget.config.saveButtonText),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Firma del `builder` de [_SliverHeaderDelegate]: recibe cuánto se ha
/// "encogido" el header (0 = totalmente expandido, en su [maxExtent];
/// [_SliverHeaderDelegate.maxExtent] menos [_SliverHeaderDelegate.minExtent]
/// = totalmente encogido) y devuelve el widget a mostrar en ese punto.
typedef _SliverHeaderBuilder = Widget Function(
  BuildContext context,
  double shrinkOffset,
);

/// Adapta cualquier widget para usarlo como header fijo (`pinned`) dentro de
/// un `CustomScrollView`, sin tener que escribir una subclase de
/// `SliverPersistentHeaderDelegate` por cada header — [AvatarCreatorScreen]
/// la usa dos veces: una para el preview (que sí se encoge,
/// `minExtent != maxExtent`) y otra para los tabs de categoría (que no se
/// encogen, `minExtent == maxExtent`).
///
/// ### ¿Qué hace un `SliverPersistentHeaderDelegate`?
/// Es la pieza que un `SliverPersistentHeader` necesita para saber, en todo
/// momento del scroll, qué tan alto debe medir su contenido y qué dibujar
/// en ese alto. Flutter llama a [build] en cada frame relevante del scroll,
/// pasándole `shrinkOffset` — cuántos píxeles del [maxExtent] original ya
/// se "comió" el scroll — para que el `builder` decida cómo verse en ese
/// punto exacto (en este archivo, [AvatarPreview] usa ese valor para
/// calcular su propio nivel de "expansión", ver
/// [AvatarPreview.expansion]). Con `pinned: true` en el `SliverPersistentHeader`
/// que lo usa, el header nunca se desplaza fuera de la pantalla: como
/// mucho, se encoge hasta [minExtent] y se queda ahí, fijo, mientras el
/// resto del contenido sigue haciendo scroll por debajo.
class _SliverHeaderDelegate extends SliverPersistentHeaderDelegate {
  _SliverHeaderDelegate({
    required this.minExtent,
    required this.maxExtent,
    required this.builder,
  });

  @override
  final double minExtent;

  @override
  final double maxExtent;

  final _SliverHeaderBuilder builder;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return builder(context, shrinkOffset);
  }

  /// Le dice a Flutter si debe volver a llamar a [build] cuando el
  /// `SliverPersistentHeader` que usa este delegate se reconstruye con una
  /// instancia nueva (por ejemplo, cada vez que el usuario elige una
  /// opción distinta y `AvatarCreatorScreen` se reconstruye). Siempre
  /// devuelve `true`: como [builder] se crea de nuevo en cada
  /// reconstrucción de la pantalla (no hay forma barata de comparar "¿el
  /// contenido que produce cambió?"), la opción segura es asumir que sí
  /// pudo cambiar. El costo de reconstruir de más un header pequeño es
  /// insignificante comparado con el riesgo de dejar el preview o los tabs
  /// mostrando una selección vieja.
  @override
  bool shouldRebuild(covariant _SliverHeaderDelegate oldDelegate) => true;
}
