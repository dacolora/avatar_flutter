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
            // Nota importante de diseño: todo el contenido del `body` vive
            // dentro de un único `SingleChildScrollView`, sin ningún
            // `Expanded` de por medio. Esto no es una preferencia de estilo:
            // en pantallas donde la altura disponible varía dinámicamente
            // (típicamente Safari en iOS, cuando la barra de direcciones se
            // muestra u oculta al hacer scroll), un `Expanded` que depende
            // de la altura del `body` de un `Scaffold` puede colapsar
            // momentáneamente a 0 píxeles de alto, dejando las opciones
            // invisibles aunque el código sea "correcto" en el resto de
            // plataformas. Usando un solo scroll para toda la pantalla, el
            // contenido siempre es alcanzable deslizando el dedo,
            // independientemente de cuánta altura real haya disponible.
            body: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AvatarPreview(),
                  const AvatarCategoryTabs(),
                  // Las categorías de tipo `layerWithColor` (Cabello, Rostro)
                  // muestran una sección extra antes de la cuadrícula: la
                  // fila de color (`colorOptions`), tal como lo pide la
                  // especificación — ver el comentario de
                  // [AvatarCategoryKind.layerWithColor]. Las categorías
                  // simples (Vestuario, Accesorios, Color de fondo) van
                  // directo a la cuadrícula.
                  if (isLayerWithColor) ...[
                    AvatarSectionLabel(
                        label: activeCategory.colorSectionLabel!),
                    AvatarOptionRow(
                      options: activeCategory.colorOptions!,
                      selectedOptionId: selectedColorOptionId,
                      onSelected: (optionId) => controller.selectColorOption(
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
                    // `resolveAssetPath` combina la forma de cada opción con
                    // el color actualmente elegido en esta categoría (si
                    // tiene uno, ver [AvatarLayerCategory.colorOptions]).
                    // Para categorías sin fila de color,
                    // `selectedColorOptionFor` devuelve `null` y
                    // `resolveAssetPath` simplemente deja `option.assetPath`
                    // intacto — por eso este mismo callback sirve para
                    // ambos casos.
                    resolveAssetPath: (option) => activeCategory.resolveAssetPath(
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
