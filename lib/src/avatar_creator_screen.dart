import 'package:bds_mobile/bds_tokens/bds_tokens.dart';
import 'package:bds_mobile/foundations/foundations.dart';
import 'package:bds_mobile/organisms/organisms.dart';
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
        appBar: BcHeader(
          type: BcHeaderType.PageHeader,
          title: widget.config.title,
          isEnabledLogo: false,
          itemLeftIcon: BdsFunctionalIcons.ANGLE_LEFT,
          itemLeftLabel: widget.config.backButtonLabel,
          itemLeftOnTap: _handleCancel,
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
                        const SizedBox(height: BdsSpacing.SPACE_S_2),
                      ],
                    ),
                  ),
                ),
                BcButtonsFooter(
                  model: BcButtonsFooterModel(
                    primaryButtonText: widget.config.saveButtonText,
                    secondaryButtonText: widget.config.cancelButtonText,
                    onPrimaryButtonPressed:
                        controller.isSaving ? null : _handleSave,
                    onSecondaryButtonPressed: _handleCancel,
                    primaryButtonEnable: !controller.isSaving,
                    secondaryButtonEnable: widget.config.secondaryButtonEnabled,
                    axis: Axis.vertical,
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
