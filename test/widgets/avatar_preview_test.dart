import 'package:avatar_flutter/avatar_flutter.dart';
import 'package:avatar_flutter/src/controllers/avatar_creator_scope.dart';
import 'package:avatar_flutter/src/widgets/avatar_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpAt(WidgetTester tester, double expansion) async {
    final controller = AvatarCreatorController(categories: defaultAvatarCatalog());
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: AvatarCreatorScope(
          controller: controller,
          child: Scaffold(
            body: AvatarPreview(
              expandedHeight: 249,
              collapsedHeight: 160,
              expansion: expansion,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets(
      'a mitad de scroll, el círculo (CircleAvatar) mide exactamente lo mismo que el rectángulo exterior espera — no se queda atrás',
      (tester) async {
    await pumpAt(tester, 0.5);

    // height = lerp(160, 249, 0.5) = 204.5; circleDiameter = 204.5 * 0.8
    const expectedCircleDiameter = (160 + (249 - 160) * 0.5) * 0.8;

    final circleAvatar = tester.widget<CircleAvatar>(
      find.byType(CircleAvatar).first,
    );
    // El CircleAvatar interno se construye siempre a su tamaño máximo fijo
    // (ver `maxCircleDiameter` en avatar_preview.dart): lo que lo deja del
    // tamaño correcto en pantalla es el `FittedBox` que lo envuelve, no su
    // propio `radius`.
    expect(circleAvatar.radius, (249 * 0.8) / 2);

    // El tamaño real en pantalla (después de que FittedBox escala) sí debe
    // coincidir exactamente con circleDiameter — esto es lo que garantiza
    // que el círculo nunca se vea más chico ni más grande que lo que el
    // rectángulo exterior (que sigue el dedo al instante) espera en este
    // punto exacto del scroll.
    final fittedBoxSize = tester.getSize(
      find.ancestor(
          of: find.byType(ClipOval), matching: find.byType(FittedBox)),
    );
    expect(fittedBoxSize.width, closeTo(expectedCircleDiameter, 0.01));
    expect(fittedBoxSize.height, closeTo(expectedCircleDiameter, 0.01));
  });

  testWidgets(
      'el contenido dentro de FittedBox (círculo + capas) se construye siempre al mismo tamaño fijo, sin importar expansion',
      (tester) async {
    await pumpAt(tester, 0.5);
    final sizeAtHalf = tester.getSize(find.byType(ClipOval));

    await pumpAt(tester, 1.0);
    final sizeAtFull = tester.getSize(find.byType(ClipOval));

    await pumpAt(tester, 0.0);
    final sizeAtZero = tester.getSize(find.byType(ClipOval));

    // El tamaño *interno* (antes de que FittedBox escale) es el mismo
    // diámetro máximo en los tres casos: nunca hay nada que recortar ni
    // reflow de SVG que recalcular en cada frame de scroll.
    expect(sizeAtHalf, sizeAtFull);
    expect(sizeAtHalf, sizeAtZero);
  });
}
