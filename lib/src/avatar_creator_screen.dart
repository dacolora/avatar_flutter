import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import 'controllers/avatar_creator_controller.dart';
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
/// (armar el controlador, mostrar el header, el preview, los tabs de
/// categorías, las opciones y el pie con los botones de guardar/cancelar).
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
  ///   // el canal decide qué hacer con resultado.imageBytes
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

/// El "estado" de [AvatarCreatorScreen]. En Flutter, un `StatefulWidget` en
/// sí mismo es inmutable (fíjate que [AvatarCreatorScreen] no tiene ningún
/// campo mutable); todo lo que puede cambiar con el tiempo — como el
/// controlador que se crea una sola vez y sobrevive a reconstrucciones — vive
/// en su clase `State` asociada, que es esta.
class _AvatarCreatorScreenState extends State<AvatarCreatorScreen> {
  /// El controlador de esta sesión de edición. Se crea una única vez en
  /// [initState] (no en [build], que puede ejecutarse muchas veces) para que
  /// conserve la selección del usuario mientras la pantalla siga montada,
  /// sin recrearse en cada reconstrucción del widget.
  late final AvatarCreatorController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AvatarCreatorController(
      categories: widget.config.categories ?? defaultAvatarCatalog(),
      initialSelection: widget.config.initialSelection,
    );
    // `addPostFrameCallback` programa el callback para que se ejecute justo
    // después de que Flutter termine de pintar el primer frame de esta
    // pantalla. Se usa aquí (en vez de llamar a `onView` directamente) para
    // no invocar un callback del canal en mitad de la construcción del
    // árbol de widgets, y para garantizar que, cuando se dispare, el usuario
    // ya está viendo la pantalla completa.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      widget.config.onView?.call();
    });
  }

  @override
  void dispose() {
    // Todo `ChangeNotifier` que creas manualmente (con `AvatarCreatorController(...)`,
    // no a través de un `ChangeNotifierProvider` que lo cree por ti) debe
    // liberarse explícitamente con `dispose()` cuando ya no se necesita, para
    // que Flutter pueda limpiar sus listeners internos y evitar fugas de
    // memoria.
    _controller.dispose();
    super.dispose();
  }

  /// Maneja el toque del botón "Guardar" del pie de pantalla.
  Future<void> _handleSave() async {
    widget.config.onSave?.call();
    try {
      final result = await _controller.save();
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

  /// Maneja el toque del botón "Cancelar" (o del botón de volver del
  /// header). Según las reglas de uso de la especificación, cancelar
  /// descarta cualquier cambio hecho durante esta sesión: como el
  /// controlador (y su [AvatarCreatorController.selection] en memoria) se
  /// destruye junto con esta pantalla en [dispose], no hace falta "revertir"
  /// nada manualmente — simplemente nunca se llega a llamar a
  /// [AvatarCreatorConfig.onSaveSuccess], así que el canal nunca se entera
  /// de una selección que el usuario no confirmó.
  void _handleCancel() {
    widget.config.onCancel?.call();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    // `ChangeNotifierProvider.value` inserta `_controller` en el árbol de
    // widgets para que cualquier descendiente pueda leerlo con
    // `context.watch<AvatarCreatorController>()` sin que se lo tengamos que
    // pasar manualmente widget por widget (esto es "inyección de
    // dependencias" vía el árbol de widgets, la forma habitual de compartir
    // estado en Flutter con el paquete `provider`). Se usa `.value` (en vez
    // de `ChangeNotifierProvider(create: ...)`) porque `_controller` ya fue
    // creado en `initState`, no queremos que el provider cree uno nuevo.
    return ChangeNotifierProvider<AvatarCreatorController>.value(
      value: _controller,
      // `Consumer` reconstruye únicamente el contenido de su `builder` cada
      // vez que el controlador llama a `notifyListeners()`. Es la forma
      // explícita (alternativa a `context.watch` dentro de un widget más
      // pequeño) de decirle a Flutter "esta parte del árbol depende del
      // controlador".
      child: Consumer<AvatarCreatorController>(
        builder: (context, controller, _) {
          final activeCategory = controller.activeCategory;
          final selectedOptionId =
              controller.selection.selectedOptionFor(activeCategory.id);

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
                  AvatarSectionLabel(label: activeCategory.label),
                  if (activeCategory.kind == AvatarCategoryKind.colorRow)
                    AvatarOptionRow(
                      category: activeCategory,
                      selectedOptionId: selectedOptionId,
                      onSelected: (optionId) => controller.selectOption(
                        activeCategory.id,
                        optionId,
                      ),
                    )
                  else
                    AvatarOptionGrid(
                      category: activeCategory,
                      selectedOptionId: selectedOptionId,
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
            // (#9 Footer siempre visible).
            bottomNavigationBar: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: controller.isSaving ? null : _handleSave,
                        child: Text(widget.config.saveButtonText),
                      ),
                    ),
                    // if (widget.config.secondaryButtonEnabled) ...[
                    //   const SizedBox(height: 16),
                    //   SizedBox(
                    //     width: double.infinity,
                    //     child: OutlinedButton(
                    //       onPressed: _handleCancel,
                    //       child: Text(widget.config.cancelButtonText),
                    //     ),
                    //   ),
                    // ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
