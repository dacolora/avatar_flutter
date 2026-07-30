import 'package:avatar_flutter/avatar_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Cabello incluye "Sin pelo" como su última opción (para un usuario calvo)', () {
    final hair =
        defaultAvatarCatalog().firstWhere((category) => category.id == 'hair');

    final noneOption = hair.options.last;
    expect(noneOption.isNone, isTrue);
    expect(noneOption.semanticLabel, 'Sin pelo');
    // "Sin pelo" no debe ser la opción preseleccionada por defecto: la
    // primera opción de la categoría (options.first) sigue siendo una
    // forma de pelo real, tal como pide la especificación.
    expect(hair.options.first.isNone, isFalse);
  });

  test('elegir "Sin pelo" no aporta ninguna capa al preview', () {
    final categories = defaultAvatarCatalog();
    final controller = AvatarCreatorController(categories: categories);
    final hair = categories.firstWhere((category) => category.id == 'hair');

    controller.selectOption('hair', hair.options.last.id);

    final hairLayerCount = controller.layerAssetPaths
        .where((layer) => layer.path.contains('/hair/'))
        .length;
    expect(hairLayerCount, 0);

    controller.dispose();
  });

  test(
      'Accesorios existe, es kind: layer, y "Sin accesorios" es su primera opción (preseleccionada por defecto)',
      () {
    final extra = defaultAvatarCatalog()
        .firstWhere((category) => category.id == 'extra');

    expect(extra.kind, AvatarCategoryKind.layer);
    expect(extra.colorOptions, isNull);
    final noneOption = extra.options.first;
    expect(noneOption.isNone, isTrue);
    expect(noneOption.semanticLabel, 'Sin accesorios');
  });

  test('un avatar nuevo no lleva ningún accesorio por defecto', () {
    final controller =
        AvatarCreatorController(categories: defaultAvatarCatalog());

    expect(controller.selectedOptionFor('extra').isNone, isTrue);
    final extraLayerCount = controller.layerAssetPaths
        .where((layer) => layer.path.contains('/extra/'))
        .length;
    expect(extraLayerCount, 0);

    controller.dispose();
  });

  test('elegir el accesorio real (id "1") sí aporta una capa al preview', () {
    final controller =
        AvatarCreatorController(categories: defaultAvatarCatalog());

    controller.selectOption('extra', '1');

    final extraLayer = controller.layerAssetPaths
        .singleWhere((layer) => layer.path.contains('/extra/'));
    expect(extraLayer.path, 'assets/avatar/extra/extra_1.svg');
    expect(extraLayer.package, 'avatar_flutter');

    controller.dispose();
  });

  test(
      '"Sin pelo" y "Sin accesorios" comparten la misma miniatura (assets/avatar/none.svg)',
      () {
    final categories = defaultAvatarCatalog();
    final hairNone =
        categories.firstWhere((c) => c.id == 'hair').options.last;
    final extraNone =
        categories.firstWhere((c) => c.id == 'extra').options.first;

    expect(hairNone.thumbnailAssetPath, 'assets/avatar/none.svg');
    expect(extraNone.thumbnailAssetPath, 'assets/avatar/none.svg');
  });
}
