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
}
