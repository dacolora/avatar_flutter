import 'package:avatar_flutter/avatar_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

AvatarLayerCategory _colorCategory(String id, List<String> optionIds) {
  return AvatarLayerCategory(
    id: id,
    label: id,
    icon: Icons.circle,
    kind: AvatarCategoryKind.colorRow,
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

void main() {
  group('AvatarCreatorController', () {
    late List<AvatarLayerCategory> categories;

    setUp(() {
      categories = [
        _layerCategory('body', ['body-1', 'body-2']),
        _layerCategory('face', ['face-1']),
        _colorCategory('background', ['green', 'blue']),
      ];
    });

    test('preselects the first option of every category by default', () {
      final controller = AvatarCreatorController(categories: categories);

      expect(controller.selectedOptionFor('body').id, 'body-1');
      expect(controller.selectedOptionFor('face').id, 'face-1');
      expect(controller.selectedOptionFor('background').id, 'green');
      expect(controller.activeCategoryId, 'body');
    });

    test('respects an initial selection provided by the channel', () {
      final controller = AvatarCreatorController(
        categories: categories,
        initialSelection: const AvatarSelection({'body': 'body-2', 'face': 'face-1', 'background': 'blue'}),
      );

      expect(controller.selectedOptionFor('body').id, 'body-2');
      expect(controller.backgroundColor, Colors.primaries[1]);
    });

    test('selectOption updates the selection and notifies listeners', () {
      final controller = AvatarCreatorController(categories: categories);
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.selectOption('body', 'body-2');

      expect(controller.selectedOptionFor('body').id, 'body-2');
      expect(notifications, 1);
      // Other categories keep their selection.
      expect(controller.selectedOptionFor('face').id, 'face-1');
    });

    test('selectCategory switches the active tab without touching selections', () {
      final controller = AvatarCreatorController(categories: categories);
      controller.selectOption('body', 'body-2');

      controller.selectCategory('face');

      expect(controller.activeCategoryId, 'face');
      expect(controller.selectedOptionFor('body').id, 'body-2');
    });

    test('layerAssetPaths only includes layer-kind categories, in catalog order', () {
      final controller = AvatarCreatorController(categories: categories);

      expect(controller.layerAssetPaths, [
        'assets/avatar/body/body-1.svg',
        'assets/avatar/face/face-1.svg',
      ]);
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
