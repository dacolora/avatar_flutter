import 'package:avatar_flutter/avatar_flutter.dart';
import 'package:avatar_flutter/src/widgets/avatar_option_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AvatarOptionGrid reports the tapped option id', (tester) async {
    const options = [
      AvatarOption.color(id: 'green', color: Colors.green, semanticLabel: 'Verde'),
      AvatarOption.color(id: 'blue', color: Colors.blue, semanticLabel: 'Azul'),
    ];

    String? selectedOptionId = 'green';

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              body: AvatarOptionGrid(
                options: options,
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

  testWidgets('AvatarOptionGrid llama a resolveAssetPath por cada opción, en vez de usar option.assetPath directo', (tester) async {
    const options = [
      AvatarOption.layer(id: '1', assetPath: 'assets/avatar/hair/Color={color}, Expression=1.svg'),
      AvatarOption.layer(id: '2', assetPath: 'assets/avatar/hair/Color={color}, Expression=2.svg'),
    ];
    final resolvedPaths = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AvatarOptionGrid(
            options: options,
            selectedOptionId: '1',
            resolveAssetPath: (option) {
              final resolved = option.assetPath!.replaceFirst('{color}', '3');
              resolvedPaths.add(resolved);
              return resolved;
            },
            onSelected: (_) {},
          ),
        ),
      ),
    );

    expect(resolvedPaths, [
      'assets/avatar/hair/Color=3, Expression=1.svg',
      'assets/avatar/hair/Color=3, Expression=2.svg',
    ]);
  });

  testWidgets('AvatarOptionGrid enforces the 10-item spec limit', (tester) async {
    final tooManyOptions = List.generate(
      11,
      (index) => AvatarOption.layer(id: 'body-$index', assetPath: 'assets/avatar/body/Property 1=1.svg'),
    );

    expect(
      () => AvatarOptionGrid(
        options: tooManyOptions,
        selectedOptionId: null,
        onSelected: (_) {},
      ),
      throwsAssertionError,
    );
  });
}
