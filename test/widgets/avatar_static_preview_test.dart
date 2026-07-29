import 'package:avatar_flutter/avatar_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

AvatarLayerCategory _backgroundCategory() {
  return AvatarLayerCategory(
    id: 'background',
    label: 'background',
    icon: Icons.circle,
    kind: AvatarCategoryKind.layer,
    isBackground: true,
    options: const [
      AvatarOption.color(id: 'green', color: Colors.green),
      AvatarOption.color(id: 'blue', color: Colors.blue),
    ],
  );
}

void main() {
  testWidgets('usa el color de fondo correspondiente a la selección dada',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AvatarStaticPreview(
            categories: [_backgroundCategory()],
            selection: const {'background': 'blue'},
            size: 64,
          ),
        ),
      ),
    );

    final circleAvatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
    expect(circleAvatar.backgroundColor, Colors.blue);
    expect(circleAvatar.radius, 32);

    final sizedBoxes = tester.widgetList<SizedBox>(
      find.ancestor(
          of: find.byType(CircleAvatar), matching: find.byType(SizedBox)),
    );
    expect(sizedBoxes.first.width, 64);
    expect(sizedBoxes.first.height, 64);
  });

  testWidgets(
      'no lanza excepción con una categoría u opción que no existe en la selección',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AvatarStaticPreview(
            categories: [_backgroundCategory()],
            // 'background' no trae ningún id de la lista de arriba, y hay
            // una categoría ('accessory') que ni siquiera existe en la
            // lista de categories.
            selection: const {'background': 'no-existe', 'accessory': 'algo'},
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    // Cae de vuelta a la primera opción de la categoría de fondo.
    final circleAvatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
    expect(circleAvatar.backgroundColor, Colors.green);
  });

  testWidgets('usa defaultAvatarCatalog si no se pasa categories',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AvatarStaticPreview(
            selection: {'background': 'blue'},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final circleAvatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
    expect(circleAvatar.backgroundColor, const Color(0xFF8FC5D6));
  });
}
