import 'package:avatar_flutter/avatar_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

AvatarLayerCategory _backgroundCategory(String id, List<String> optionIds) {
  return AvatarLayerCategory(
    id: id,
    label: id,
    icon: Icons.circle,
    kind: AvatarCategoryKind.layer,
    isBackground: true,
    options: [
      for (final optionId in optionIds)
        AvatarOption.color(id: optionId, color: Colors.primaries[optionIds.indexOf(optionId)]),
    ],
  );
}

AvatarLayerCategory _layerCategory(String id, List<String> optionIds) {
  return AvatarLayerCategory(
    id: id,
    label: id,
    icon: Icons.circle,
    kind: AvatarCategoryKind.layer,
    options: [
      for (final optionId in optionIds)
        AvatarOption.layer(id: optionId, assetPath: 'assets/avatar/$id/$optionId.svg'),
    ],
  );
}

AvatarLayerCategory _layerWithColorCategory(
  String id,
  List<String> optionIds,
  List<String> colorOptionIds,
) {
  return AvatarLayerCategory(
    id: id,
    label: id,
    icon: Icons.circle,
    kind: AvatarCategoryKind.layerWithColor,
    colorSectionLabel: 'Color de $id',
    shapeSectionLabel: 'Forma de $id',
    options: [
      for (final optionId in optionIds)
        AvatarOption.layer(
          id: optionId,
          assetPath: 'assets/avatar/$id/Color={color}, Shape=$optionId.svg',
        ),
    ],
    colorOptions: [
      for (final optionId in colorOptionIds)
        AvatarOption.color(
          id: optionId,
          color: Colors.primaries[colorOptionIds.indexOf(optionId)],
        ),
    ],
  );
}

void main() {
  // `GlobalKey.currentContext` (usado por `save()` para encontrar el
  // `RepaintBoundary` del preview) internamente lee `WidgetsBinding.instance`,
  // así que se necesita inicializar el binding incluso en los tests de más
  // abajo que nunca "pintan" un widget de verdad (`tester.pumpWidget`).
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AvatarCreatorController', () {
    late List<AvatarLayerCategory> categories;

    setUp(() {
      categories = [
        _layerCategory('body', ['body-1', 'body-2']),
        _layerWithColorCategory('hair', ['hair-1', 'hair-2'], ['gray', 'purple']),
        _backgroundCategory('background', ['green', 'blue']),
      ];
    });

    test('preselects the first shape and color option of every category by default', () {
      final controller = AvatarCreatorController(categories: categories);

      expect(controller.selectedOptionFor('body').id, 'body-1');
      expect(controller.selectedOptionFor('hair').id, 'hair-1');
      expect(controller.selectedColorOptionFor('hair')?.id, 'gray');
      expect(controller.selectedOptionFor('background').id, 'green');
      expect(controller.activeCategoryId, 'body');
    });

    test('selectedColorOptionFor returns null for categories without colorOptions', () {
      final controller = AvatarCreatorController(categories: categories);

      expect(controller.selectedColorOptionFor('body'), isNull);
    });

    test('respects an initial selection provided by the channel', () {
      final controller = AvatarCreatorController(
        categories: categories,
        initialSelection: const {
          'body': 'body-2',
          'hair': 'hair-2',
          'hair_color': 'purple',
          'background': 'blue',
        },
      );

      expect(controller.selectedOptionFor('body').id, 'body-2');
      expect(controller.selectedColorOptionFor('hair')?.id, 'purple');
      expect(controller.backgroundColor, Colors.primaries[1]);
    });

    test('selectOption updates the shape selection without touching the color selection', () {
      final controller = AvatarCreatorController(categories: categories);
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.selectOption('hair', 'hair-2');

      expect(controller.selectedOptionFor('hair').id, 'hair-2');
      expect(controller.selectedColorOptionFor('hair')?.id, 'gray');
      expect(notifications, 1);
      // Other categories keep their selection.
      expect(controller.selectedOptionFor('body').id, 'body-1');
    });

    test('selectColorOption updates the color selection without touching the shape selection', () {
      final controller = AvatarCreatorController(categories: categories);
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.selectColorOption('hair', 'purple');

      expect(controller.selectedColorOptionFor('hair')?.id, 'purple');
      expect(controller.selectedOptionFor('hair').id, 'hair-1');
      expect(notifications, 1);
    });

    test('selectCategory switches the active tab without touching selections', () {
      final controller = AvatarCreatorController(categories: categories);
      controller.selectOption('body', 'body-2');

      controller.selectCategory('hair');

      expect(controller.activeCategoryId, 'hair');
      expect(controller.selectedOptionFor('body').id, 'body-2');
    });

    test('layerAssetPaths excludes the background category and resolves the shape+color combination', () {
      final controller = AvatarCreatorController(categories: categories);
      controller.selectColorOption('hair', 'purple');

      expect(controller.layerAssetPaths, [
        'assets/avatar/body/body-1.svg',
        'assets/avatar/hair/Color=purple, Shape=hair-1.svg',
      ]);
    });

    test('resolveAssetPath returns null when the shape option is actually a pure color option', () {
      // Regresión: la cuadrícula de "Color de fondo" reutiliza el mismo
      // AvatarOptionGrid que las categorías ilustradas, así que
      // AvatarCreatorScreen le pasa un resolveAssetPath incondicionalmente.
      // Antes, llamar a resolveAssetPath sobre una opción de color (sin
      // assetPath) lanzaba "Null check operator used on a null value".
      final background = _backgroundCategory('background', ['green', 'blue']);
      final greenOption = background.optionById('green');

      expect(background.resolveAssetPath(greenOption, null), isNull);
    });

    test('resolveAssetPath returns null for an AvatarOption.none', () {
      const category = AvatarLayerCategory(
        id: 'extra',
        label: 'Accesorios',
        icon: Icons.circle,
        kind: AvatarCategoryKind.layer,
        options: [
          AvatarOption.none(id: 'none', semanticLabel: 'Sin accesorios'),
          AvatarOption.layer(id: 'style-1', assetPath: 'assets/avatar/extra/style-1.svg'),
        ],
      );

      expect(category.resolveAssetPath(category.optionById('none'), null), isNull);
    });

    test('a category whose default option is AvatarOption.none contributes no layer until a real style is chosen', () {
      final categoriesWithOptionalExtra = [
        ...categories,
        const AvatarLayerCategory(
          id: 'extra',
          label: 'Accesorios',
          icon: Icons.circle,
          kind: AvatarCategoryKind.layer,
          options: [
            AvatarOption.none(id: 'none', semanticLabel: 'Sin accesorios'),
            AvatarOption.layer(id: 'style-1', assetPath: 'assets/avatar/extra/style-1.svg'),
          ],
        ),
      ];
      final controller = AvatarCreatorController(categories: categoriesWithOptionalExtra);

      expect(controller.selectedOptionFor('extra').id, 'none');
      expect(
        controller.layerAssetPaths.any((path) => path.contains('extra')),
        isFalse,
      );

      controller.selectOption('extra', 'style-1');

      expect(controller.layerAssetPaths, contains('assets/avatar/extra/style-1.svg'));
    });

    test('save() surfaces a StateError and records it when the preview is not mounted', () async {
      final controller = AvatarCreatorController(categories: categories);

      await expectLater(controller.save(), throwsA(isA<StateError>()));
      expect(controller.saveError, isA<StateError>());
      expect(controller.isSaving, isFalse);
    });

    test('clearSaveError resets the error state', () async {
      final controller = AvatarCreatorController(categories: categories);
      await expectLater(controller.save(), throwsA(isA<StateError>()));

      controller.clearSaveError();

      expect(controller.saveError, isNull);
    });
  });
}
