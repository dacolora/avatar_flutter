import 'package:avatar_flutter/avatar_flutter.dart';
import 'package:avatar_flutter/src/widgets/avatar_option_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AvatarOptionGrid reports the tapped option id', (tester) async {
    final category = AvatarLayerCategory(
      id: 'background',
      label: 'Color de fondo',
      icon: Icons.circle,
      kind: AvatarCategoryKind.colorRow,
      options: const [
        AvatarOption.color(id: 'green', color: Colors.green, semanticLabel: 'Verde'),
        AvatarOption.color(id: 'blue', color: Colors.blue, semanticLabel: 'Azul'),
      ],
    );

    String? selectedOptionId = 'green';

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              body: AvatarOptionGrid(
                category: category,
                selectedOptionId: selectedOptionId,
                onSelected: (optionId) => setState(() => selectedOptionId = optionId),
              ),
            );
          },
        ),
      ),
    );

    expect(find.bySemanticsLabel('Verde'), findsOneWidget);
    expect(find.bySemanticsLabel('Azul'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Azul'));
    await tester.pumpAndSettle();

    expect(selectedOptionId, 'blue');
  });

  testWidgets('AvatarOptionGrid enforces the 10-item spec limit', (tester) async {
    AvatarLayerCategory tooManyOptions() {
      return AvatarLayerCategory(
        id: 'body',
        label: 'Vestuario',
        icon: Icons.circle,
        kind: AvatarCategoryKind.layer,
        options: List.generate(
          11,
          (index) => AvatarOption.layer(id: 'body-$index', assetPath: 'assets/avatar/body/body_1.svg'),
        ),
      );
    }

    expect(
      () => AvatarOptionGrid(
        category: tooManyOptions(),
        selectedOptionId: null,
        onSelected: (_) {},
      ),
      throwsAssertionError,
    );
  });
}
