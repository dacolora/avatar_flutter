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

/// Pantalla del creador de avatar (#1 Header, #2/#3 Preview, #4/#5
/// Categorías, #6/#7/#8 Opciones, #9 Footer). Punto de entrada único del
/// widget: el canal decide desde dónde se dispara (ej. botón de edición de
/// avatar en el perfil).
class AvatarCreatorScreen extends StatefulWidget {
  const AvatarCreatorScreen({
    this.config = const AvatarCreatorConfig(),
    super.key,
  });

  final AvatarCreatorConfig config;

  /// Atajo para embeber el widget como una pantalla completa. Devuelve el
  /// [AvatarCreatorResult] al guardar, o `null` si el usuario cancela/cierra
  /// sin guardar.
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
  late final AvatarCreatorController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AvatarCreatorController(
      categories: widget.config.categories ?? defaultAvatarCatalog(),
      initialSelection: widget.config.initialSelection,
    );
    SchedulerBinding.instance.addPostFrameCallback((_) {
      widget.config.onView?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    widget.config.onSave?.call();
    try {
      final result = await _controller.save();
      widget.config.onSaveSuccess?.call(result);
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

  void _handleCancel() {
    widget.config.onCancel?.call();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AvatarCreatorController>.value(
      value: _controller,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.config.title),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            tooltip: widget.config.backButtonLabel,
            onPressed: _handleCancel,
          ),
        ),
        body: Consumer<AvatarCreatorController>(
          builder: (context, controller, _) {
            final activeCategory = controller.activeCategory;
            final selectedOptionId =
                controller.selection.selectedOptionFor(activeCategory.id);

            return Column(
              children: [
                const AvatarPreview(),
                const AvatarCategoryTabs(),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: controller.isSaving ? null : _handleSave,
                            child: Text(widget.config.saveButtonText),
                          ),
                        ),
                        if (widget.config.secondaryButtonEnabled) ...[
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: _handleCancel,
                              child: Text(widget.config.cancelButtonText),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
